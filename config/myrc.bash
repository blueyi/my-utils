[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
: "${MY_UTILS_ROOT:=$HOME/repos/my-utils}"
export MY_CONF_PATH="${MY_UTILS_ROOT}/config"
# export TVM_HOME=$HOME/repos/tvm
# source $MY_CONF_PATH/tvm.bash

source $MY_CONF_PATH/llvm.bash
# source $MY_CONF_PATH/dl.bash
