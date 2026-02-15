# C++ profile - LLVM, clang, cmake
[ -z "$MY_UTILS_ROOT" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$MY_UTILS_ROOT/profiles/base/env.bash"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
source "$MYRC_PATH/llvm.bash"
