#!/usr/bin/env bash
# Idempotent misc setup: git, oh-my-zsh, pyenv
# Sourced by run_misc.sh

set -e
# Use MY_UTILS_ROOT when set (e.g. from run_misc.sh under bootstrap); else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$COMMON_DIR/platform.sh"

# Ensure Homebrew is installed on macOS (required for pyenv and other brew packages)
ensure_brew() {
  if command -v brew &>/dev/null; then
    return 0
  fi
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/brew" ] && export PATH="$p:$PATH" && return 0
  done
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

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

# pyenv: macOS = brew install (see mac_app_list.txt); Linux = git clone to ~/.pyenv
if is_macos; then
  ensure_brew
  if command -v pyenv &>/dev/null; then
    echo "pyenv already installed (Homebrew)"
  else
    echo "Installing pyenv via Homebrew..."
    brew install pyenv || echo "  WARN: brew install pyenv failed; run manually: brew install pyenv"
  fi
else
  if [ ! -d "$HOME/.pyenv" ]; then
    echo "Installing pyenv (git clone)..."
    git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
    (cd "$HOME/.pyenv" && src/configure && make -C src) || true
  else
    echo "pyenv already installed"
  fi
fi
