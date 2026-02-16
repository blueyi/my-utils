[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${MYRC_PATH:=$MY_UTILS_ROOT/config}"
export MY_CONF_PATH="$MYRC_PATH"
export TVM_HOME=$HOME/repos/tvm_before_seqstmt
source "$MY_CONF_PATH/tvm.bash"
