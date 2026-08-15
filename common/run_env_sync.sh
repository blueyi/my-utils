#!/usr/bin/env bash
# Optional env.rc sync helper for bootstrap --tools env
# Does not decrypt without SYNC_ENV_KEY. Never stores secrets in the repo.

set -e
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$MY_UTILS_ROOT"
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fi

ENV_SYNC="$ROOT/tools/env_sync/env_sync.py"
ENC_DEFAULT="${XDG_STATE_HOME:-$HOME/.local/state}/my-utils/env.rc.enc"

echo "=== Env sync (optional) ==="
echo "Encrypted backup default: $ENC_DEFAULT"
echo "Set SYNC_ENV_KEY in the environment (or ~/.env.rc) before decrypt/merge."
echo ""

if [ ! -f "$ENV_SYNC" ]; then
  echo "  WARN: $ENV_SYNC not found"
  exit 0
fi

if [ -z "${SYNC_ENV_KEY:-}" ]; then
  echo "  SYNC_ENV_KEY unset — skip decrypt (by design)."
  echo "  Examples:"
  echo "    export SYNC_ENV_KEY='…'"
  echo "    python3 \"$ENV_SYNC\" decrypt --output /tmp/env.rc.backup"
  echo "    python3 \"$ENV_SYNC\" merge --local ~/.env.rc --backup /tmp/env.rc.backup --dry-run"
  echo "  Or after bootstrap:"
  echo "    ./bootstrap.sh --tools env --yes   # still needs SYNC_ENV_KEY to decrypt"
  exit 0
fi

if [ ! -f "$ENC_DEFAULT" ]; then
  echo "  No encrypted backup at $ENC_DEFAULT"
  echo "  Create one on the old machine: python3 \"$ENV_SYNC\" encrypt"
  exit 0
fi

echo "  Decrypting $ENC_DEFAULT …"
if python3 "$ENV_SYNC" decrypt --output /tmp/my-utils-env.rc.backup; then
  echo "  Wrote /tmp/my-utils-env.rc.backup"
  echo "  Review, then merge:"
  echo "    python3 \"$ENV_SYNC\" merge --local ~/.env.rc --backup /tmp/my-utils-env.rc.backup"
else
  echo "  WARN: decrypt failed"
  exit 1
fi

echo "=== Env sync done ==="
