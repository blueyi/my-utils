#!/usr/bin/env bash
# Run misc setup (git, oh-my-zsh, pyenv)
# Zero Python dependency

set -e
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$COMMON_DIR/misc.sh" ]; then
  echo "misc.sh not found"
  exit 1
fi

echo "=== Running misc setup ==="
source "$COMMON_DIR/misc.sh"
echo "=== Misc done ==="
