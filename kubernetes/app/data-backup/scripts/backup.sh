#!/bin/sh
set -eu

export TZ=Asia/Shanghai
export RCLONE_RETRIES=3 RCLONE_RETRIES_SLEEP=1m
export RCLONE_LOW_LEVEL_RETRIES=6 RCLONE_CONTIMEOUT=30s RCLONE_TIMEOUT=5m

: "${REMOTE_ROOT:?REMOTE_ROOT is required}"
: "${PATH_CONCURRENCY:=3}"
: "${MAX_DELETE:=10000}"
: "${DATABASE_READY_TIMEOUT:=3600}"
: "${DATA_ROOT:=/media/service_data}"
: "${PATHS_CONFIG:=/config/paths}"

latest="$REMOTE_ROOT/latest"
state="$REMOTE_ROOT/state"
today=$(date +%Y-%m-%d)
today_compact=$(date +%Y%m%d)
pids=''

terminate() {
  trap - INT TERM
  if [ -n "$pids" ]; then
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    wait || true
  fi
  exit 143
}
trap terminate INT TERM

echo "backup generation $today started at $(date)"
echo "remote layout: $REMOTE_ROOT"

backups_ready() {
  not_ready=0
  while IFS='|' read -r path excludes || [ -n "$path" ]; do
    [ -n "$path" ] || continue
    source_path="$DATA_ROOT/$path"
    backup_dirs=''
    case "$path" in
      */pg_backup|*/sqlite_backup) backup_dirs=$source_path ;;
    esac
    for candidate in "$source_path/pg_backup" "$source_path/sqlite_backup"; do
      if [ -d "$candidate" ]; then
        backup_dirs="$backup_dirs $candidate"
      fi
    done

    for backup_dir in $backup_dirs; do
      marker="$backup_dir/_SUCCESS"
      if [ ! -f "$marker" ]; then
        echo "waiting for required backup marker: $marker"
        not_ready=1
        continue
      fi
      marker_day=$(cut -c 1-8 "$marker")
      if [ "$marker_day" != "$today_compact" ]; then
        echo "waiting for fresh backup: $backup_dir (marker: $marker_day, expected: $today_compact)"
        not_ready=1
      fi
    done
  done < "$PATHS_CONFIG"
  [ "$not_ready" -eq 0 ]
}

# Database CronJobs start before this Job, but tolerate scheduling or dump
# delays. No remote generation is mutated until every marker is fresh.
readiness_deadline=$(($(date +%s) + DATABASE_READY_TIMEOUT))
until backups_ready; do
  if [ "$(date +%s)" -ge "$readiness_deadline" ]; then
    echo "database backups did not become ready within ${DATABASE_READY_TIMEOUT}s" >&2
    exit 1
  fi
  sleep 60
done

# Refuse to turn a missing NFS mount or missing application path into mass
# deletion on the remote latest tree.
while IFS='|' read -r dir excludes || [ -n "$dir" ]; do
  [ -n "$dir" ] || continue
  if [ ! -e "$DATA_ROOT/$dir" ]; then
    echo "backup source does not exist: $DATA_ROOT/$dir" >&2
    exit 1
  fi
  if [ -d "$DATA_ROOT/$dir" ] && ! find "$DATA_ROOT/$dir" -mindepth 1 -print -quit | grep -q .; then
    echo "backup source is unexpectedly empty: $DATA_ROOT/$dir" >&2
    exit 1
  fi
done < "$PATHS_CONFIG"

mkdir -p /tmp/backup-state
printf '{"generation":"%s","startedAt":"%s"}\n' "$today" "$(date -Iseconds)" > /tmp/backup-state/IN_PROGRESS
rclone mkdir "$latest"
rclone copyto /tmp/backup-state/IN_PROGRESS "$state/IN_PROGRESS"
rclone delete "$latest" --include '/_SUCCESS' --max-depth 1

sync_path() {
  dir=$1
  excludes=${2:-}
  src="$DATA_ROOT/$dir"
  dest="$latest/$dir"
  set --
  old_ifs=$IFS
  IFS=','
  for exclude in $excludes; do
    set -- "$@" --exclude "$exclude"
  done
  IFS=$old_ifs

  echo "syncing $src to $dest ..."
  if [ -f "$src" ]; then
    rclone copyto -L "$src" "$dest" "$@" \
      --transfers 4 --checkers 8 --stats 1m --log-level INFO
  else
    rclone sync -L "$src" "$dest" "$@" \
      --create-empty-src-dirs --delete-after --max-delete "$MAX_DELETE" \
      --no-update-dir-modtime \
      --transfers 4 --checkers 8 --stats 1m --log-level INFO
  fi
  echo "completed $dir"
}

wait_batch() {
  batch_failed=0
  for pid in $pids; do
    if ! wait "$pid"; then
      batch_failed=1
    fi
  done
  pids=''
  [ "$batch_failed" -eq 0 ]
}

sync_failed=0
batch_count=0
while IFS='|' read -r dir excludes || [ -n "$dir" ]; do
  [ -n "$dir" ] || continue
  sync_path "$dir" "$excludes" &
  pids="$pids $!"
  batch_count=$((batch_count + 1))
  if [ "$batch_count" -ge "$PATH_CONCURRENCY" ]; then
    if ! wait_batch; then
      sync_failed=1
    fi
    batch_count=0
  fi
done < "$PATHS_CONFIG"

if ! wait_batch; then
  sync_failed=1
fi
if [ "$sync_failed" -ne 0 ]; then
  echo 'one or more paths failed; keeping latest as resumable work in progress' >&2
  exit 1
fi

printf '{"generation":"%s","completedAt":"%s"}\n' "$today" "$(date -Iseconds)" > /tmp/backup-state/latest-success.json
rclone copyto /tmp/backup-state/latest-success.json "$latest/_SUCCESS"
rclone copyto /tmp/backup-state/latest-success.json "$state/latest-success.json"
rclone delete "$state" --include '/IN_PROGRESS' --max-depth 1
echo "backup completed: $latest"
