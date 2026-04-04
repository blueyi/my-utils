# Section: prepend tool dirs to PATH (idempotent)
_path_add() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH";; esac; }
[ -n "${CMAKE_PATH:-}" ] && _path_add "$CMAKE_PATH"
[ -n "${LOCAL_BIN_PATH:-}" ] && _path_add "$LOCAL_BIN_PATH"
[ -n "${MY_BIN:-}" ] && _path_add "$MY_BIN"
[ -n "${HOME_BIN:-}" ] && _path_add "$HOME_BIN"
[ -n "${CUDA_BIN_PATH:-}" ] && _path_add "$CUDA_BIN_PATH"
[ -n "${LLVM_BIN_PATH:-}" ] && _path_add "$LLVM_BIN_PATH"
unset -f _path_add 2>/dev/null; unset _brew_prefix 2>/dev/null
