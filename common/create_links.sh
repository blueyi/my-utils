#!/usr/bin/env bash
# Create soft links from link.ini
# Config files stay in repo; ~/.vimrc etc point to them for easy git backup

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$COMMON_DIR/.." && pwd)"
LINK_FILE="$COMMON_DIR/link.ini"

# Write MY_UTILS_ROOT for rc files to use (they source this for portable paths)
ENV_FILE="$HOME/.my-utils.env"
echo "export MY_UTILS_ROOT=\"$ROOT\"" > "$ENV_FILE"
echo "export MYRC_PATH=\"\$MY_UTILS_ROOT/config\"" >> "$ENV_FILE"
echo "Created $ENV_FILE"

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
