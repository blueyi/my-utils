# git-dual-remote.bash — interactive git() wrapper (bash/zsh).
# Sourced from resetrc.bash when GIT_DUAL_REMOTE_ENABLED=1.

[ -f "${MYRC_PATH:-}/git-dual-remote.env" ] && . "${MYRC_PATH}/git-dual-remote.env"
[ -f "${MY_UTILS_ROOT:-}/config/git-dual-remote.env" ] && . "${MY_UTILS_ROOT}/config/git-dual-remote.env"

_lib="${MY_UTILS_ROOT:-}/common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || _lib="${MYRC_PATH:-}/../common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || return 0

# shellcheck source=/dev/null
. "$_lib"
unset _lib

git_dual_remote_enabled || return 0

# Optional global git timeouts (idempotent include.path).
_git_dual_maybe_global_config() {
  local frag="${MY_UTILS_ROOT:-}/config/gitconfig.dual-remote"
  [[ -f "$frag" ]] || return 0
  local cur
  cur="$(command git config --global --get-all include.path 2>/dev/null || true)"
  printf '%s\n' "$cur" | grep -Fxq "$frag" && return 0
  command git config --global --add include.path "$frag" 2>/dev/null || true
}
_git_dual_maybe_global_config
unset -f _git_dual_maybe_global_config 2>/dev/null || true

git() {
  if ! git_dual_remote_enabled; then
    command git "$@"
    return $?
  fi

  case "${1:-}" in
    push)
      shift
      git_dual_push "$@"
      ;;
    pull)
      shift
      git_dual_pull "$@"
      ;;
    fetch)
      shift
      git_dual_fetch "$@"
      ;;
    clone)
      shift
      git_dual_clone "$@"
      ;;
    *)
      command git "$@"
      ;;
  esac
}

# Convenience aliases (optional shortcuts).
alias gdr-setup='bash "${MY_UTILS_ROOT:-}/common/git-dual-remote-setup.sh"'
alias gdr-scan='bash "${MY_UTILS_ROOT:-}/common/git-dual-remote-setup.sh" --scan'
