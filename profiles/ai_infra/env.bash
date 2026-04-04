# AI Infra — LLVM/MLIR via resetrc sections; TVM optional below
[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$MY_UTILS_ROOT/profiles/base/env.bash"
# TVM: uncomment when needed (MYRC_PATH set by base)
# source "$MYRC_PATH/tvm.bash"
