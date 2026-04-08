#!/bin/sh
# Temporary test harness for backup.sh – validates in-container logic with mocks.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "${TEST_DIR}"; }
trap cleanup EXIT

pass() { PASS=$((PASS + 1)); printf '  ✓ %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  ✗ %s\n' "$1"; }

# ---------------------------------------------------------------------------
# Setup: fake storage dir, mock mysqldump, and env vars
# ---------------------------------------------------------------------------
FAKE_STORAGE="${TEST_DIR}/storage"
mkdir -p "${FAKE_STORAGE}/app/public"
echo "test file" > "${FAKE_STORAGE}/app/public/testfile.txt"

MOCK_BIN="${TEST_DIR}/bin"
mkdir -p "${MOCK_BIN}"
cat > "${MOCK_BIN}/mysqldump" <<'MOCK'
#!/bin/sh
printf 'CREATE TABLE dummy;\n'
MOCK
chmod +x "${MOCK_BIN}/mysqldump"

export DB_HOST=localhost
export DB_PORT=3306
export DB_DATABASE=testdb
export DB_USERNAME=testuser
export DB_PASSWORD=testpass
export STORAGE_PATH="${FAKE_STORAGE}"

TODAY="$(date +%Y-%m-%d)"

# ---------------------------------------------------------------------------
# Test 1: Daily backup via basename symlink
# ---------------------------------------------------------------------------
echo "Test 1: daily backup (basename detection)"
BACKUP_OUT="${TEST_DIR}/backups_t1"
ln -sf "${SCRIPT_DIR}/backup.sh" "${TEST_DIR}/daily"

(
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT}" \
        sh "${TEST_DIR}/daily" > /dev/null 2>&1
)

ARCHIVE="${BACKUP_OUT}/${TODAY}-daily.tar.gz"
if [ -f "${ARCHIVE}" ]; then
    pass "daily archive created: $(basename "${ARCHIVE}")"
else
    fail "daily archive not found at ${ARCHIVE}"
fi

if tar tzf "${ARCHIVE}" 2>/dev/null | grep -q 'db.sql.gz'; then
    pass "archive contains db.sql.gz"
else
    fail "archive missing db.sql.gz"
fi
if tar tzf "${ARCHIVE}" 2>/dev/null | grep -q 'storage.tar.gz'; then
    pass "archive contains storage.tar.gz"
else
    fail "archive missing storage.tar.gz"
fi

# ---------------------------------------------------------------------------
# Test 2: Weekly backup via basename
# ---------------------------------------------------------------------------
echo "Test 2: weekly backup (basename detection)"
BACKUP_OUT2="${TEST_DIR}/backups_t2"
ln -sf "${SCRIPT_DIR}/backup.sh" "${TEST_DIR}/weekly"

(
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT2}" \
        sh "${TEST_DIR}/weekly" > /dev/null 2>&1
)

ARCHIVE2="${BACKUP_OUT2}/${TODAY}-weekly.tar.gz"
if [ -f "${ARCHIVE2}" ]; then
    pass "weekly archive created: $(basename "${ARCHIVE2}")"
else
    fail "weekly archive not found at ${ARCHIVE2}"
fi

# ---------------------------------------------------------------------------
# Test 3: Monthly backup via basename
# ---------------------------------------------------------------------------
echo "Test 3: monthly backup (basename detection)"
BACKUP_OUT3="${TEST_DIR}/backups_t3"
ln -sf "${SCRIPT_DIR}/backup.sh" "${TEST_DIR}/monthly"

(
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT3}" \
        sh "${TEST_DIR}/monthly" > /dev/null 2>&1
)

ARCHIVE3="${BACKUP_OUT3}/${TODAY}-monthly.tar.gz"
if [ -f "${ARCHIVE3}" ]; then
    pass "monthly archive created: $(basename "${ARCHIVE3}")"
else
    fail "monthly archive not found at ${ARCHIVE3}"
fi

# ---------------------------------------------------------------------------
# Test 4: Manual invocation (basename = backup.sh -> frequency = manual)
# ---------------------------------------------------------------------------
echo "Test 4: manual invocation (basename fallback)"
BACKUP_OUT4="${TEST_DIR}/backups_t4"

(
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT4}" \
        sh "${SCRIPT_DIR}/backup.sh" > /dev/null 2>&1
)

ARCHIVE4="${BACKUP_OUT4}/${TODAY}-manual.tar.gz"
if [ -f "${ARCHIVE4}" ]; then
    pass "manual archive created: $(basename "${ARCHIVE4}")"
else
    fail "manual archive not found at ${ARCHIVE4}"
fi

# ---------------------------------------------------------------------------
# Test 5: Retention deletes old backups of matching frequency
# ---------------------------------------------------------------------------
echo "Test 5: retention cleanup"
BACKUP_OUT5="${TEST_DIR}/backups_t5"
mkdir -p "${BACKUP_OUT5}"

OLD_FILE="${BACKUP_OUT5}/1999-01-01-daily.tar.gz"
touch "${OLD_FILE}"
if touch -t 199901010000 "${OLD_FILE}" 2>/dev/null; then :
else touch -d "60 days ago" "${OLD_FILE}" 2>/dev/null || true; fi

ln -sf "${SCRIPT_DIR}/backup.sh" "${TEST_DIR}/daily"

(
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT5}" \
        sh "${TEST_DIR}/daily" > /dev/null 2>&1
)

if [ ! -f "${OLD_FILE}" ]; then
    pass "old daily backup was cleaned up"
else
    fail "old daily backup was NOT cleaned up"
fi

# ---------------------------------------------------------------------------
# Test 6: Fails with missing DB credentials
# ---------------------------------------------------------------------------
echo "Test 6: fails with missing credentials"
BACKUP_OUT6="${TEST_DIR}/backups_t6"

if (
    unset DB_DATABASE DB_USERNAME DB_PASSWORD
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT6}" \
        sh "${SCRIPT_DIR}/backup.sh" > /dev/null 2>&1
); then
    fail "should have exited non-zero with missing credentials"
else
    pass "correctly failed with missing DB credentials"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ] || exit 1
