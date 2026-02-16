[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
[ -f "$MYRC_PATH/resetrc.bash" ] && source "$MYRC_PATH/resetrc.bash"
export PYTHONPATH=$TVM_HOME/python:$TVM_HOME/topi/python:${PYTHONPATH}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TVM_HOME/build
export LIBRARY_PATH=$LD_LIBRARY_PATH
export TVM_LOG_DEBUG="ir/transform.cc=1;relay/ir/transform.cc=1"

export PATH=$PATH:$LLVM_PATH

alias ctv='cd ${TVM_HOME}'
