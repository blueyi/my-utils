[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MY_CONF_PATH="${MY_UTILS_ROOT}/config"
source "$MY_CONF_PATH/resetrc.bash"
