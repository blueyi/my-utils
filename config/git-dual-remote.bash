# git-dual-remote.bash — dual-remote helpers for interactive shells.
# Sourced from resetrc.bash.
#
# Native `git` is never wrapped. Dual-remote ops go through `gdr` only
# (common/gdr on PATH, or the gdr() function below).

[ -f "${MYRC_PATH:-}/git-dual-remote.env" ] && . "${MYRC_PATH}/git-dual-remote.env"
[ -f "${MY_UTILS_ROOT:-}/config/git-dual-remote.env" ] && . "${MY_UTILS_ROOT}/config/git-dual-remote.env"

_lib="${MY_UTILS_ROOT:-}/common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || _lib="${MYRC_PATH:-}/../common/git-dual-remote-lib.sh"
[ -f "$_lib" ] || return 0

# shellcheck source=/dev/null
. "$_lib"
unset _lib

# Drop any leftover git() wrapper from an older session / inherited rc.
unalias git 2>/dev/null || true
unset -f git 2>/dev/null || true

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
