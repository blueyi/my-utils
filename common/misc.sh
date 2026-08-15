#!/usr/bin/env bash
# Idempotent misc setup: git, oh-my-zsh, uv
# Sourced by run_misc.sh

set -e
# Use MY_UTILS_ROOT when set (e.g. from run_misc.sh under bootstrap); else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$COMMON_DIR/platform.sh"

# Ensure Homebrew is installed on macOS (required for uv and other brew packages)
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

_misc_force() {
  [ "${MY_UTILS_FORCE:-}" = "1" ] || [ "${MY_UTILS_FORCE:-}" = "true" ]
}

# Ensure git is installed before configuring (bootstrap order: packages before misc; here we install if still missing)
ensure_git() {
  if command -v git &>/dev/null; then
    if _misc_force && is_macos && command -v brew &>/dev/null && brew list git &>/dev/null 2>/dev/null; then
      echo "Reinstalling git (Homebrew, --force)..."
      brew reinstall git || echo "  WARN: brew reinstall git failed"
    fi
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

# Oh My Zsh (unattended: no chsh, no new shell; KEEP_ZSHRC preserves symlinked ~/.zshrc)
install_omz_plugins() {
  [ -d "$HOME/.oh-my-zsh" ] || return 0
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ ! -d "$custom/plugins/zsh-autosuggestions" ]; then
    echo "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions" || true
  fi
  if [ ! -d "$custom/plugins/zsh-syntax-highlighting" ]; then
    echo "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting" || true
  fi
  if [ ! -d "$custom/themes/powerlevel10k" ]; then
    echo "Cloning powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k" || true
  fi
}

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  KEEP_ZSHRC=yes CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
  install_omz_plugins
else
  echo "Oh My Zsh already installed"
  install_omz_plugins
fi

# fzf (Ubuntu/WSL: apt; macOS: Homebrew)
if is_macos; then
  ensure_brew
  if command -v brew &>/dev/null; then
    if brew list fzf &>/dev/null; then
      if _misc_force; then
        echo "Reinstalling fzf (Homebrew, --force)..."
        brew reinstall fzf || echo "  WARN: brew reinstall fzf failed"
      else
        echo "fzf already installed (use --force to reinstall)"
      fi
    else
      brew install fzf || echo "  WARN: brew install fzf failed"
    fi
  fi
else
  case "$(detect_package_manager)" in
    apt)
      if command -v fzf &>/dev/null; then
        if _misc_force; then
          echo "Reinstalling fzf (apt, --force)..."
          sudo apt-get install --reinstall -y fzf || echo "  WARN: apt reinstall fzf failed"
        else
          echo "fzf already installed (use --force to reinstall)"
        fi
      else
        echo "Installing fzf (apt)..."
        sudo apt-get update -qq && sudo apt-get install -y fzf || echo "  WARN: apt install fzf failed"
      fi
      ;;
  esac
fi

