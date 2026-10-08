#!/usr/bin/env bash
# Privacy vault helper — backup or restore privacy/*.enc
# Usage:
#   run_env_sync.sh [backup|restore]
#   MY_UTILS_VAULT_ACTION=backup run_env_sync.sh
# Default: restore (bootstrap --tools env)
#
# On restore: if env.rc cannot be decrypted / is missing, create an empty
# config/env.rc stub and still refresh symlinks (~/.env.rc → config/env.rc).

set -e
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$MY_UTILS_ROOT"
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fi

ENV_SYNC="$ROOT/tools/env_sync/env_sync.py"
MANIFEST="$ROOT/privacy/manifest"
LINKS_SH="$ROOT/common/create_links.sh"
ACTION="${1:-${MY_UTILS_VAULT_ACTION:-restore}}"
FORCE_ARGS=()
[ "${MY_UTILS_FORCE:-}" = "1" ] && FORCE_ARGS+=(--force)

_myu_ensure_env_rc_stub() {
  local f="$ROOT/config/env.rc"
  if [ -f "$f" ]; then
    return 0
  fi
  mkdir -p "$(dirname "$f")"
  cat > "$f" <<'EOF'
# config/env.rc — machine-local overrides + Claude Code / Codex keys (gitignored).
# Symlink: ~/.env.rc → this file (via common/link.ini).
# Full template: config/env.rc.example
#
# Auto-created because vault restore did not produce this file.
# Hermes agent keys stay in ~/.hermes/.env (private git) — leave that tree alone.
#
# export MY_UTILS_PROXY=on
# export ANTHROPIC_BASE_URL='https://www.onerouter.one'
# export ANTHROPIC_AUTH_TOKEN=''
# export OPENAI_API_KEY=''
# export OPENAI_BASE_URL=''
EOF
  chmod 600 "$f" 2>/dev/null || true
  echo "  Created empty stub: $f"
}

_myu_refresh_links() {
  if [ -x "$LINKS_SH" ] || [ -f "$LINKS_SH" ]; then
    echo "  Refreshing symlinks (incl. ~/.env.rc → config/env.rc)…"
    bash "$LINKS_SH" || echo "  WARN: create_links.sh reported errors"
  else
    echo "  WARN: missing $LINKS_SH — skip symlink refresh"
  fi
}

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
    if [ "$ACTION" = "restore" ]; then
      _myu_ensure_env_rc_stub
      _myu_refresh_links
    fi
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

restore_rc=0
if [ "$enc_count" -eq 0 ]; then
  echo "  No privacy/*.enc in repo yet."
  echo "  On the old machine:"
  echo "    ./myu vault backup"
  echo "    git add privacy/*.enc && git commit && git push"
  echo "  Creating empty config/env.rc so ~/.env.rc can be linked."
else
  echo "  Found $enc_count encrypted blob(s). Restoring…"
  set +e
  python3 "$ENV_SYNC" vault-restore --manifest "$MANIFEST" "${FORCE_ARGS[@]}"
  restore_rc=$?
  set -e
fi

_myu_ensure_env_rc_stub
_myu_refresh_links

if [ "$restore_rc" -ne 0 ]; then
  echo "=== Privacy vault restore finished with errors (exit $restore_rc) ==="
  echo "  env.rc stub + symlinks are in place; fix SYNC_ENV_KEY and re-run:"
  echo "    ./myu vault restore --force"
  exit "$restore_rc"
fi

echo "=== Privacy vault restore done ==="
echo "  Tip: exec \$SHELL  # reload ~/.env.rc / optional_home snippets"
