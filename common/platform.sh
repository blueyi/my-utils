#!/usr/bin/env bash
# Platform detection for my-utils (Linux/macOS)
# Source this file or call functions directly

detect_os() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    *)        echo "unknown" ;;
  esac
}

detect_package_manager() {
  case "$(detect_os)" in
    macos)  echo "brew" ;;
    linux)
      if [ -f /etc/debian_version ] || [ -f /etc/apt/sources.list ]; then
        echo "apt"
      elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ]; then
        echo "yum"
      else
        echo "unknown"
      fi
      ;;
    *)      echo "unknown" ;;
  esac
}

is_linux() { [ "$(detect_os)" = "linux" ]; }
is_macos() { [ "$(detect_os)" = "macos" ]; }

# WSL1/WSL2: Ubuntu packages rarely ship linux-headers matching Microsoft kernel (uname -r).
is_wsl() {
  [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
  [ -n "${WSL_INTEROP:-}" ] && return 0
  grep -qi microsoft /proc/version 2>/dev/null && return 0
  return 1
}
