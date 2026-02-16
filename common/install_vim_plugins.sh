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
if [ ! -f "$PLUG_DIR/plug.vim" ]; then
  echo "Installing vim-plug..."
  curl -fLo "$PLUG_DIR/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  echo "vim-plug already installed"
fi

# Install plugins via vim (batch mode: -E -s avoids "Press ENTER" prompt; pipe newline as fallback)
echo "Installing vim plugins (this may take a while)..."
( echo '' | vim -u "$VIMRC" -E -s -c "PlugInstall" -c "qall" 2>/dev/null ) || {
  echo "If vim failed, run manually: vim -u $VIMRC +PlugInstall +qall"
}
