#!/usr/bin/env bash
# Sync Cursor config to cursor_bak and symlink back
# All config lives in workspace/cursor_bak; Cursor uses it via symlinks
#
# Usage: ./cursor_config_link.sh [--restore]
#   Default: backup current config to cursor_bak, then create symlinks
#   --restore: remove symlinks, copy cursor_bak back to original locations

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$COMMON_DIR/.." && pwd -P)"
CURSOR_BAK="$ROOT/cursor_bak"

# macOS paths
CURSOR_APP_SUPPORT="$HOME/Library/Application Support/Cursor"
CURSOR_USER="$CURSOR_APP_SUPPORT/User"
CURSOR_RULES="$HOME/.cursor/rules"

bak_user() {
  mkdir -p "$CURSOR_BAK/User"
  [ -d "$CURSOR_USER" ] || [ -L "$CURSOR_USER" ] || return 0
  for f in settings.json keybindings.json mcp.json chatLanguageModels.json; do
    [ -f "$CURSOR_USER/$f" ] && cp "$CURSOR_USER/$f" "$CURSOR_BAK/User/"
  done
  [ -d "$CURSOR_USER/snippets" ] && cp -r "$CURSOR_USER/snippets" "$CURSOR_BAK/User/"
}

bak_rules() {
  mkdir -p "$CURSOR_BAK/rules"
  [ -d "$CURSOR_RULES" ] || return 0
  cp -r "$CURSOR_RULES"/* "$CURSOR_BAK/rules/" 2>/dev/null || true
}

link_user() {
  mkdir -p "$CURSOR_APP_SUPPORT"
  # Ensure cursor_bak/User has minimal content
  mkdir -p "$CURSOR_BAK/User/snippets"
  [ -f "$CURSOR_BAK/User/settings.json" ] || echo '{}' > "$CURSOR_BAK/User/settings.json"
  if [ -e "$CURSOR_USER" ] && [ ! -L "$CURSOR_USER" ]; then
    bak_user
    mv "$CURSOR_USER" "${CURSOR_USER}.bak.$(date +%Y%m%d%H%M%S)"
  elif [ -L "$CURSOR_USER" ]; then
    existing=$(readlink "$CURSOR_USER")
    if [[ "$existing" != "$CURSOR_BAK/User"* ]]; then
      bak_user
      rm "$CURSOR_USER"
    fi
  else
    bak_user
  fi
  ln -sf "$CURSOR_BAK/User" "$CURSOR_USER"
  echo "  $CURSOR_USER -> $CURSOR_BAK/User"
}

link_rules() {
  mkdir -p "$CURSOR_BAK/rules"
  mkdir -p "$HOME/.cursor"
  if [ -d "$CURSOR_RULES" ] && [ ! -L "$CURSOR_RULES" ]; then
    bak_rules
    mv "$CURSOR_RULES" "${CURSOR_RULES}.bak.$(date +%Y%m%d%H%M%S)"
  elif [ -L "$CURSOR_RULES" ]; then
    existing=$(readlink "$CURSOR_RULES")
    if [[ "$existing" != "$CURSOR_BAK/rules"* ]]; then
      bak_rules
      rm "$CURSOR_RULES"
    fi
  else
    bak_rules
  fi
  ln -sf "$CURSOR_BAK/rules" "$CURSOR_RULES"
  echo "  $CURSOR_RULES -> $CURSOR_BAK/rules"
}

restore_user() {
  [ -L "$CURSOR_USER" ] || return 0
  bak_dir=$(readlink "$CURSOR_USER")
  [ -d "$bak_dir" ] || return 0
  rm "$CURSOR_USER"
  cp -r "$bak_dir" "$CURSOR_USER"
  echo "  Restored User from $bak_dir"
}

restore_rules() {
  [ -L "$CURSOR_RULES" ] || return 0
  bak_dir=$(readlink "$CURSOR_RULES")
  [ -d "$bak_dir" ] || return 0
  rm "$CURSOR_RULES"
  mkdir -p "$CURSOR_RULES"
  cp -r "$bak_dir"/* "$CURSOR_RULES/" 2>/dev/null || true
  echo "  Restored rules from $bak_dir"
}

# Extensions list (for reference, not symlinked)
save_extensions() {
  cursor --list-extensions > "$CURSOR_BAK/extensions.txt" 2>/dev/null || true
}

RESTORE=false
[[ "${1:-}" == "--restore" ]] && RESTORE=true

if [ "$RESTORE" = true ]; then
  echo "=== Restore Cursor config from cursor_bak ==="
  restore_user
  restore_rules
else
  echo "=== Link Cursor config to cursor_bak ==="
  echo "cursor_bak: $CURSOR_BAK"
  save_extensions
  link_user
  link_rules
  echo "=== Done. Edit files in cursor_bak/ and commit to git. ==="
fi
