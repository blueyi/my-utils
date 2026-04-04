# Section: repo common bin + user layout paths (before PATH prepend)
MY_BIN=${MY_UTILS_ROOT}/common
HOME_BIN=$HOME/bin
export LOCAL_BIN_PATH=$HOME/.local/bin

[ -d "$HOME/bin/cmake/bin" ] && export CMAKE_PATH=$HOME/bin/cmake/bin || CMAKE_PATH=""
