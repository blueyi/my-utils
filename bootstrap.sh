#!/usr/bin/env bash
# My-Utils Bootstrap - One-click dev environment setup
# Supports Linux + macOS.
#
# Usage:
#   ./bootstrap.sh --help
#   ./bootstrap.sh --yes
#   ./bootstrap.sh --new-mac --yes
#   ./bootstrap.sh --force --yes
#   ./bootstrap.sh --tools packages --optional --yes
#   ./bootstrap.sh --tools env --yes

set -e
MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export MY_UTILS_ROOT
COMMON="$MY_UTILS_ROOT/common"

YES_MODE=false
FORCE_MODE=false
NEW_MAC=false
OPTIONAL_BREW=false
SELECTED_TOOLS=()

STAMP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/my-utils/bootstrap"

# Summary buckets (space-separated names)
SUMMARY_RAN=""
SUMMARY_SKIP_STAMP=""
SUMMARY_SKIP_DECLINE=""
SUMMARY_FAIL=""

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
  --optional              Also install common/Brewfile.optional (with packages)
  --tools T [T ...]       Run only these tools (default: all except env)
                          packages | links | misc | vimrc | cursor | env

Tools:
  packages   Install system packages (apt/yum, or macOS Brewfile / brew)
  links      Symlink configs from link.ini into \$HOME
  misc       Oh My Zsh, fzf, uv, rustup default, brew login PATH, …
  vimrc      Vim plugins (vim-plug)
  cursor     Cursor config backup / symlink into cursor_bak/
  env        Optional env.rc decrypt hint (needs SYNC_ENV_KEY; not in default set)

Idempotency (two layers):
  1) Per-tool stamps under \$XDG_STATE_HOME/my-utils/bootstrap/
     packages re-runs when Brewfile (+ optional) hash changes
     links re-runs when common/link.ini hash changes
  2) Per-package: already-installed skipped unless --force

Examples:
  $0 --help
  $0 --new-mac --yes
  $0 --tools packages --optional --yes
  $0 --tools env --yes
  $0 --force --yes
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h) usage; exit 0 ;;
    --yes|-y) YES_MODE=true; shift ;;
    --force|-f) FORCE_MODE=true; shift ;;
    --new-mac) NEW_MAC=true; shift ;;
    --optional) OPTIONAL_BREW=true; shift ;;
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

# Default one-shot: everything except optional env decrypt
ALL_TOOLS=(packages links misc vimrc cursor)

if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
  SELECTED_TOOLS=("${ALL_TOOLS[@]}")
fi

if [ "$FORCE_MODE" = true ]; then
  export MY_UTILS_FORCE=1
else
  unset MY_UTILS_FORCE 2>/dev/null || true
fi

if [ "$OPTIONAL_BREW" = true ]; then
  export MY_UTILS_BREW_OPTIONAL=1
else
  unset MY_UTILS_BREW_OPTIONAL 2>/dev/null || true
fi

file_sha256() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "none"
    return 0
  fi
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$f" | awk '{print $1}'
  else
    cksum "$f" | awk '{print $1"-"$2}'
  fi
}

stamp_path() {
  echo "$STAMP_DIR/$1.done"
}

packages_manifest_hash() {
  local h opt
  h="$(file_sha256 "$COMMON/Brewfile")"
  if [ "${MY_UTILS_BREW_OPTIONAL:-}" = "1" ] || [ "${MY_UTILS_BREW_OPTIONAL:-}" = "true" ]; then
    opt="$(file_sha256 "$COMMON/Brewfile.optional")"
    echo "${h}+optional:${opt}"
  else
    echo "$h"
  fi
}

links_manifest_hash() {
  file_sha256 "$COMMON/link.ini"
}

