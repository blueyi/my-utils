#!/usr/bin/env bash
# Privacy vault helper — backup or restore privacy/*.enc
# Usage:
#   run_env_sync.sh [backup|restore]
#   MY_UTILS_VAULT_ACTION=backup run_env_sync.sh
# Default: restore (bootstrap --tools env)

set -e
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$MY_UTILS_ROOT"
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fi

ENV_SYNC="$ROOT/tools/env_sync/env_sync.py"
MANIFEST="$ROOT/privacy/manifest"
ACTION="${1:-${MY_UTILS_VAULT_ACTION:-restore}}"
FORCE_ARGS=()
[ "${MY_UTILS_FORCE:-}" = "1" ] && FORCE_ARGS+=(--force)

case "$ACTION" in
  backup|restore) ;;
  *)
    echo "Usage: $0 [backup|restore]" >&2
    exit 2
    ;;
esac

echo "=== Privacy vault ($ACTION) ==="
echo "Manifest: $MANIFEST"
echo ""

if [ ! -f "$ENV_SYNC" ]; then
  echo "  WARN: $ENV_SYNC not found"
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  echo "  WARN: no privacy/manifest — nothing to do"
  exit 0
fi

if [ -z "${SYNC_ENV_KEY:-}" ]; then
  if [ -t 0 ]; then
    echo "  SYNC_ENV_KEY unset — will prompt for password (≥8 chars)."
  else
    echo "  SYNC_ENV_KEY unset and no TTY — cannot prompt."
    echo "  export SYNC_ENV_KEY='…' then re-run: ./myu vault $ACTION"
    exit 1
  fi
fi

if [ "$ACTION" = "backup" ]; then
  echo "  Encrypting sources → privacy/*.enc …"
  python3 "$ENV_SYNC" vault-backup --manifest "$MANIFEST" "${FORCE_ARGS[@]}"
  echo "=== Privacy vault backup done ==="
  echo "  Next:"
  echo "    git add privacy/*.enc privacy/manifest"
  echo "    git commit -m \"Update privacy vault\""
  echo "    git push"
  exit 0
fi

# restore
enc_count=0
for f in "$ROOT"/privacy/*.enc; do
  [ -f "$f" ] || continue
  enc_count=$((enc_count + 1))
done

if [ "$enc_count" -eq 0 ]; then
  echo "  No privacy/*.enc in repo yet."
  echo "  On the old machine:"
  echo "    ./myu vault backup"
  echo "    git add privacy/*.enc && git commit && git push"
  exit 0
fi

echo "  Found $enc_count encrypted blob(s). Restoring…"
python3 "$ENV_SYNC" vault-restore --manifest "$MANIFEST" "${FORCE_ARGS[@]}"
echo "=== Privacy vault restore done ==="
echo "  Tip: exec \$SHELL  # reload ~/.env.rc / optional_home snippets"
