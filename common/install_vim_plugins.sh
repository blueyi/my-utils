#!/usr/bin/env bash
# Install vim-plug and plugins from _vimrc
# Zero Python dependency

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$COMMON_DIR/.." && pwd)"
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

# Install plugins via vim (vim reads vimrc which has Plug declarations)
echo "Installing vim plugins (this may take a while)..."
vim -u "$VIMRC" +PlugInstall +qall 2>/dev/null || {
  echo "If vim failed, run manually: vim +PlugInstall +qall"
}
