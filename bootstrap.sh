#!/usr/bin/env bash
# My-Utils Bootstrap - One-click dev environment setup
# Zero Python dependency. Supports Linux + macOS.
#
# Usage:
#   ./bootstrap.sh              # Interactive
#   ./bootstrap.sh --yes       # Unattended, all tools
#   ./bootstrap.sh --tools packages links vimrc --yes

set -e
MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON="$MY_UTILS_ROOT/common"
export MY_UTILS_ROOT

YES_MODE=false
SELECTED_TOOLS=()

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --yes|-y)
      YES_MODE=true
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
      echo "Unknown option: $1"
      echo "Usage: $0 [--yes] [--tools packages links misc vimrc]"
      exit 1
      ;;
  esac
done

ALL_TOOLS=(packages links misc vimrc)

# If no tools specified, use all
if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
  SELECTED_TOOLS=("${ALL_TOOLS[@]}")
fi

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

echo "=== My-Utils Bootstrap ==="
echo "Root: $MY_UTILS_ROOT"
echo "Tools: ${SELECTED_TOOLS[*]}"
echo ""

for tool in "${SELECTED_TOOLS[@]}"; do
  if confirm "Run $tool?"; then
    run_tool "$tool"
  else
    echo "  Skip $tool"
  fi
done

echo ""
echo "=== Bootstrap complete ==="
echo "Reload shell: exec \$SHELL"
