#!/bin/sh
set -eu

# Invoice Ninja Docker – Backup Script
# Backs up the MySQL database and the storage volume.
# Run from the debian/ directory (where docker-compose.yml lives).
#
# Usage:
#   ./scripts/backup.sh              # backup with defaults
#   BACKUP_DIR=/mnt/nas ./scripts/backup.sh
#
# Environment variables (all optional):
#   BACKUP_DIR             – where to store backups     (default: ./backups)
#   BACKUP_RETENTION_DAYS  – delete backups older than  (default: 30, 0 = keep all)
#   COMPOSE_PROJECT        – docker compose project     (default: auto-detected)

BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_NAME="invoiceninja-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

COMPOSE_CMD="docker compose"
if [ -n "${COMPOSE_PROJECT:-}" ]; then
    COMPOSE_CMD="docker compose -p ${COMPOSE_PROJECT}"
fi

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
command -v docker >/dev/null 2>&1 || die "docker is not installed or not in PATH"

# Verify the containers we need are running
for svc in mysql app; do
    ${COMPOSE_CMD} ps --status running --format '{{.Service}}' 2>/dev/null \
        | grep -qx "${svc}" \
        || die "'${svc}' service is not running. Start the stack first: docker compose up -d"
done

# Read DB credentials from the .env file next to docker-compose.yml
ENV_FILE="$(dirname "$(dirname "$0")")/.env"
if [ -f "${ENV_FILE}" ]; then
    DB_DATABASE="$(grep -E '^DB_DATABASE=' "${ENV_FILE}" | cut -d= -f2-)"
    DB_USERNAME="$(grep -E '^DB_USERNAME=' "${ENV_FILE}" | cut -d= -f2-)"
    DB_PASSWORD="$(grep -E '^DB_PASSWORD=' "${ENV_FILE}" | cut -d= -f2-)"
fi

DB_DATABASE="${DB_DATABASE:?DB_DATABASE is not set – check .env}"
DB_USERNAME="${DB_USERNAME:?DB_USERNAME is not set – check .env}"
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD is not set – check .env}"

# ---------------------------------------------------------------------------
# Create backup directory
# ---------------------------------------------------------------------------
mkdir -p "${BACKUP_PATH}"

echo "Starting backup → ${BACKUP_PATH}"

# ---------------------------------------------------------------------------
# 1. Database dump
# ---------------------------------------------------------------------------
echo "  Dumping database '${DB_DATABASE}'..."
${COMPOSE_CMD} exec -T mysql \
    mysqldump -u"${DB_USERNAME}" -p"${DB_PASSWORD}" \
    --single-transaction --routines --triggers \
    "${DB_DATABASE}" \
    | gzip > "${BACKUP_PATH}/db.sql.gz"
echo "  Database dump complete."

# ---------------------------------------------------------------------------
# 2. Storage volume
# ---------------------------------------------------------------------------
echo "  Archiving storage volume..."
${COMPOSE_CMD} exec -T app \
    tar czf - -C /var/www/html storage \
    > "${BACKUP_PATH}/storage.tar.gz"
echo "  Storage archive complete."

# ---------------------------------------------------------------------------
# 3. Bundle into a single archive and clean up the temp directory
# ---------------------------------------------------------------------------
tar czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
rm -rf "${BACKUP_PATH}"
echo "Backup saved to ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# ---------------------------------------------------------------------------
# 4. Retention – remove old backups
# ---------------------------------------------------------------------------
if [ "${BACKUP_RETENTION_DAYS}" -gt 0 ] 2>/dev/null; then
    DELETED=$(find "${BACKUP_DIR}" -maxdepth 1 -name 'invoiceninja-*.tar.gz' \
        -type f -mtime +"${BACKUP_RETENTION_DAYS}" -print -delete | wc -l)
    if [ "${DELETED}" -gt 0 ]; then
        echo "Cleaned up ${DELETED} backup(s) older than ${BACKUP_RETENTION_DAYS} days."
    fi
fi

echo "Done."
