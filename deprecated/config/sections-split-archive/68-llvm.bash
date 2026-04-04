# Section: LLVM checkout, cllvm, and LLVM_BIN_PATH for toolchain PATH
export LLVM_PATH="${LLVM_PATH:-$HOME/workspace/repos/llvm-project}"
alias cllvm='cd ${LLVM_PATH}'

if [ -n "${LLVM_PATH-}" ] && [ -f "${LLVM_PATH}/build/bin/clang" ]; then
  export LLVM_BIN_PATH=${LLVM_PATH}/build/bin
elif [ -d "$HOME/bin/llvm-19.1.1/bin" ]; then
  export LLVM_BIN_PATH=$HOME/bin/llvm-19.1.1/bin
else
  LLVM_BIN_PATH=""
fi
