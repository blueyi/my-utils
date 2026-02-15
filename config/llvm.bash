# for llvm
export LLVM_PATH=$HOME/repos/llvm-project
# export LLVM_BIN_PATH=$LLVM_PATH/build/bin
# export PATH=$LLVM_PATH_BIN:$PATH
alias cllvm='cd ${LLVM_PATH}'

: "${MYRC_PATH:=$HOME/repos/my-utils/config}"
source "$MYRC_PATH/resetrc.bash"