tool_stamp_valid() {
  local name="$1"
  local stamp want have
  stamp="$(stamp_path "$name")"
  [ -f "$stamp" ] || return 1
  case "$name" in
    packages)
      want="$(packages_manifest_hash)"
      have="$(grep -E '^brewfile_sha256=' "$stamp" 2>/dev/null | head -1 | cut -d= -f2-)"
      [ -n "$have" ] && [ "$have" = "$want" ]
      return $?
      ;;
    links)
      want="$(links_manifest_hash)"
      have="$(grep -E '^link_ini_sha256=' "$stamp" 2>/dev/null | head -1 | cut -d= -f2-)"
      [ -n "$have" ] && [ "$have" = "$want" ]
      return $?
      ;;
    *)
      return 0
      ;;
  esac
}

write_tool_stamp() {
  local name="$1"
  mkdir -p "$STAMP_DIR"
  {
    echo "ts=$(date +%Y-%m-%dT%H:%M:%S%z)"
    case "$name" in
      packages) echo "brewfile_sha256=$(packages_manifest_hash)" ;;
      links)    echo "link_ini_sha256=$(links_manifest_hash)" ;;
    esac
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
    packages) "$COMMON/install_packages.sh" ;;
    links)    "$COMMON/create_links.sh" ;;
    misc)     "$COMMON/run_misc.sh" ;;
    vimrc)    "$COMMON/install_vim_plugins.sh" ;;
    cursor)   "$COMMON/cursor_config_link.sh" ;;
    env)      "$COMMON/run_env_sync.sh" ;;
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

summary_add() {
  local bucket="$1" item="$2"
  case "$bucket" in
    ran) SUMMARY_RAN="$SUMMARY_RAN $item" ;;
    stamp) SUMMARY_SKIP_STAMP="$SUMMARY_SKIP_STAMP $item" ;;
    decline) SUMMARY_SKIP_DECLINE="$SUMMARY_SKIP_DECLINE $item" ;;
    fail) SUMMARY_FAIL="$SUMMARY_FAIL $item" ;;
  esac
}

print_summary() {
  echo ""
  echo "=== Bootstrap summary ==="
  echo "  Ran:              ${SUMMARY_RAN:- (none)}"
  echo "  Skipped (stamp):  ${SUMMARY_SKIP_STAMP:- (none)}"
  echo "  Skipped (decline):${SUMMARY_SKIP_DECLINE:- (none)}"
  echo "  Failed:           ${SUMMARY_FAIL:- (none)}"
  if [ -n "${SUMMARY_FAIL// }" ]; then
    echo "  Tip: re-run failed tools, e.g. ./bootstrap.sh --tools${SUMMARY_FAIL} --yes"
  fi
  case "$(uname -s)" in
    Darwin*)
      echo "  Optional apps: ./bootstrap.sh --tools packages --optional --yes"
      echo "             or: brew bundle --file=$COMMON/Brewfile.optional"
      ;;
  esac
  echo "  Optional secrets: export SYNC_ENV_KEY=… then ./bootstrap.sh --tools env --yes"
  echo "  Reload shell:     exec \$SHELL"
}

if [ "$NEW_MAC" = true ]; then
  ensure_macos_new_mac
fi

echo "=== My-Utils Bootstrap ==="
echo "Root: $MY_UTILS_ROOT"
echo "Tools: ${SELECTED_TOOLS[*]}"
[ "$FORCE_MODE" = true ] && echo "Mode: force (ignore stamps; reinstall/re-link)"
[ "$NEW_MAC" = true ] && echo "Mode: new-mac"
[ "$OPTIONAL_BREW" = true ] && echo "Mode: optional Brewfile"
echo "Stamps: $STAMP_DIR"
echo ""

for tool in "${SELECTED_TOOLS[@]}"; do
  if ! confirm "Run $tool?"; then
    echo "  Skip $tool (declined)"
    summary_add decline "$tool"
    continue
  fi
  if [ "$FORCE_MODE" != true ] && tool_stamp_valid "$tool"; then
    echo "  Skip $tool (already done; use --force to re-run)"
    summary_add stamp "$tool"
    continue
  fi
  if run_tool "$tool"; then
    write_tool_stamp "$tool"
    summary_add ran "$tool"
  else
    echo "  WARN: $tool failed; stamp not written (will retry on next run)"
    summary_add fail "$tool"
  fi
done

print_summary
echo ""
echo "=== Bootstrap complete ==="
