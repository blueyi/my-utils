#!/usr/bin/env bash
# My-Utils Bootstrap - One-click dev environment setup
# Supports Linux + macOS.
#
# Usage:
#   ./bootstrap.sh --help
#   ./bootstrap.sh --yes
#   ./bootstrap.sh --new-mac --yes
#   ./bootstrap.sh --force --yes
#   ./bootstrap.sh --tools packages links --yes

set -e
# Canonical project root; all child scripts (create_links, install_packages, etc.) use this when set
MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export MY_UTILS_ROOT
COMMON="$MY_UTILS_ROOT/common"

YES_MODE=false
FORCE_MODE=false
NEW_MAC=false
SELECTED_TOOLS=()

STAMP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/my-utils/bootstrap"

usage() {
  cat <<EOF
My-Utils Bootstrap — one-click dev environment setup (Linux + macOS)

Usage:
  $0 [options]

Options:
  -h, --help              Show this help and exit
  -y, --yes               Run selected tools without prompting
  -f, --force             Ignore tool stamps; reinstall packages / re-link configs
  --new-mac               macOS-only init helper (CLT check + App Store hint)
  --tools T [T ...]       Run only these tools (default: all)
                          packages | links | misc | vimrc | cursor

Tools:
  packages   Install system packages (apt/yum, or macOS Brewfile / brew)
  links      Symlink configs from link.ini into \$HOME
  misc       Oh My Zsh, fzf, uv, git identity, etc.
  vimrc      Vim plugins (vim-plug)
  cursor     Cursor config backup / symlink into cursor_bak/

Idempotency (two layers):
  1) Per-tool stamps under:
       \$XDG_STATE_HOME/my-utils/bootstrap/  (default: ~/.local/state/...)
     Successful tools are skipped on later runs unless --force.
     packages also re-runs when common/Brewfile content changes.
  2) Per-package: already-installed packages are skipped unless --force
     (then apt/yum/brew reinstall).

Examples:
  $0 --help
  $0 --yes
  $0 --new-mac --yes
  $0 --tools packages links --yes
  $0 --force --yes
  $0 --tools packages --force --yes
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      usage
      exit 0
      ;;
    --yes|-y)
      YES_MODE=true
      shift
      ;;
    --force|-f)
      FORCE_MODE=true
      shift
      ;;
    --new-mac)
      NEW_MAC=true
      shift
      ;;
    --tools)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        SELECTED_TOOLS+=("$1")
        shift
      done
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "" >&2
      usage >&2
      exit 1
      ;;
  esac
done

ALL_TOOLS=(packages links misc vimrc cursor)

# If no tools specified, use all (--yes without --tools => one-shot init)
if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
  SELECTED_TOOLS=("${ALL_TOOLS[@]}")
fi

if [ "$FORCE_MODE" = true ]; then
  export MY_UTILS_FORCE=1
else
  unset MY_UTILS_FORCE 2>/dev/null || true
fi

file_sha256() {
  local f="$1"
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$f" | awk '{print $1}'
  else
    # Portable weak fallback
    cksum "$f" | awk '{print $1"-"$2}'
  fi
}

stamp_path() {
  echo "$STAMP_DIR/$1.done"
}

packages_brewfile_hash() {
  local bf="$COMMON/Brewfile"
  if [ -f "$bf" ]; then
    file_sha256 "$bf"
  else
    echo "none"
  fi
}

tool_stamp_valid() {
  local name="$1"
  local stamp
  stamp="$(stamp_path "$name")"
  [ -f "$stamp" ] || return 1
  if [ "$name" = "packages" ]; then
    local want have
    want="$(packages_brewfile_hash)"
    have="$(grep -E '^brewfile_sha256=' "$stamp" 2>/dev/null | head -1 | cut -d= -f2-)"
    [ -n "$have" ] && [ "$have" = "$want" ]
    return $?
  fi
  return 0
}

write_tool_stamp() {
  local name="$1"
  mkdir -p "$STAMP_DIR"
  {
    echo "ts=$(date +%Y-%m-%dT%H:%M:%S%z)"
    if [ "$name" = "packages" ]; then
      echo "brewfile_sha256=$(packages_brewfile_hash)"
    fi
  } > "$(stamp_path "$name")"
}

ensure_macos_new_mac() {
  case "$(uname -s)" in
    Darwin*) ;;
    *)
      echo "ERROR: --new-mac is only supported on macOS (Darwin)." >&2
      exit 1
      ;;
  esac
  echo "New Mac prerequisites:"
  echo "  - Sign in to the Mac App Store (required for Brewfile mas entries)"
  echo "  - Network access for Homebrew / git clones"
  if ! xcode-select -p &>/dev/null; then
    echo "  - Xcode Command Line Tools: not found"
    echo "    Run: xcode-select --install"
    echo "    Then re-run this bootstrap after the installer finishes."
    exit 1
  fi
  echo "  - Xcode Command Line Tools: OK ($(xcode-select -p))"
  echo ""
}

run_tool() {
  local name="$1"
  case "$name" in
    packages)
      "$COMMON/install_packages.sh"
      ;;
    links)
      "$COMMON/create_links.sh"
      ;;
    misc)
      "$COMMON/run_misc.sh"
      ;;
    vimrc)
      "$COMMON/install_vim_plugins.sh"
      ;;
    cursor)
      "$COMMON/cursor_config_link.sh"
      ;;
    *)
      echo "Unknown tool: $name"
      return 1
      ;;
  esac
}

confirm() {
  if [ "$YES_MODE" = true ]; then
    return 0
  fi
  echo -n "$1 [y/N] "
  read -r r
  [[ "$r" =~ ^[yY] ]]
}

if [ "$NEW_MAC" = true ]; then
  ensure_macos_new_mac
fi

echo "=== My-Utils Bootstrap ==="
echo "Root: $MY_UTILS_ROOT"
echo "Tools: ${SELECTED_TOOLS[*]}"
[ "$FORCE_MODE" = true ] && echo "Mode: force (ignore stamps; reinstall/re-link)"
[ "$NEW_MAC" = true ] && echo "Mode: new-mac"
echo "Stamps: $STAMP_DIR"
echo ""

for tool in "${SELECTED_TOOLS[@]}"; do
  if ! confirm "Run $tool?"; then
    echo "  Skip $tool (declined)"
    continue
  fi
  if [ "$FORCE_MODE" != true ] && tool_stamp_valid "$tool"; then
    echo "  Skip $tool (already done; use --force to re-run)"
    continue
  fi
  if run_tool "$tool"; then
    write_tool_stamp "$tool"
  else
    echo "  WARN: $tool failed; stamp not written (will retry on next run)"
  fi
done

echo ""
echo "=== Bootstrap complete ==="
echo "Reload shell: exec \$SHELL"
