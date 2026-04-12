#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPOSTS_DIR="$SCRIPT_DIR/outposts"

ACTION="apply"
ENV_NAME="prod"

usage() {
  cat <<'EOF'
Usage: ./update_outposts.sh [options] [outpost-name ...]

Batch update Authentik outposts with Tanka.

Options:
  --env <name>   Environment name to apply, defaults to prod
  --diff         Preview changes with tk diff instead of tk apply
  -h, --help     Show this help message

Examples:
  ./update_outposts.sh
  ./update_outposts.sh --diff
  ./update_outposts.sh sonarr radarr
EOF
}

FILTERS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --env)
      if [ "$#" -lt 2 ]; then
        echo "error: --env requires a value" >&2
        exit 1
      fi
      ENV_NAME="$2"
      shift 2
      ;;
    --diff)
      ACTION="diff"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      FILTERS+=("$1")
      shift
      ;;
  esac
done

shopt -s nullglob

env_files=(
  "$OUTPOSTS_DIR"/*/env/"$ENV_NAME".jsonnet
  "$OUTPOSTS_DIR"/*/env/*/"$ENV_NAME".jsonnet
)

selected_files=()

for env_file in "${env_files[@]}"; do
  if [ "${#FILTERS[@]}" -eq 0 ]; then
    selected_files+=("$env_file")
    continue
  fi

  env_parent="$(basename "$(dirname "$env_file")")"
  outpost_type="$(basename "$(dirname "$(dirname "$env_file")")")"

  if [ "$env_parent" = "env" ]; then
    env_name="$outpost_type"
  else
    env_name="$env_parent"
  fi

  for filter in "${FILTERS[@]}"; do
    if [ "$env_name" = "$filter" ] || [ "$outpost_type" = "$filter" ]; then
      selected_files+=("$env_file")
      break
    fi
  done
done

if [ "${#selected_files[@]}" -eq 0 ]; then
  echo "No outpost environments matched." >&2
  exit 1
fi

echo "Running tk $ACTION for ${#selected_files[@]} outpost environment(s)..."

for env_file in "${selected_files[@]}"; do
  outpost_dir="${env_file%%/env/*}"
  relative_env_file="${env_file#"$outpost_dir"/}"

  echo
  echo "==> $relative_env_file"
  (
    cd "$outpost_dir"
    tk "$ACTION" "$relative_env_file"
  )
done

echo
echo "Done."
