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

# Count soft failures so run_misc.sh can exit non-zero (no bootstrap stamp).
MY_UTILS_MISC_FAILS="${MY_UTILS_MISC_FAILS:-0}"
_misc_fail() {
  # Always return 0 so set -e continues remaining incremental steps.
  MY_UTILS_MISC_FAILS=$((MY_UTILS_MISC_FAILS + 1))
  echo "  WARN: $*" >&2
  return 0
}

# Clone or repair incomplete checkouts (failed network leaves dirs without .git).
_misc_git_clone() {
  local url="$1" dest="$2"
  shift 2
  if [ -d "$dest" ] && [ ! -d "$dest/.git" ]; then
    echo "  Removing incomplete clone: $dest"
    rm -rf "$dest"
  fi
  if [ -d "$dest/.git" ]; then
    return 0
  fi
  echo "Cloning $url → $dest ..."
  if git clone "$@" "$url" "$dest"; then
    return 0
  fi
  _misc_fail "git clone failed: $url"
  rm -rf "$dest" 2>/dev/null || true
  return 1
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
    brew install git || { _misc_fail "brew install git failed"; return 1; }
  else
    # Linux/WSL: system packages need sudo — keep that in packages step only.
    _misc_fail "git not found; run: ./bootstrap.sh --tools packages --yes"
    return 1
  fi
}

# Git config (only after git is installed)
if ensure_git; then
  git config --global user.name "yulong"
  git config --global user.email "yl.w@outlook.com"
  git config --global core.editor "vim"
else
  _misc_fail "git unavailable; skip git config / clone-dependent steps may fail"
fi

# Oh My Zsh (unattended: no chsh, no new shell; KEEP_ZSHRC preserves symlinked ~/.zshrc)
install_omz_plugins() {
  [ -d "$HOME/.oh-my-zsh" ] || return 0
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  command -v git &>/dev/null || { _misc_fail "git missing; cannot install OMZ plugins"; return 1; }
  _misc_git_clone https://github.com/zsh-users/zsh-autosuggestions \
    "$custom/plugins/zsh-autosuggestions" || true
  _misc_git_clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$custom/plugins/zsh-syntax-highlighting" || true
  _misc_git_clone https://github.com/romkatv/powerlevel10k.git \
    "$custom/themes/powerlevel10k" --depth=1 || true
}

if [ ! -d "$HOME/.oh-my-zsh" ] || [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  if [ -d "$HOME/.oh-my-zsh" ] && [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "  Removing incomplete Oh My Zsh install..."
    rm -rf "$HOME/.oh-my-zsh"
  fi
  echo "Installing Oh My Zsh..."
  if ! KEEP_ZSHRC=yes CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    _misc_fail "Oh My Zsh install failed (network?)"
  fi
  install_omz_plugins
else
  echo "Oh My Zsh already installed"
  install_omz_plugins
fi

# fzf (Ubuntu/WSL: via packages/apt; macOS: Homebrew — no sudo here)
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
      brew install fzf || _misc_fail "brew install fzf failed"
    fi
  fi
elif ! command -v fzf &>/dev/null; then
  _misc_fail "fzf not found; run: ./bootstrap.sh --tools packages --yes"
fi

# Default login shell → zsh (opt-in: MY_UTILS_CHSH=1 in ~/.env.rc).
# Off by default to avoid account-level /etc/passwd changes on macOS / WSL / Linux.
case "${MY_UTILS_CHSH:-off}" in
  1|true|on|ON|yes|YES)
    if command -v zsh &>/dev/null; then
      _zsh_bin="$(command -v zsh)"
      if [ -n "${SHELL:-}" ] && [ "$(basename "$SHELL")" != "zsh" ]; then
        echo "Setting default login shell to zsh ($_zsh_bin)..."
        chsh -s "$_zsh_bin" 2>/dev/null || echo "  WARN: chsh failed; on WSL try a login shell or /etc/wsl.conf"
      else
        echo "Login shell already zsh or SHELL unset; skip chsh"
      fi
      unset _zsh_bin
    fi
    ;;
  *)
    if command -v zsh &>/dev/null && [ -n "${SHELL:-}" ] && [ "$(basename "$SHELL")" != "zsh" ]; then
      echo "Skip chsh (login shell is $(basename "$SHELL")); set MY_UTILS_CHSH=1 in ~/.env.rc to switch to zsh"
    fi
    ;;
esac

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
    brew install uv || { _misc_fail "brew install uv failed"; return 1; }
  else
    echo "Installing uv (official install script)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh || { _misc_fail "uv install failed"; return 1; }
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
  if ! uv python install "$_py" --default --preview-features python-install-default 2>/dev/null \
    && ! uv python install "$_py" --default 2>/dev/null \
    && ! uv python install "$_py"; then
    _misc_fail "uv python install ${_py} failed"
  fi
  uv python pin --global "$_py" 2>/dev/null || true
}

ensure_uv || true
ensure_uv_python_default

# Hexo blog deps are opt-in: ./myu hexo --yes  or  ./bootstrap.sh --tools hexo --yes

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

if [ "${MY_UTILS_MISC_FAILS:-0}" -gt 0 ]; then
  echo "=== Misc incomplete: ${MY_UTILS_MISC_FAILS} step(s) failed (will retry on next bootstrap) ==="
  return 1 2>/dev/null || exit 1
fi
