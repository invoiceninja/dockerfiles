#!/bin/sh
set -eu

# Invoice Ninja Docker – Backup Script
#
# When symlinked into /etc/cron.daily, /etc/cron.weekly, or /etc/cron.monthly
# the script uses its invocation name to set the backup frequency and retention.
# It can also be run manually: /usr/local/bin/backup.sh
#
# Retention defaults:
#   daily   –  7 days
#   weekly  – 30 days
#   monthly – 120 days
#   manual  – 30 days

FREQUENCY="$(basename "$0")"

case "${FREQUENCY}" in
    daily)   RETENTION_DAYS=7   ;;
    weekly)  RETENTION_DAYS=30  ;;
    monthly) RETENTION_DAYS=120 ;;
    *)       FREQUENCY="manual"; RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}" ;;
esac

BACKUP_DIR="${BACKUP_DIR:-/backups}"
STORAGE_PATH="${STORAGE_PATH:-/var/www/html/storage}"
TIMESTAMP="$(date +%Y-%m-%d)"
BACKUP_NAME="${TIMESTAMP}-${FREQUENCY}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:?DB_DATABASE is not set}"
DB_USERNAME="${DB_USERNAME:?DB_USERNAME is not set}"
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD is not set}"

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
command -v mysqldump >/dev/null 2>&1 || die "mysqldump is not installed"
[ -d "${STORAGE_PATH}" ] || die "${STORAGE_PATH} does not exist"
mkdir -p "${BACKUP_DIR}"

echo "[backup] Starting ${FREQUENCY} backup → ${BACKUP_PATH}"

# ---------------------------------------------------------------------------
# 1. Database dump
# ---------------------------------------------------------------------------
mkdir -p "${BACKUP_PATH}"

echo "[backup] Dumping database '${DB_DATABASE}'..."
mysqldump -h"${DB_HOST}" -P"${DB_PORT}" \
    -u"${DB_USERNAME}" -p"${DB_PASSWORD}" \
    --single-transaction --no-tablespaces --routines --triggers \
    "${DB_DATABASE}" \
    | gzip > "${BACKUP_PATH}/db.sql.gz"

# ---------------------------------------------------------------------------
# 2. Storage volume
# ---------------------------------------------------------------------------
echo "[backup] Archiving storage volume..."
tar czf "${BACKUP_PATH}/storage.tar.gz" -C "$(dirname "${STORAGE_PATH}")" "$(basename "${STORAGE_PATH}")"

# ---------------------------------------------------------------------------
# 3. Bundle into a single archive
# ---------------------------------------------------------------------------
tar czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
rm -rf "${BACKUP_PATH}"
echo "[backup] Saved ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# ---------------------------------------------------------------------------
# 4. Retention – remove old backups of the same frequency
# ---------------------------------------------------------------------------
if [ "${RETENTION_DAYS}" -gt 0 ] 2>/dev/null; then
    DELETED=$(find "${BACKUP_DIR}" -maxdepth 1 -name "*-${FREQUENCY}.tar.gz" \
        -type f -mtime +"${RETENTION_DAYS}" -print -delete | wc -l)
    if [ "${DELETED}" -gt 0 ]; then
        echo "[backup] Cleaned up ${DELETED} ${FREQUENCY} backup(s) older than ${RETENTION_DAYS} days."
    fi
fi

echo "[backup] Done."
