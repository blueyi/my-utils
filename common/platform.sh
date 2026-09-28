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

# Privilege gates (set in ~/.env.rc; survive create_links.sh):
#   MY_UTILS_ALLOW_SUDO=off  — skip apt/yum/dnf sudo paths (macOS brew unaffected)
#   MY_UTILS_CHSH=1          — allow misc.sh to change login shell to zsh
my_utils_sudo_allowed() {
  case "${MY_UTILS_ALLOW_SUDO:-on}" in
    off|OFF|0|false|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

# Run sudo "$@" when allowed; otherwise warn and return 1 (bash/zsh safe).
my_utils_sudo() {
  if ! my_utils_sudo_allowed; then
    echo "  SKIP sudo ($*): set MY_UTILS_ALLOW_SUDO=on (default) to allow" >&2
    return 1
  fi
  command sudo "$@"
}
