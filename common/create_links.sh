#!/usr/bin/env bash
# Create soft links from link.ini
# Config files stay in repo; ~/.vimrc etc point to them for easy git backup

set -e
# Use MY_UTILS_ROOT from bootstrap when set; else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$(cd "$MY_UTILS_ROOT" && pwd -P)"
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(cd "$COMMON_DIR/.." && pwd -P)"
fi
LINK_FILE="$COMMON_DIR/link.ini"

# Write config/my-utils.env (source by rc via symlink ~/.my-utils.env -> config/my-utils.env)
ENV_FILE="$ROOT/config/my-utils.env"
if [[ "$ROOT" == "$HOME"/* ]]; then
  _rel="${ROOT#"$HOME"/}"
  echo "export MY_UTILS_ROOT=\"\$HOME/$_rel\"" > "$ENV_FILE"
else
  echo "export MY_UTILS_ROOT=\"$ROOT\"" > "$ENV_FILE"
fi
echo "export MYRC_PATH=\"\$MY_UTILS_ROOT/config\"" >> "$ENV_FILE"
echo "Created $ENV_FILE (link ~/.my-utils.env in link.ini)"
unset _rel

echo "=== Creating soft links ==="

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$line" ] && continue

  # Format: source_path target_path (both relative or ~ for home)
  read -r src tgt <<< "$line"
  src="${src// /}"
  tgt=$(echo "$tgt" | tr -s ' ' ' ' | xargs)
  [ -z "$src" ] || [ -z "$tgt" ] && continue

  src_full="$ROOT/$src"
  tgt_full="${tgt/#\~/$HOME}"

  # Skip if source doesn't exist (e.g. optional configs)
  if [ ! -e "$src_full" ]; then
    echo "  Skip $src (not found)"
    continue
  fi

  # Avoid circular link: if target parent resolves inside repo, skip.
  # (e.g. ~/.config -> repo/config, or ~/.pip -> repo/config/pip)
  tgt_parent="$(dirname "$tgt_full")"
  if [ -e "$tgt_parent" ]; then
    canon="$(cd "$tgt_parent" 2>/dev/null && pwd -P)" || true
    if [[ -n "$canon" && "$canon" == "$ROOT"* ]]; then
      echo "  Skip $tgt (circular link: target parent resolves inside repo)"
      continue
    fi
  fi

  # If target is already a symlink, check it points to the expected source (idempotent)
  if [ -L "$tgt_full" ]; then
    current_target=$(readlink "$tgt_full")
    [[ -z "$current_target" ]] && current_target=""
    if [[ "$current_target" != /* ]]; then
      current_abs="$(dirname "$tgt_full")/$current_target"
    else
      current_abs="$current_target"
    fi
    expected_canon=$(cd "$(dirname "$src_full")" 2>/dev/null && echo "$(pwd -P)/$(basename "$src_full")") || true
    current_canon=$(cd "$(dirname "$current_abs")" 2>/dev/null && echo "$(pwd -P)/$(basename "$current_abs")") || true
    if [[ -n "$expected_canon" && -n "$current_canon" && "$current_canon" == "$expected_canon" ]]; then
      echo "  $tgt_full (already points to expected)"
      continue
    fi
  fi

  if [ -e "$tgt_full" ] && [ ! -L "$tgt_full" ]; then
    bak="${tgt_full}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  Backup: $tgt_full -> $bak"
    mv "$tgt_full" "$bak"
  fi

  mkdir -p "$(dirname "$tgt_full")"
  ln -sf "$src_full" "$tgt_full"
  echo "  $tgt_full -> $src_full"
done < "$LINK_FILE"

echo "=== Links created ==="
