[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
: "${MY_UTILS_ROOT:=$HOME/repos/my-utils}"
: "${MYRC_PATH:=$MY_UTILS_ROOT/config}"
export MY_CONF_PATH="$MYRC_PATH"
export TVM_HOME=$HOME/repos/tvm_before_seqstmt
source "$MY_CONF_PATH/tvm.bash"
