#!/usr/bin/env bash
# Source resetrc.bash + optional_home in bash; emit Fish set -gx lines.
# Optional: symlink as ~/.my-utils.emit-fish-env.bash after uncommenting link.ini + installing fish.
set +u
[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MYRC_PATH:-}" ] && [ -n "${MY_UTILS_ROOT:-}" ] && MYRC_PATH="${MY_UTILS_ROOT}/config"
if [ -z "${MYRC_PATH:-}" ] || [ ! -f "${MYRC_PATH}/resetrc.bash" ]; then
  exit 0
fi
# shellcheck source=resetrc.bash
source "${MYRC_PATH}/resetrc.bash"
[ -f "${MYRC_PATH}/optional_home.bash" ] && source "${MYRC_PATH}/optional_home.bash"

fish_escape_value() {
  local s=$1 i c out="'"
  local len=${#s}
  for ((i = 0; i < len; i++)); do
    c=${s:i:1}
    if [[ "$c" == "'" ]]; then
      out+="'\''"
    else
      out+="$c"
    fi
  done
  out+="'"
  printf '%s' "$out"
}

while IFS= read -r name; do
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
  case "$name" in
    PWD | OLDPWD | _ | SHLVL | OPTIND | PS1 | PS2 | PS3 | PS4 | FUNCNAME | GROUPS) continue ;;
  esac
  [[ "$name" == BASH_* ]] && continue
  dec=$(declare -p "$name" 2>/dev/null) || continue
  [[ "$dec" == declare\ -a* ]] || [[ "$dec" == declare\ -A* ]] && continue
  # exported: flags contain x (e.g. -x, -rx)
  [[ "$dec" =~ ^declare\ -[a-zA-Z0-9]*x[a-zA-Z0-9]*[[:space:]] ]] || continue
  val="${!name}"
  [[ "$val" == *$'\n'* ]] && continue
  printf 'set -gx %s %s\n' "$name" "$(fish_escape_value "$val")"
done < <(compgen -e)
