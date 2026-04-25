#!/usr/bin/env bash
set -Eeuo pipefail

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
FILENAME="siscom_${TIMESTAMP}.dump"
LOCAL_FILE="/backups/${FILENAME}"
S3_URI="s3://${S3_BUCKET}/${S3_PREFIX}/${FILENAME}"

echo "[INFO] Starting backup at $(date -Iseconds)"

# Evita duplicados
exec 9>/tmp/postgres-backup.lock
flock -n 9 || {
  echo "[WARN] Backup already running. Exiting."
  exit 0
}

# Dump en formato custom
nice -n 10 ionice -c2 -n7 \
pg_dump \
  -Fc \
  -h "${POSTGRES_HOST}" \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  -f "${LOCAL_FILE}"

echo "[INFO] Local backup created: ${LOCAL_FILE}"

# Subir a S3
aws s3 cp "${LOCAL_FILE}" "${S3_URI}"

echo "[INFO] Uploaded to S3: ${S3_URI}"

# Rotación local (7 días)
find /backups -type f -name "*.dump" -mtime +7 -delete

echo "[INFO] Backup finished at $(date -Iseconds)"