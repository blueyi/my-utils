#!/usr/bin/env bash
# Install vim-plug and plugins from _vimrc
# Zero Python dependency

set -e
# Use MY_UTILS_ROOT from bootstrap when set; else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  ROOT="$(cd "$MY_UTILS_ROOT" && pwd)"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(cd "$COMMON_DIR/.." && pwd)"
fi
VIMRC="$ROOT/config/_vimrc"
PLUG_DIR="$HOME/.vim/autoload"
PLUGGED_DIR="$HOME/.vim/plugged"

mkdir -p "$HOME/.vimbak"
mkdir -p "$PLUGGED_DIR"
mkdir -p "$(dirname "$PLUG_DIR")"

# Install vim-plug
VIMRC_FAILS=0
if [ ! -f "$PLUG_DIR/plug.vim" ]; then
  echo "Installing vim-plug..."
  if ! curl -fLo "$PLUG_DIR/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
    echo "  WARN: vim-plug download failed"
    VIMRC_FAILS=$((VIMRC_FAILS + 1))
  fi
else
  echo "vim-plug already installed"
fi

# Install plugins via vim (batch mode: -E -s avoids "Press ENTER" prompt; pipe newline as fallback)
if [ -f "$PLUG_DIR/plug.vim" ]; then
  echo "Installing vim plugins (this may take a while)..."
  ( echo '' | vim -u "$VIMRC" -E -s -c "PlugInstall" -c "qall" 2>/dev/null ) || {
    echo "  WARN: PlugInstall failed; run manually: vim -u $VIMRC +PlugInstall +qall"
    VIMRC_FAILS=$((VIMRC_FAILS + 1))
  }
fi

if [ "$VIMRC_FAILS" -gt 0 ] || [ ! -f "$PLUG_DIR/plug.vim" ]; then
  echo "=== vimrc incomplete (will retry on next bootstrap) ==="
  exit 1
fi
