source $HOME/repos/my-utils/config/resetrc.bash

# for llvm
export LLVM_PATH=$HOME/repos/llvm-project/build/bin
export PATH=$LLVM_PATH:$PATH
alias cllvm='cd ${LLVM_PATH}'
