#!/usr/bin/env bash
# Cross-platform package installation (apt/brew/yum)
# Zero Python dependency
#
# Respects MY_UTILS_FORCE=1 from bootstrap --force:
#   already-installed packages are reinstalled instead of skipped.

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

force_mode() {
  [ "${MY_UTILS_FORCE:-}" = "1" ] || [ "${MY_UTILS_FORCE:-}" = "true" ]
}

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
force_mode && echo "  (force: reinstall already-installed packages)"

pkg_installed() {
  local pkg="$1"
  case "$PM" in
    apt)  dpkg -s "$pkg" &>/dev/null ;;
    yum)  rpm -q "$pkg" &>/dev/null ;;
    brew) brew list "$pkg" &>/dev/null 2>/dev/null || brew list --cask "$pkg" &>/dev/null 2>/dev/null ;;
    *)    return 1 ;;
  esac
}

install_one() {
  local pkg="$1"
  case "$PM" in
    apt)
      if pkg_installed "$pkg"; then
        if force_mode; then
          echo "  Reinstalling $pkg..."
          sudo apt-get install --reinstall -y "$pkg" || echo "  WARN: $pkg reinstall failed, continuing..."
        else
          echo "  $pkg (already installed; use --force to reinstall)"
        fi
      else
        echo "  Installing $pkg..."
        sudo apt-get install -y "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
    yum)
      if pkg_installed "$pkg"; then
        if force_mode; then
          echo "  Reinstalling $pkg..."
          if command -v dnf &>/dev/null; then
            sudo dnf reinstall -y "$pkg" || echo "  WARN: $pkg reinstall failed, continuing..."
          else
            sudo yum reinstall -y "$pkg" || echo "  WARN: $pkg reinstall failed, continuing..."
          fi
        else
          echo "  $pkg (already installed; use --force to reinstall)"
        fi
      else
        echo "  Installing $pkg..."
        sudo yum install -y "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
    brew)
      if pkg_installed "$pkg"; then
        if force_mode; then
          echo "  Reinstalling $pkg..."
          brew reinstall "$pkg" || echo "  WARN: $pkg reinstall failed, continuing..."
        else
          echo "  $pkg (already installed; use --force to reinstall)"
        fi
      else
        echo "  Installing $pkg..."
        brew install "$pkg" || echo "  WARN: $pkg install failed, continuing..."
      fi
      ;;
  esac
}

install_brew_cask() {
  local pkg="$1"
  if brew list --cask "$pkg" &>/dev/null 2>/dev/null; then
    if force_mode; then
      echo "  Reinstalling cask $pkg..."
      brew reinstall --cask "$pkg" || echo "  WARN: cask $pkg reinstall failed, continuing..."
    else
      echo "  cask $pkg (already installed; use --force to reinstall)"
    fi
  else
    echo "  Installing cask $pkg..."
    brew install --cask "$pkg" || echo "  WARN: cask $pkg install failed, continuing..."
  fi
}

brewfile_has_mas_apps() {
  local file="$1"
  grep -qE '^[[:space:]]*mas[[:space:]]+"[^"]+"[[:space:]]*,[[:space:]]*id:[[:space:]]*[0-9]+' "$file"
}

# mas CLI is required for Brewfile `mas` lines; brew bundle may leave it missing
# when network fails mid-run. Install (or repair) it explicitly.
ensure_mas_cli() {
  local file="$1"
  brewfile_has_mas_apps "$file" || return 0
  # brew may be installed but not yet on PATH in this shell
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/mas" ] && export PATH="$p:$PATH"
  done
  if command -v mas &>/dev/null; then
    return 0
  fi
  echo "  Installing mas (required for Brewfile App Store apps)..."
  if ! brew install mas; then
    echo "  ERROR: failed to install mas; App Store apps will be skipped"
    return 1
  fi
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/mas" ] && export PATH="$p:$PATH"
  done
  command -v mas &>/dev/null
}

install_mas() {
  local id="$1"
  local name="${2:-$id}"
  if ! command -v mas &>/dev/null; then
    echo "  WARN: mas not installed; skip App Store id $id ($name)"
    return 0
  fi
  if mas list 2>/dev/null | grep -qE "^${id}[[:space:]]"; then
    if force_mode; then
      echo "  Reinstalling mas $name ($id)..."
      mas install "$id" || echo "  WARN: mas install $id failed, continuing..."
    else
      echo "  mas $name ($id) (already installed; use --force to reinstall)"
    fi
  else
    echo "  Installing mas $name ($id)..."
    mas install "$id" || echo "  WARN: mas install $id failed (sign in to App Store?), continuing..."
  fi
}

