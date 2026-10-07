#!/usr/bin/env bash
# Opt-in Hexo blog deps (Node.js + hexo-cli). Invoked via:
#   ./myu hexo --yes
#   ./bootstrap.sh --tools hexo --yes
# Not part of the default tool list.

set -e
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$COMMON_DIR/platform.sh"

_hexo_force() {
  [ "${MY_UTILS_FORCE:-}" = "1" ] || [ "${MY_UTILS_FORCE:-}" = "true" ]
}

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

ensure_npm_user_prefix() {
  command -v npm &>/dev/null || return 1
  local prefix="${HOME}/.npm-global"
  mkdir -p "$prefix"
  # Prefer session override when default prefix is not writable (e.g. /usr/local).
  # Linked ~/.npmrc also sets prefix=${HOME}/.npm-global after the links step.
  local cur
  cur="$(npm prefix -g 2>/dev/null || npm config get prefix 2>/dev/null || true)"
  if [ -z "$cur" ] || [ ! -w "$cur" ]; then
    export NPM_CONFIG_PREFIX="$prefix"
  fi
  case ":$PATH:" in
    *":$prefix/bin:"*) ;;
    *) export PATH="$prefix/bin:$PATH" ;;
  esac
}

echo "=== Running hexo setup ==="

if command -v node &>/dev/null && command -v npm &>/dev/null; then
  if _hexo_force && is_macos && command -v brew &>/dev/null && brew list node &>/dev/null 2>/dev/null; then
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
    # Linux/WSL: Node via packages step (apt/dnf) — no sudo here.
    if ! command -v node &>/dev/null; then
      echo "  WARN: Node.js not found; run: ./bootstrap.sh --tools packages --yes"
      echo "        (hexo tool does not invoke sudo on Linux/WSL)"
      echo "=== Hexo done (skipped) ==="
      exit 0
    fi
  fi
fi

if ! command -v npm &>/dev/null; then
  echo "  WARN: npm not found; skip hexo-cli"
  echo "=== Hexo done (skipped) ==="
  exit 0
fi

ensure_npm_user_prefix || {
  echo "  WARN: could not prepare npm user prefix"
  echo "=== Hexo done (skipped) ==="
  exit 0
}

if command -v hexo &>/dev/null; then
  if _hexo_force; then
    echo "Reinstalling hexo-cli (npm, --force)..."
    npm install -g hexo-cli || echo "  WARN: npm reinstall hexo-cli failed"
  else
    echo "hexo-cli already installed (use --force to reinstall)"
  fi
else
  echo "Installing hexo-cli (npm install -g hexo-cli → ~/.npm-global)..."
  npm install -g hexo-cli || echo "  WARN: npm install -g hexo-cli failed; run manually if needed"
fi

echo "=== Hexo done ==="
