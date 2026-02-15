# Base profile - PATH, pyenv, nvm, etc
# Source: source $MY_UTILS_ROOT/profiles/base/env.bash
[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "$MY_UTILS_ROOT" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
source "$MYRC_PATH/resetrc.bash"
