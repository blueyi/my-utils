[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MY_CONF_PATH="${MY_UTILS_ROOT}/config"
[ -f "$MY_CONF_PATH/path.bash" ] && . "$MY_CONF_PATH/path.bash"
# export TVM_HOME=$HOME/repos/tvm
# source $MY_CONF_PATH/tvm.bash

source "$MY_CONF_PATH/llvm.bash"
# C++ / CMake: default load for C++ dev (PATH, CC, CXX, CMAKE_MAKE_PROGRAM)
[ -f "$MY_CONF_PATH/cmake_env.bash" ] && . "$MY_CONF_PATH/cmake_env.bash"
