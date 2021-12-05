source $HOME/repos/my-utils/config/resetrc.bash
export PYTHONPATH=$TVM_HOME/python:$TVM_HOME/topi/python:${PYTHONPATH}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TVM_HOME/build
export LIBRARY_PATH=$LD_LIBRARY_PATH
export TVM_LOG_DEBUG="ir/transform.cc=1;relay/ir/transform.cc=1"

alias ctv='cd ${TVM_HOME}'
