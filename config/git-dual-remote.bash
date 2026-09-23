# git-dual-remote.bash — dual-remote helpers for interactive shells.
# Sourced from resetrc.bash.
#
# Default: native `git` (GIT_DUAL_REMOTE_ENABLED=0).
# Dual-remote: use `gdr` (common/gdr on PATH), or set GIT_DUAL_REMOTE_ENABLED=1
# to wrap push/pull/fetch/clone again.

[ -f "${MYRC_PATH:-}/git-dual-remote.env" ] && . "${MYRC_PATH}/git-dual-remote.env"
[ -f "${MY_UTILS_ROOT:-}/config/git-dual-remote.env" ] && . "${MY_UTILS_ROOT}/config/git-dual-remote.env"

_lib="${MY_UTILS_ROOT:-}/common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || _lib="${MYRC_PATH:-}/../common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || return 0

# shellcheck source=/dev/null
. "$_lib"
unset _lib

# Optional global git timeouts — only when dual-remote wrapper is enabled.
_git_dual_maybe_global_config() {
  local frag="${MY_UTILS_ROOT:-}/config/gitconfig.dual-remote"
  [[ -f "$frag" ]] || return 0
  local cur
  cur="$(command git config --global --get-all include.path 2>/dev/null || true)"
  printf '%s\n' "$cur" | grep -Fxq "$frag" && return 0
  command git config --global --add include.path "$frag" 2>/dev/null || true
}

# Shell function fallback if common/ is not yet on PATH in this shell.
gdr() {
  local _gdr="${MY_UTILS_ROOT:-}/common/gdr"
  if [[ -x "$_gdr" ]]; then
    "$_gdr" "$@"
    return $?
  fi
  echo "gdr: missing executable $_gdr" >&2
  return 127
}

# Convenience aliases for setup/scan (also: gdr setup / gdr scan).
alias gdr-setup='bash "${MY_UTILS_ROOT:-}/common/git-dual-remote-setup.sh"'
alias gdr-scan='bash "${MY_UTILS_ROOT:-}/common/git-dual-remote-setup.sh" --scan'

# Opt-in: wrap git push/pull/fetch/clone with dual-remote behavior.
if git_dual_remote_enabled; then
  _git_dual_maybe_global_config

  git() {
    if ! git_dual_remote_enabled; then
      command git "$@"
      return $?
    fi

    case "${1:-}" in
      push)
        shift
        git_dual_push "$@"
        return $?
        ;;
      pull)
        shift
        git_dual_pull "$@"
        return $?
        ;;
      fetch)
        shift
        git_dual_fetch "$@"
        return $?
        ;;
      clone)
        shift
        git_dual_clone "$@"
        return $?
        ;;
      *)
        command git "$@"
        return $?
        ;;
    esac
  }
fi

unset -f _git_dual_maybe_global_config 2>/dev/null || true
