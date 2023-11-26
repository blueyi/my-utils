source $HOME/repos/my-utils/config/resetrc.bash

# for llvm
export LLVM_PATH=$HOME/repos/llvm-project
export LLVM_PATH_BIN=$LLVM_PATH/build/bin
export PATH=$LLVM_PATH_BIN:$PATH
alias cllvm='cd ${LLVM_PATH}'
