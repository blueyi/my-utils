#!/usr/bin/env bash
# My-Utils Bootstrap - One-click dev environment setup
# Supports Linux + macOS.
#
# Usage:
#   ./bootstrap.sh              # Interactive: ask which of (packages, links, misc, vimrc, cursor) to run
#   ./bootstrap.sh --yes        # Unattended: run all (packages, links, misc, vimrc, cursor) with no prompts
#   ./bootstrap.sh --tools packages links --yes   # Unattended, only selected tools

set -e
# Canonical project root; all child scripts (create_links, install_packages, etc.) use this when set
MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export MY_UTILS_ROOT
COMMON="$MY_UTILS_ROOT/common"

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
      echo "Usage: $0 [--yes] [--tools packages links misc vimrc cursor]"
      echo "  --yes: run all selected tools without prompting"
      echo "  --tools: run only these (default: all)"
      echo "  packages=install pkgs, links=symlinks, misc=oh-my-zsh/pyenv, vimrc=vim plugins, cursor=config backup"
      exit 1
      ;;
  esac
done

ALL_TOOLS=(packages links misc vimrc cursor)

# If no tools specified, use all (--yes without --tools => one-shot init: packages, links, misc, vimrc, cursor)
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
