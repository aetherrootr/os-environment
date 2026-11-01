#!/bin/sh
set -eu

# This is run in spec.source.path. CMP receives the full repository, including
# sibling local Jsonnet dependencies; do not restrict the tar stream to this app.
case "${ARGOCD_ENV_TANKA_ENV:-}" in
  env/*.jsonnet) ;;
  *) echo 'TANKA_ENV must be a relative env/*.jsonnet entry' >&2; exit 1 ;;
esac
case "$ARGOCD_ENV_TANKA_ENV" in
  *..*) echo 'TANKA_ENV must not contain ..' >&2; exit 1 ;;
esac
test -f "$ARGOCD_ENV_TANKA_ENV"
test -f jsonnetfile.lock.json

# A render must not silently resolve newer dependencies or rewrite the lock.
lock_before=$(sha256sum jsonnetfile.lock.json)
jb install >&2
test "$lock_before" = "$(sha256sum jsonnetfile.lock.json)" || {
  echo 'jb changed jsonnetfile.lock.json; refresh and commit the lock locally' >&2
  exit 1
}
if test -f chartfile.yaml; then
  tk tool charts vendor >&2
fi
