#!/bin/sh
set -eu
export TZ=Asia/Shanghai
# Shared by all rclone commands; the Job has a separate six-hour total deadline.
export RCLONE_RETRIES=5 RCLONE_RETRIES_SLEEP=1m
export RCLONE_LOW_LEVEL_RETRIES=10 RCLONE_CONTIMEOUT=30s RCLONE_TIMEOUT=5m

date
onedrive_prefix="onedrive:/backup/kubernetes-daily"
today=$(date +%Y-%m-%d)
backup="$onedrive_prefix/$today"
cutoff=$(date -d "@$(($(date +%s) - RETENTION_DAYS * 86400))" +%Y%m%d)

rclone mkdir "$backup"
# Reuse the latest successful earlier day; ignore incomplete and same-day backups.
previous=''
rclone lsf "$onedrive_prefix" --dirs-only --max-depth 1 > /tmp/backup-days.txt
sort -r /tmp/backup-days.txt > /tmp/backup-candidates.txt
while IFS= read -r entry; do
  name=${entry%/}
  if printf '%s\n' "$name" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' && [ "$name" \< "$today" ]; then
    marker=$(rclone lsf "$onedrive_prefix/$name" --files-only --max-depth 1 --include '/_SUCCESS')
    if [ "$marker" = '_SUCCESS' ]; then
      previous="$onedrive_prefix/$name"
      break
    fi
  fi
done < /tmp/backup-candidates.txt
echo "copy reference: ${previous:-none (full upload)}"

# A same-day rerun is incomplete until every path succeeds again.
rclone delete "$backup" --include '/_SUCCESS' --max-depth 1
# Paths are relative to /media/service_data; blank lines and comments are allowed.
while IFS= read -r dir || [ -n "$dir" ]; do
  case "$dir" in ''|\#*) continue ;; esac
  src="/media/service_data/$dir"
  dest="$backup/$dir"
  set --
  if [ -n "$previous" ]; then
    reference="$previous/$dir"
    [ ! -f "$src" ] || reference="$previous/$(dirname "$dir")"
    set -- --copy-dest "$reference"
  fi
  echo "syncing $src to $dest ..."
  if [ -f "$src" ]; then
    rclone copyto -L "$src" "$dest" "$@" \
      --stats 1m --log-level INFO
  else
    rclone sync -L --create-empty-src-dirs "$src" "$dest" "$@" \
      --stats 1m --log-level INFO
  fi
done < /scripts/paths.txt

date > /tmp/backup-success.txt
rclone copyto /tmp/backup-success.txt "$backup/_SUCCESS"

# Keep today and the preceding six days when RETENTION_DAYS=7.
# Only reached after all backups succeed; file mtimes do not affect retention.
rclone lsf "$onedrive_prefix" --dirs-only --max-depth 1 > /tmp/backup-days.txt
while IFS= read -r entry; do
  name=${entry%/}
  if printf '%s\n' "$name" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    backup_day=$(printf '%s' "$name" | tr -d '-')
    if [ "$backup_day" -le "$cutoff" ]; then
      echo "deleting expired backup $onedrive_prefix/$name ..."
      rclone purge "$onedrive_prefix/$name"
    fi
  fi
done < /tmp/backup-days.txt

echo "backup completed: $backup"