# Default login shell → zsh (may fail on some WSL setups without extra permissions)
if command -v zsh &>/dev/null; then
  _zsh_bin="$(command -v zsh)"
  if [ -n "${SHELL:-}" ] && [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "Setting default login shell to zsh ($_zsh_bin)..."
    chsh -s "$_zsh_bin" 2>/dev/null || echo "  WARN: chsh failed; on WSL try: chsh from a login shell or set default in /etc/passwd / wsl.conf"
  else
    echo "Login shell already zsh or SHELL unset; skip chsh"
  fi
  unset _zsh_bin
fi

# uv: macOS = brew install (see Brewfile / mac_app_list.txt); Linux = official install script
ensure_uv() {
  if command -v uv &>/dev/null; then
    if _misc_force && is_macos && command -v brew &>/dev/null && brew list uv &>/dev/null 2>/dev/null; then
      echo "Reinstalling uv via Homebrew (--force)..."
      brew reinstall uv || echo "  WARN: brew reinstall uv failed"
    else
      echo "uv already installed ($(uv --version 2>/dev/null || echo ok); use --force to reinstall)"
    fi
    return 0
  fi
  if is_macos; then
    ensure_brew
    echo "Installing uv via Homebrew..."
    brew install uv || { echo "  WARN: brew install uv failed; run manually: brew install uv"; return 1; }
  else
    echo "Installing uv (official install script)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh || { echo "  WARN: uv install failed; see https://docs.astral.sh/uv/getting-started/installation/"; return 1; }
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
  fi
}

ensure_uv_python_default() {
  command -v uv &>/dev/null || return 0
  local _py="${UV_DEFAULT_PYTHON:-3.12}"
  echo "Ensuring default Python ${_py} via uv..."
  uv python install "$_py" --default --preview-features python-install-default 2>/dev/null || \
    uv python install "$_py" --default || \
    uv python install "$_py" || \
    echo "  WARN: uv python install ${_py} failed"
  uv python pin --global "$_py" 2>/dev/null || true
}

ensure_uv
ensure_uv_python_default

# --- Hexo blog dependencies (Node.js + hexo-cli), Linux + macOS ---
ensure_hexo_env() {
  # Ensure Node.js is available
  if command -v node &>/dev/null && command -v npm &>/dev/null; then
    if _misc_force && is_macos && command -v brew &>/dev/null && brew list node &>/dev/null 2>/dev/null; then
      echo "Reinstalling Node.js (Homebrew, --force)..."
      brew reinstall node || echo "  WARN: brew reinstall node failed"
    fi
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
    if _misc_force && command -v npm &>/dev/null; then
      echo "Reinstalling hexo-cli (npm, --force)..."
      npm install -g hexo-cli || echo "  WARN: npm reinstall hexo-cli failed"
    else
      echo "hexo-cli already installed (use --force to reinstall)"
    fi
  elif command -v npm &>/dev/null; then
    echo "Installing hexo-cli (npm install -g hexo-cli)..."
    npm install -g hexo-cli || echo "  WARN: npm install -g hexo-cli failed; run manually if needed"
  fi
}

ensure_hexo_env

# --- macOS: brew on login PATH (~/.zprofile / ~/.bash_profile) ---
ensure_brew_login_path() {
  is_macos || return 0
  local brew_bin="" begin end target tmp
  if [ -x /opt/homebrew/bin/brew ]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    brew_bin=/usr/local/bin/brew
  elif command -v brew &>/dev/null; then
    brew_bin="$(command -v brew)"
  else
    echo "  Skip brew login PATH (brew not found)"
    return 0
  fi
  begin="# >>> my-utils brew >>>"
  end="# <<< my-utils brew <<<"
  for target in "$HOME/.zprofile" "$HOME/.bash_profile"; do
    touch "$target"
    if grep -qF "$begin" "$target" 2>/dev/null; then
      if _misc_force; then
        tmp="$(mktemp)"
        awk -v b="$begin" -v e="$end" '
          $0 == b { skip=1; next }
          $0 == e { skip=0; next }
          !skip { print }
        ' "$target" > "$tmp"
        {
          echo ""
          echo "$begin"
          echo "# Managed by my-utils misc (idempotent)."
          echo "if [ -x \"$brew_bin\" ]; then"
          echo "  eval \"\$(\"$brew_bin\" shellenv)\""
          echo "fi"
          echo "$end"
        } >> "$tmp"
        mv "$tmp" "$target"
        echo "  Updated brew shellenv block in $target (forced)"
      else
        echo "  brew shellenv already in $target"
      fi
    else
      {
        echo ""
        echo "$begin"
        echo "# Managed by my-utils misc (idempotent)."
        echo "if [ -x \"$brew_bin\" ]; then"
        echo "  eval \"\$(\"$brew_bin\" shellenv)\""
        echo "fi"
        echo "$end"
      } >> "$target"
      echo "  Added brew shellenv to $target"
    fi
  done
  eval "$("$brew_bin" shellenv)" 2>/dev/null || true
}

# --- rustup: ensure a default toolchain so cargo/rustc work ---
ensure_rustup_default() {
  if ! command -v rustup &>/dev/null; then
    for p in /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin; do
      [ -x "$p/rustup" ] && export PATH="$p:$PATH"
    done
  fi
  command -v rustup &>/dev/null || {
    echo "  Skip rustup default (rustup not installed yet; run packages first)"
    return 0
  }
  if rustup show 2>/dev/null | grep -q '(default)'; then
    if _misc_force; then
      echo "Reinstalling default rust toolchain (stable, --force)..."
      rustup default stable || echo "  WARN: rustup default stable failed"
    else
      echo "rustup default toolchain already set"
    fi
    return 0
  fi
  echo "Setting rustup default toolchain to stable..."
  rustup default stable || echo "  WARN: rustup default stable failed"
}

ensure_brew_login_path
ensure_rustup_default
