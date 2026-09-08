#!/bin/sh
set -eu

export TZ=Asia/Shanghai
export RCLONE_RETRIES=3 RCLONE_RETRIES_SLEEP=1m
export RCLONE_LOW_LEVEL_RETRIES=6 RCLONE_CONTIMEOUT=30s RCLONE_TIMEOUT=5m

: "${REMOTE_ROOT:?REMOTE_ROOT is required}"
: "${RETENTION_DAYS:?RETENTION_DAYS is required}"
: "${MAX_DELETE:=10000}"
: "${LATEST_READY_TIMEOUT:=10800}"

latest="$REMOTE_ROOT/latest"
weekly="$REMOTE_ROOT/weekly"
today=$(date +%Y-%m-%d)
snapshot="$weekly/$today"
cutoff=$(date -d "@$(($(date +%s) - RETENTION_DAYS * 86400))" +%Y%m%d)

mkdir -p /tmp/backup-state
ready_deadline=$(($(date +%s) + LATEST_READY_TIMEOUT))
while :; do
  if rclone copyto "$latest/_SUCCESS" /tmp/backup-state/latest-success.json 2>/dev/null \
    && grep -q "\"generation\":\"$today\"" /tmp/backup-state/latest-success.json; then
    break
  fi
  if [ "$(date +%s)" -ge "$ready_deadline" ]; then
    echo "latest backup for $today did not become ready within ${LATEST_READY_TIMEOUT}s" >&2
    exit 1
  fi
  echo "waiting for today's verified latest backup ..."
  sleep 60
done

echo "weekly snapshot $today started at $(date)"
rclone mkdir "$snapshot"
rclone delete "$snapshot" --include '/_SUCCESS' --max-depth 1
rclone sync "$latest" "$snapshot" --exclude '/_SUCCESS' \
  --delete-after --max-delete "$MAX_DELETE" --no-update-dir-modtime \
  --transfers 4 --checkers 8 --stats 1m --log-level INFO
rclone check "$latest" "$snapshot" --one-way --exclude '/_SUCCESS'
rclone copyto /tmp/backup-state/latest-success.json "$snapshot/_SUCCESS"

# Retention only runs after a complete, verified weekly snapshot is published.
rclone lsf "$weekly" --dirs-only --max-depth 1 > /tmp/backup-weeks.txt
while IFS= read -r entry; do
  name=${entry%/}
  if printf '%s\n' "$name" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    backup_day=$(printf '%s' "$name" | tr -d '-')
    if [ "$backup_day" -le "$cutoff" ]; then
      echo "deleting expired snapshot $weekly/$name ..."
      rclone purge "$weekly/$name"
    fi
  fi
done < /tmp/backup-weeks.txt

echo "weekly snapshot completed: $snapshot"
