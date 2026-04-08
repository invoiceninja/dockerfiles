#!/bin/sh
# Temporary test harness for backup.sh – validates logic with a mock docker.
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
# Setup: create a fake debian/ tree with .env and a mock `docker` binary
# ---------------------------------------------------------------------------
FAKE_DEBIAN="${TEST_DIR}/debian"
mkdir -p "${FAKE_DEBIAN}/scripts"
cp "${SCRIPT_DIR}/backup.sh" "${FAKE_DEBIAN}/scripts/backup.sh"

cat > "${FAKE_DEBIAN}/.env" <<'DOTENV'
DB_DATABASE=testdb
DB_USERNAME=testuser
DB_PASSWORD=testpass
DOTENV

# Mock docker binary that simulates compose commands
MOCK_BIN="${TEST_DIR}/bin"
mkdir -p "${MOCK_BIN}"
cat > "${MOCK_BIN}/docker" <<'MOCK'
#!/bin/sh
# Intercept `docker compose` subcommands
case "$*" in
    *"ps --status running"*)
        printf 'mysql\napp\n'
        ;;
    *"exec -T mysql mysqldump"*)
        printf 'CREATE TABLE dummy;\n'
        ;;
    *"exec -T app tar"*)
        # produce a tiny valid gzip stream (empty tar)
        tar czf - --files-from /dev/null
        ;;
    *)
        printf 'mock docker called: %s\n' "$*" >&2
        ;;
esac
MOCK
chmod +x "${MOCK_BIN}/docker"

# ---------------------------------------------------------------------------
# Test 1: Successful backup creates archive
# ---------------------------------------------------------------------------
echo "Test 1: basic backup"
BACKUP_OUT="${TEST_DIR}/backups_t1"
(
    cd "${FAKE_DEBIAN}"
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT}" BACKUP_RETENTION_DAYS=0 \
        sh scripts/backup.sh > /dev/null 2>&1
)
ARCHIVE=$(find "${BACKUP_OUT}" -maxdepth 1 -name 'invoiceninja-*.tar.gz' | head -1)
if [ -n "${ARCHIVE}" ] && [ -f "${ARCHIVE}" ]; then
    pass "archive created: $(basename "${ARCHIVE}")"
else
    fail "no archive found in ${BACKUP_OUT}"
fi

# Verify the archive contains db.sql.gz and storage.tar.gz
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
# Test 2: Retention deletes old backups
# ---------------------------------------------------------------------------
echo "Test 2: retention cleanup"
BACKUP_OUT2="${TEST_DIR}/backups_t2"
mkdir -p "${BACKUP_OUT2}"
# Create a fake old backup (touch with old date)
OLD_FILE="${BACKUP_OUT2}/invoiceninja-19990101-000000.tar.gz"
touch "${OLD_FILE}"
# backdate it on macOS (uses -t) or Linux (uses -d)
if touch -t 199901010000 "${OLD_FILE}" 2>/dev/null; then
    :
else
    touch -d "60 days ago" "${OLD_FILE}" 2>/dev/null || true
fi

(
    cd "${FAKE_DEBIAN}"
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT2}" BACKUP_RETENTION_DAYS=7 \
        sh scripts/backup.sh > /dev/null 2>&1
)
if [ ! -f "${OLD_FILE}" ]; then
    pass "old backup was cleaned up"
else
    fail "old backup was NOT cleaned up"
fi

# ---------------------------------------------------------------------------
# Test 3: Fails when a service is not running
# ---------------------------------------------------------------------------
echo "Test 3: fails when service is down"
cat > "${MOCK_BIN}/docker" <<'MOCK2'
#!/bin/sh
case "$*" in
    *"ps --status running"*)
        printf 'app\n'   # mysql is missing
        ;;
    *) ;;
esac
MOCK2
chmod +x "${MOCK_BIN}/docker"

BACKUP_OUT3="${TEST_DIR}/backups_t3"
if (
    cd "${FAKE_DEBIAN}"
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT3}" \
        sh scripts/backup.sh > /dev/null 2>&1
); then
    fail "should have exited non-zero when mysql is down"
else
    pass "correctly failed when mysql service is down"
fi

# ---------------------------------------------------------------------------
# Test 4: Fails with missing .env credentials
# ---------------------------------------------------------------------------
echo "Test 4: fails with missing credentials"
# Restore working mock
cat > "${MOCK_BIN}/docker" <<'MOCK3'
#!/bin/sh
case "$*" in
    *"ps --status running"*)
        printf 'mysql\napp\n'
        ;;
    *) ;;
esac
MOCK3
chmod +x "${MOCK_BIN}/docker"

EMPTY_DEBIAN="${TEST_DIR}/empty_debian"
mkdir -p "${EMPTY_DEBIAN}/scripts"
cp "${SCRIPT_DIR}/backup.sh" "${EMPTY_DEBIAN}/scripts/backup.sh"
touch "${EMPTY_DEBIAN}/.env"   # empty .env

BACKUP_OUT4="${TEST_DIR}/backups_t4"
if (
    cd "${EMPTY_DEBIAN}"
    PATH="${MOCK_BIN}:${PATH}" BACKUP_DIR="${BACKUP_OUT4}" \
        sh scripts/backup.sh > /dev/null 2>&1
); then
    fail "should have exited non-zero with empty .env"
else
    pass "correctly failed with missing DB credentials"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ] || exit 1
