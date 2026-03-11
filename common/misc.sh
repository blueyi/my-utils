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

# Ensure git is installed before configuring (bootstrap order: packages before misc; here we install if still missing)
ensure_git() {
  if command -v git &>/dev/null; then
    return 0
  fi
  if is_macos; then
    ensure_brew
    echo "Installing git (Homebrew)..."
    brew install git || { echo "  WARN: brew install git failed; run packages step or install git manually"; return 1; }
  else
    case "$(detect_package_manager)" in
      apt)
        echo "Installing git (apt)..."
        sudo apt-get update -qq && sudo apt-get install -y git || { echo "  WARN: apt install git failed"; return 1; }
        ;;
      yum)
        echo "Installing git (dnf/yum)..."
        (command -v dnf &>/dev/null && sudo dnf install -y git) || sudo yum install -y git || { echo "  WARN: dnf/yum install git failed"; return 1; }
        ;;
      *)
        echo "  WARN: git not found and unknown package manager; run bootstrap packages step or install git manually"
        return 1
        ;;
    esac
  fi
}

# Git config (only after git is installed)
ensure_git && {
  git config --global user.name "yulong"
  git config --global user.email "yl.w@outlook.com"
  git config --global core.editor "vim"
} || true

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

# pyenv-virtualenv plugin (for `pyenv virtualenv-init`)
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [ -d "$PYENV_ROOT" ]; then
  if [ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
    echo "Installing pyenv-virtualenv plugin..."
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv" || \
      echo "  WARN: git clone pyenv-virtualenv failed; run manually: git clone https://github.com/pyenv/pyenv-virtualenv.git \"$PYENV_ROOT/plugins/pyenv-virtualenv\""
  else
    echo "pyenv-virtualenv plugin already installed"
  fi
fi

# --- Hexo blog dependencies (Node.js + hexo-cli), Linux + macOS ---
ensure_hexo_env() {
  # Ensure Node.js is available
  if command -v node &>/dev/null && command -v npm &>/dev/null; then
    : # already have node/npm (e.g. from nvm, brew, or system)
  else
    if is_macos; then
      ensure_brew
      if ! command -v node &>/dev/null; then
        echo "Installing Node.js for Hexo (Homebrew)..."
        brew install node || echo "  WARN: brew install node failed; install manually for Hexo"
      fi
    else
      case "$(detect_package_manager)" in
        apt)
          if ! command -v node &>/dev/null; then
            echo "Installing Node.js/npm for Hexo (apt)..."
            sudo apt-get update -qq && sudo apt-get install -y nodejs npm || echo "  WARN: apt install nodejs npm failed"
          fi
          ;;
        yum)
          if ! command -v node &>/dev/null; then
            echo "Installing Node.js for Hexo (dnf/yum)..."
            (command -v dnf &>/dev/null && sudo dnf install -y nodejs) || sudo yum install -y nodejs || echo "  WARN: dnf/yum install nodejs failed"
          fi
          ;;
        *)
          echo "  Skip Hexo: unknown Linux package manager; install Node.js manually"
          return 0
          ;;
      esac
    fi
  fi
  # Install hexo-cli globally if not present
  if command -v hexo &>/dev/null; then
    echo "hexo-cli already installed"
  elif command -v npm &>/dev/null; then
    echo "Installing hexo-cli (npm install -g hexo-cli)..."
    npm install -g hexo-cli || echo "  WARN: npm install -g hexo-cli failed; run manually if needed"
  fi
}

ensure_hexo_env
