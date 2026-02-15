#!/usr/bin/env bash
# Cross-platform package installation (apt/brew/yum)
# Zero Python dependency

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$COMMON_DIR/.." && pwd)"

source "$COMMON_DIR/platform.sh"
OS=$(detect_os)
PM=$(detect_package_manager)

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
        sudo apt-get install -y "$pkg"
      fi
      ;;
    yum)
      if rpm -q "$pkg" &>/dev/null; then
        echo "  $pkg (already installed)"
      else
        echo "  Installing $pkg..."
        sudo yum install -y "$pkg"
      fi
      ;;
    brew)
      if brew list "$pkg" &>/dev/null 2>/dev/null; then
        echo "  $pkg (already installed)"
      else
        echo "  Installing $pkg..."
        brew install "$pkg"
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
  [ -z "$line" ] && continue
  # Expand e.g. linux-headers-`uname -r` on Linux
  pkg=$(eval echo "$line")
  install_one "$pkg"
done < "$list_file"

echo "=== Packages installed ==="
