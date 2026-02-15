#!/usr/bin/env bash
# Idempotent misc setup: git, oh-my-zsh, pyenv
# Sourced by run_misc.sh

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$COMMON_DIR/platform.sh"

# Git config (idempotent)
git config --global user.name "blueyi" 2>/dev/null || true
git config --global user.email "blueyiniu@qq.com" 2>/dev/null || true

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  KEEP_ZSHRC=yes RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
else
  echo "Oh My Zsh already installed"
fi

# pyenv
if [ ! -d "$HOME/.pyenv" ]; then
  echo "Installing pyenv..."
  git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
  (cd "$HOME/.pyenv" && src/configure && make -C src) || true
else
  echo "pyenv already installed"
fi
