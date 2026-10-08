#!/usr/bin/env bash
# Run misc setup (git, oh-my-zsh, uv)
# Zero Python dependency

set -e
# Use MY_UTILS_ROOT from bootstrap when set; else resolve from script location
if [ -n "${MY_UTILS_ROOT:-}" ]; then
  COMMON_DIR="$MY_UTILS_ROOT/common"
else
  COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ ! -f "$COMMON_DIR/misc.sh" ]; then
  echo "misc.sh not found"
  exit 1
fi

echo "=== Running misc setup ==="
# shellcheck source=/dev/null
source "$COMMON_DIR/misc.sh"
# misc.sh returns/exits non-zero when MY_UTILS_MISC_FAILS > 0
echo "=== Misc done ==="
