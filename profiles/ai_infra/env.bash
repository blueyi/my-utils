# AI Infra - LLVM/MLIR, TVM, workload tools
[ -z "$MY_UTILS_ROOT" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$MY_UTILS_ROOT/profiles/base/env.bash"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
[ -f "$MYRC_PATH/llvm.bash" ] && source "$MYRC_PATH/llvm.bash"
# TVM: uncomment when needed
# source "$MYRC_PATH/tvm.bash"
