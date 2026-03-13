#!/usr/bin/env bash
set -Eeuo pipefail

umask 077

ENV_FILE="${ENV_FILE:-/etc/wave-db-backup.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

DB_FILE="${DB_FILE:-/opt/wave-messenger/data/db.json}"
LOCAL_BACKUP_DIR="${LOCAL_BACKUP_DIR:-/root/deploy-backups/wave-db}"
RCLONE_CONFIG="${RCLONE_CONFIG:-/root/.config/rclone/rclone.conf}"
RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME:-gdrive}"
RCLONE_REMOTE_DIR="${RCLONE_REMOTE_DIR:-Wave Messenger/db-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
MAX_COPY_RETRIES="${MAX_COPY_RETRIES:-10}"
SLEEP_BETWEEN_RETRIES_SECONDS="${SLEEP_BETWEEN_RETRIES_SECONDS:-2}"
BACKUP_TZ="${BACKUP_TZ:-UTC}"
LOG_FILE="${LOG_FILE:-/var/log/wave-db-backup.log}"

mkdir -p "$(dirname "$LOG_FILE")" "$LOCAL_BACKUP_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec >>"$LOG_FILE" 2>&1

timestamp() {
  TZ="$BACKUP_TZ" date +"%Y-%m-%dT%H:%M:%S%z"
}

log() {
  printf "[%s] %s\n" "$(timestamp)" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

validate_json() {
  node -e "JSON.parse(require('node:fs').readFileSync(process.argv[1], 'utf8'))" "$1" >/dev/null
}

command -v node >/dev/null 2>&1 || fail "node is required to validate the backup snapshot"
command -v gzip >/dev/null 2>&1 || fail "gzip is required"
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required"
command -v rclone >/dev/null 2>&1 || fail "rclone is not installed"

[[ -f "$DB_FILE" ]] || fail "database file not found: $DB_FILE"
[[ -f "$RCLONE_CONFIG" ]] || fail "rclone config not found: $RCLONE_CONFIG"

if ! rclone listremotes --config "$RCLONE_CONFIG" | grep -Fxq "${RCLONE_REMOTE_NAME}:"; then
  fail "rclone remote '${RCLONE_REMOTE_NAME}' is not configured in $RCLONE_CONFIG"
fi

run_timestamp="$(TZ="$BACKUP_TZ" date +"%Y%m%d-%H%M%S")"
archive_name="wave-db-${run_timestamp}.json.gz"
archive_path="${LOCAL_BACKUP_DIR}/${archive_name}"
archive_sha_path="${archive_path}.sha256"
latest_name="latest.json.gz"
latest_sha_name="latest.sha256"
remote_base="${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_DIR}"

tmp_dir="$(mktemp -d)"
tmp_json="${tmp_dir}/db.json"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

log "Starting backup from ${DB_FILE}"

snapshot_ok=0
for (( attempt=1; attempt<=MAX_COPY_RETRIES; attempt++ )); do
  cp "$DB_FILE" "$tmp_json"
  if validate_json "$tmp_json"; then
    snapshot_ok=1
    log "Snapshot validated on attempt ${attempt}"
    break
  fi

  log "Snapshot validation failed on attempt ${attempt}; retrying in ${SLEEP_BETWEEN_RETRIES_SECONDS}s"
  sleep "$SLEEP_BETWEEN_RETRIES_SECONDS"
done

[[ "$snapshot_ok" -eq 1 ]] || fail "could not read a valid JSON snapshot after ${MAX_COPY_RETRIES} attempts"

gzip -c "$tmp_json" > "$archive_path"
checksum="$(sha256sum "$archive_path" | awk '{print $1}')"
printf "%s  %s\n" "$checksum" "$archive_name" > "$archive_sha_path"

log "Uploading ${archive_name} to ${remote_base}"

rclone mkdir --config "$RCLONE_CONFIG" "$remote_base"
rclone copyto --config "$RCLONE_CONFIG" "$archive_path" "${remote_base}/${archive_name}"
rclone copyto --config "$RCLONE_CONFIG" "$archive_path" "${remote_base}/${latest_name}"
rclone copyto --config "$RCLONE_CONFIG" "$archive_sha_path" "${remote_base}/${archive_name}.sha256"

latest_sha_file="${tmp_dir}/${latest_sha_name}"
printf "%s  %s\n" "$checksum" "$latest_name" > "$latest_sha_file"
rclone copyto --config "$RCLONE_CONFIG" "$latest_sha_file" "${remote_base}/${latest_sha_name}"

find "$LOCAL_BACKUP_DIR" -type f -name "wave-db-*.json.gz" -mtime +"$RETENTION_DAYS" -delete
find "$LOCAL_BACKUP_DIR" -type f -name "wave-db-*.json.gz.sha256" -mtime +"$RETENTION_DAYS" -delete
rclone delete --config "$RCLONE_CONFIG" --include "wave-db-*.json.gz" --min-age "${RETENTION_DAYS}d" "$remote_base" || true
rclone delete --config "$RCLONE_CONFIG" --include "wave-db-*.json.gz.sha256" --min-age "${RETENTION_DAYS}d" "$remote_base" || true

log "Backup completed: ${archive_name}"
