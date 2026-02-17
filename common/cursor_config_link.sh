#!/usr/bin/env bash
# Cursor config backup: sync to cursor_bak and symlink back.
# Backed up: User/, rules/, Preferences, ide_state.json (all under cursor_bak).
# Symlinks use absolute paths so config survives reboot.
#
# Usage: ./cursor_config_link.sh [--restore]
#   Default: backup current config to cursor_bak, then create symlinks
#   --restore: remove symlinks, copy cursor_bak back to original locations

set -e
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$(cd "$MY_UTILS_ROOT" && pwd -P)"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(cd "$COMMON_DIR/.." && pwd -P)"
fi
CURSOR_BAK="$ROOT/cursor_bak"

# Platform: Cursor Application Support path (macOS vs Linux)
case "$(uname -s)" in
  Darwin*) CURSOR_APP_SUPPORT="$HOME/Library/Application Support/Cursor" ;;
  Linux*)  CURSOR_APP_SUPPORT="$HOME/.config/Cursor" ;;
  *)       CURSOR_APP_SUPPORT="" ;;
esac
CURSOR_RULES="$HOME/.cursor/rules"
CURSOR_PROJECTS="$HOME/.cursor/projects"

# --- Cursor config inventory ---
# Items under Application Support (path relative to CURSOR_APP_SUPPORT):
#   type: dir -> backup as dir, symlink whole dir
#   type: file -> backup as file, symlink file
# Items under $HOME (full path):
#   type: rules -> special: ~/.cursor/rules
CURSOR_APP_ITEMS=(
  "User:dir"
  "Preferences:file"
  "ide_state.json:file"
)