# Install any Brewfile mas apps still missing (after brew bundle or as recovery).
install_mas_apps_from_brewfile() {
  local file="$1"
  local line name id
  brewfile_has_mas_apps "$file" || return 0
  if ! command -v mas &>/dev/null; then
    return 0
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\"[[:space:]]*,[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
      name="${BASH_REMATCH[1]}"
      id="${BASH_REMATCH[2]}"
      install_mas "$id" "$name"
    fi
  done < "$file"
}

# Process declarative Brewfile (brew / cask / mas lines)
# Returns 1 if Brewfile needs mas but mas CLI is still missing after recovery.
process_brewfile() {
  local file="$1"
  local line name id
  # Ensure mas is available before mas lines when force-installing piecemeal;
  # brew bundle path installs in file order instead.
  if ! force_mode; then
    echo "  brew bundle --file=$file"
    if ! brew bundle --file="$file"; then
      echo "  WARN: brew bundle reported errors; attempting mas recovery..."
    fi
    # Always ensure mas + missing App Store apps: brew bundle can report success
    # for formulae while still skipping mas lines if mas was unavailable earlier,
    # or fail entirely on network and leave mas / WeChat etc. missing.
    if ! ensure_mas_cli "$file"; then
      return 1
    fi
    # Cover brew-bundle partial failure / skipped mas lines
    install_mas_apps_from_brewfile "$file"
    if brewfile_has_mas_apps "$file" && ! command -v mas &>/dev/null; then
      return 1
    fi
    return 0
  fi
  echo "  Processing Brewfile with --force (reinstall)..."
  ensure_mas_cli "$file" || true
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    if [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
      install_one "${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
      install_brew_cask "${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\"[[:space:]]*,[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
      name="${BASH_REMATCH[1]}"
      id="${BASH_REMATCH[2]}"
      install_mas "$id" "$name"
    fi
  done < "$file"
  if brewfile_has_mas_apps "$file" && ! command -v mas &>/dev/null; then
    return 1
  fi
  return 0
}

install_from_list_file() {
  local list_file="$1"
  if [ ! -f "$list_file" ]; then
    echo "Package list not found: $list_file"
    exit 1
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    # Keep internal spaces intact (e.g. `uname -r`); only trim ends.
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    line="${line//$'\r'/}"
    [ -z "$line" ] && continue
    # Expand e.g. linux-headers-`uname -r` on Linux
    pkg=$(eval echo "$line")
    # WSL: linux-headers-$(uname -r) is not published in Ubuntu repos (Microsoft kernel)
    if [ "$PM" = apt ] && is_wsl; then
      case "$pkg" in
        linux-headers-*)
          echo "  Skip $pkg (WSL: kernel headers not in distro repos; native Linux keeps this line in deb_app_list.ini)"
          continue
          ;;
      esac
    fi
    install_one "$pkg"
  done < "$list_file"
}

case "$PM" in
  apt)
    sudo apt-get update -y 2>/dev/null || true
    install_from_list_file "$COMMON_DIR/deb_app_list.ini"
    ;;
  yum)
    sudo yum update -y 2>/dev/null || true
    install_from_list_file "$COMMON_DIR/rpm_app_list.ini"
    ;;
  brew)
    ensure_brew
    # Ensure C/C++ compilers for CMake (macOS: Xcode Command Line Tools provide clang)
    if ! command -v clang &>/dev/null; then
      echo "  Hint: Install Xcode Command Line Tools for C/C++: xcode-select --install"
    fi
    if [ -f "$COMMON_DIR/Brewfile" ]; then
      if ! process_brewfile "$COMMON_DIR/Brewfile"; then
        echo "=== Packages incomplete (mas / Brewfile recovery failed) ==="
        exit 1
      fi
    else
      install_from_list_file "$COMMON_DIR/mac_app_list.txt"
    fi
    ;;
  *)
    echo "No package list for $PM"
    exit 1
    ;;
esac

echo "=== Packages installed ==="
