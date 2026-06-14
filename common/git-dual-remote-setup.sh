#!/usr/bin/env bash
# Configure GitHub + GitCode dual remotes for one repo or many under a directory.
#
# Usage:
#   git-dual-remote-setup.sh                  # current repo
#   git-dual-remote-setup.sh /path/to/repo
#   git-dual-remote-setup.sh --scan ~/workspace/repos
#   git-dual-remote-setup.sh --global-git-config
#
# Requires: config/git-dual-remote.env (or ~/.my-utils.env overrides)

set -euo pipefail

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_root="$(cd "$_script_dir/.." && pwd)"

[ -f "$HOME/.my-utils.env" ] && . "$HOME/.my-utils.env"
[ -f "$_root/config/git-dual-remote.env" ] && . "$_root/config/git-dual-remote.env"
# shellcheck source=git-dual-remote-lib.sh
. "$_script_dir/git-dual-remote-lib.sh"

usage() {
  cat <<'EOF'
Usage: git-dual-remote-setup.sh [options] [path]

Options:
  --scan DIR          Configure every git repo under DIR (max depth 4)
  --global-git-config Install include.path for config/gitconfig.dual-remote
  --dry-run           Print actions without changing remotes
  -h, --help          Show this help

With no path: configure the current directory's repo (origin + gitcode remote).
EOF
}

_scan_root=""
_dry_run=0
_install_global=0
_target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scan) _scan_root="$2"; shift 2 ;;
    --global-git-config) _install_global=1; shift ;;
    --dry-run) _dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *) _target="$1"; shift ;;
  esac
done

_setup_one_repo() {
  local dir="$1"
  [[ -d "$dir/.git" ]] || return 0
  if (( _dry_run )); then
    local url
    url="$(git -C "$dir" remote get-url origin 2>/dev/null || echo '?')"
    echo "[dry-run] would configure: $dir (origin=$url)"
    return 0
  fi
  if ( cd "$dir" && git_dual_ensure_remotes origin 2>/dev/null ); then
    echo "OK: $dir"
    git -C "$dir" remote -v | sed 's/^/  /'
  else
    echo "SKIP: $dir (not under mirrored namespace ${GIT_DUAL_REMOTE_GITHUB_USER:-blueyi}, or not GitHub/GitCode)"
  fi
}

_install_global_git_config() {
  local frag="$_root/config/gitconfig.dual-remote"
  [[ -f "$frag" ]] || { echo "Missing $frag" >&2; return 1; }
  if (( _dry_run )); then
    echo "[dry-run] git config --global include.path $frag"
    return 0
  fi
  local cur
  cur="$(git config --global --get-all include.path 2>/dev/null || true)"
  if printf '%s\n' "$cur" | grep -Fxq "$frag"; then
    echo "include.path already set: $frag"
  else
    git config --global --add include.path "$frag"
    echo "Added global include.path → $frag"
  fi
}

if (( _install_global )); then
  _install_global_git_config
fi

if [[ -n "$_scan_root" ]]; then
  [[ -d "$_scan_root" ]] || { echo "Not a directory: $_scan_root" >&2; exit 1; }
  echo "Scanning git repos under $_scan_root ..."
  while IFS= read -r -d '' gitdir; do
    _setup_one_repo "$(dirname "$gitdir")"
  done < <(find "$_scan_root" -maxdepth 4 -type d -name .git -print0 2>/dev/null)
  exit 0
fi

if [[ -n "$_target" ]]; then
  [[ -d "$_target" ]] || { echo "Not a directory: $_target" >&2; exit 1; }
  ( cd "$_target" && _setup_one_repo "$_target" )
  exit 0
fi

_setup_one_repo "$(pwd)"
