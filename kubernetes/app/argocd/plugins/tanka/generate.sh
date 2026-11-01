#!/bin/sh
set -eu

# Buffer the result so a failed render never emits partial manifests.
output=$(mktemp)
trap 'rm -f "$output"' EXIT HUP INT TERM
tk show --dangerous-allow-redirect "$ARGOCD_ENV_TANKA_ENV" > "$output"
test -s "$output" || { echo 'Tanka rendered no resources' >&2; exit 1; }
cat "$output"