# Backup a single file from App Support into cursor_bak
bak_app_file() {
  local name="$1"
  local src="$CURSOR_APP_SUPPORT/$name"
  local dst="$CURSOR_BAK/$name"
  [ -f "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

# Backup a single dir from App Support (only key files for User; full copy for others)
bak_user_dir() {
  mkdir -p "$CURSOR_BAK/User"
  [ -d "$CURSOR_APP_SUPPORT/User" ] || [ -L "$CURSOR_APP_SUPPORT/User" ] || return 0
  # When User is already our symlink, skip copy (same in/out)
  if [ -L "$CURSOR_APP_SUPPORT/User" ]; then
    r=$(readlink "$CURSOR_APP_SUPPORT/User" 2>/dev/null)
    [[ "$r" == *"cursor_bak/User"* ]] && return 0
  fi
  local u="$CURSOR_APP_SUPPORT/User"
  for f in settings.json keybindings.json mcp.json chatLanguageModels.json; do
    [ -f "$u/$f" ] && cp "$u/$f" "$CURSOR_BAK/User/" 2>/dev/null || true
  done
  [ -d "$u/snippets" ] && cp -r "$u/snippets" "$CURSOR_BAK/User/" 2>/dev/null || true
}

# Generic: ensure target is symlink to cursor_bak, backup first if needed
link_app_item() {
  local name="$1"
  local type="$2"
  local src="$CURSOR_APP_SUPPORT/$name"
  local dst="$CURSOR_BAK/$name"

  # Already points to cursor_bak: skip backup and link
  if [ -L "$src" ]; then
    existing=$(readlink "$src")
    existing_abs=$existing
    [[ "$existing_abs" != /* ]] && existing_abs="$(dirname "$src")/$existing_abs"
    expected_canon=$(cd "$(dirname "$dst")" 2>/dev/null && pwd -P)/$(basename "$dst")
    existing_canon=$(cd "$(dirname "$existing_abs")" 2>/dev/null && pwd -P)/$(basename "$existing_abs") 2>/dev/null || true
    if [[ -n "$expected_canon" && "$existing_canon" == "$expected_canon" ]]; then
      echo "  $src (already points to expected)"
      return 0
    fi
  fi

  if [ "$name" = "User" ]; then
    bak_user_dir
    mkdir -p "$CURSOR_BAK/User/snippets"
    [ -f "$CURSOR_BAK/User/settings.json" ] || echo '{}' > "$CURSOR_BAK/User/settings.json"
  elif [ "$type" = "file" ]; then
    [ -f "$src" ] && bak_app_file "$name"
    [ -f "$dst" ] || return 0
  fi

  if [ -e "$src" ]; then
    if [ "$name" = "User" ]; then
      bak_user_dir
    elif [ "$type" = "file" ] && [ -f "$src" ]; then
      bak_app_file "$name"
    fi
    mv "$src" "${src}.bak.$(date +%Y%m%d%H%M%S)"
  fi

  if [ "$name" = "User" ] || [ -e "$dst" ]; then
    mkdir -p "$(dirname "$src")"
    ln -sf "$dst" "$src"
    echo "  $src -> $dst"
  fi
}

link_user() {
  mkdir -p "$CURSOR_APP_SUPPORT"
  for entry in "${CURSOR_APP_ITEMS[@]}"; do
    local name="${entry%%:*}" type="${entry#*:}"
    link_app_item "$name" "$type"
  done
}

# --- Rules (~/.cursor/rules) ---
bak_rules() {
  mkdir -p "$CURSOR_BAK/rules"
  [ -d "$CURSOR_RULES" ] || return 0
  cp -r "$CURSOR_RULES"/* "$CURSOR_BAK/rules/" 2>/dev/null || true
}

# --- Projects (~/.cursor/projects): per-workspace state (terminals, agent-transcripts, mcps) ---
bak_projects() {
  mkdir -p "$CURSOR_BAK/projects"
  [ -d "$CURSOR_PROJECTS" ] || return 0
  cp -r "$CURSOR_PROJECTS"/* "$CURSOR_BAK/projects/" 2>/dev/null || true
}

link_rules() {
  mkdir -p "$CURSOR_BAK/rules"
  mkdir -p "$HOME/.cursor"
  if [ -L "$CURSOR_RULES" ]; then
    existing=$(readlink "$CURSOR_RULES")
    existing_abs=$existing
    [[ "$existing_abs" != /* ]] && existing_abs="$(dirname "$CURSOR_RULES")/$existing_abs"
    expected_canon=$(cd "$CURSOR_BAK/rules" 2>/dev/null && pwd -P) || true
    existing_canon=$(cd "$existing_abs" 2>/dev/null && pwd -P) || true
    if [[ -n "$expected_canon" && "$existing_canon" == "$expected_canon" ]]; then
      echo "  $CURSOR_RULES (already points to expected)"
      return 0
    fi
    if [[ "$existing" != "$CURSOR_BAK/rules"* ]]; then
      bak_rules
      rm "$CURSOR_RULES"
    fi
  elif [ -d "$CURSOR_RULES" ] || [ -e "$CURSOR_RULES" ]; then
    bak_rules
    mv "$CURSOR_RULES" "${CURSOR_RULES}.bak.$(date +%Y%m%d%H%M%S)"
  else
    bak_rules
  fi
  ln -sf "$CURSOR_BAK/rules" "$CURSOR_RULES"
  echo "  $CURSOR_RULES -> $CURSOR_BAK/rules"
}

link_projects() {
  mkdir -p "$CURSOR_BAK/projects"
  mkdir -p "$HOME/.cursor"
  if [ -L "$CURSOR_PROJECTS" ]; then
    existing=$(readlink "$CURSOR_PROJECTS")
    existing_abs=$existing
    [[ "$existing_abs" != /* ]] && existing_abs="$(dirname "$CURSOR_PROJECTS")/$existing_abs"
    expected_canon=$(cd "$CURSOR_BAK/projects" 2>/dev/null && pwd -P) || true
    existing_canon=$(cd "$existing_abs" 2>/dev/null && pwd -P) || true
    if [[ -n "$expected_canon" && "$existing_canon" == "$expected_canon" ]]; then
      echo "  $CURSOR_PROJECTS (already points to expected)"
      return 0
    fi
    rm "$CURSOR_PROJECTS"
  elif [ -d "$CURSOR_PROJECTS" ] || [ -e "$CURSOR_PROJECTS" ]; then
    bak_projects
    mv "$CURSOR_PROJECTS" "${CURSOR_PROJECTS}.bak.$(date +%Y%m%d%H%M%S)"
  else
    bak_projects
  fi
  ln -sf "$CURSOR_BAK/projects" "$CURSOR_PROJECTS"
  echo "  $CURSOR_PROJECTS -> $CURSOR_BAK/projects"
}

# --- Restore ---
restore_app_item() {
  local name="$1"
  local src="$CURSOR_APP_SUPPORT/$name"
  local dst="$CURSOR_BAK/$name"
  [ -L "$src" ] || return 0
  [ -e "$dst" ] || return 0
  rm "$src"
  if [ -d "$dst" ]; then
    cp -r "$dst" "$src"
  else
    cp "$dst" "$src"
  fi
  echo "  Restored $name from cursor_bak"
}

restore_user() {
  for entry in "${CURSOR_APP_ITEMS[@]}"; do
    restore_app_item "${entry%%:*}"
  done
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

restore_projects() {
  [ -L "$CURSOR_PROJECTS" ] || return 0
  bak_dir=$(readlink "$CURSOR_PROJECTS")
  [ -d "$bak_dir" ] || return 0
  rm "$CURSOR_PROJECTS"
  mkdir -p "$CURSOR_PROJECTS"
  cp -r "$bak_dir"/* "$CURSOR_PROJECTS/" 2>/dev/null || true
  echo "  Restored projects from $bak_dir"
}

save_extensions() {
  cursor --list-extensions > "$CURSOR_BAK/extensions.txt" 2>/dev/null || true
}

# --- Main ---
RESTORE=false
[[ "${1:-}" == "--restore" ]] && RESTORE=true

if [ -z "$CURSOR_APP_SUPPORT" ]; then
  echo "Unsupported platform for Cursor config"
  exit 1
fi

if [ "$RESTORE" = true ]; then
  echo "=== Restore Cursor config from cursor_bak ==="
  restore_user
  restore_rules
  restore_projects
else
  echo "=== Link Cursor config to cursor_bak ==="
  echo "cursor_bak: $CURSOR_BAK"
  echo "App Support: $CURSOR_APP_SUPPORT"
  save_extensions
  link_user
  link_rules
  link_projects
  echo "=== Done. Edit files in cursor_bak/ and commit to git. ==="
  echo "Backed up: User/, rules/, projects/, Preferences, ide_state.json (when present)."
fi
