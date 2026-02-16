#!/usr/bin/env bash
# Cross-platform package installation (apt/brew/yum)
# Zero Python dependency

set -e
# Use MY_UTILS_ROOT from bootstrap when set; else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

source "$COMMON_DIR/platform.sh"
OS=$(detect_os)
PM=$(detect_package_manager)

# Ensure Homebrew is installed on macOS
ensure_brew() {
  if command -v brew &>/dev/null; then
    return 0
  fi
  # Add common brew paths (Apple Silicon: /opt/homebrew, Intel: /usr/local)
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/brew" ] && export PATH="$p:$PATH" && return 0
  done
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this session (Apple Silicon default)
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [ "$OS" = "unknown" ] || [ "$PM" = "unknown" ]; then
  echo "Unsupported platform: $OS / $PM"
  exit 1
fi

echo "=== Install packages ($OS / $PM) ==="

install_one() {
  local pkg="$1"
  case "$PM" in
    apt)
      if dpkg -s "$pkg" &>/dev/null; then
        echo "  $pkg (already installed)"
      else
        echo "  Installing $pkg..."
        sudo apt-get install -y "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
    yum)
      if rpm -q "$pkg" &>/dev/null; then
        echo "  $pkg (already installed)"
      else
        echo "  Installing $pkg..."
        sudo yum install -y "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
    brew)
      if brew list "$pkg" &>/dev/null 2>/dev/null; then
        echo "  $pkg (already installed)"
      else
        echo "  Installing $pkg..."
        brew install "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
  esac
}

case "$PM" in
  apt)
    sudo apt-get update -y 2>/dev/null || true
    list_file="$COMMON_DIR/deb_app_list.ini"
    ;;
  yum)
    sudo yum update -y 2>/dev/null || true
    list_file="$COMMON_DIR/rpm_app_list.ini"
    ;;
  brew)
    ensure_brew
    # Ensure C/C++ compilers for CMake (macOS: Xcode Command Line Tools provide clang)
    if ! command -v clang &>/dev/null; then
      echo "  Hint: Install Xcode Command Line Tools for C/C++: xcode-select --install"
    fi
    list_file="$COMMON_DIR/mac_app_list.txt"
    ;;
  *)
    echo "No package list for $PM"
    exit 1
    ;;
esac

if [ ! -f "$list_file" ]; then
  echo "Package list not found: $list_file"
  exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="${line// /}"
  line="${line//$'\r'/}"
  [ -z "$line" ] && continue
  # Expand e.g. linux-headers-`uname -r` on Linux
  pkg=$(eval echo "$line")
  install_one "$pkg"
done < "$list_file"

echo "=== Packages installed ==="
