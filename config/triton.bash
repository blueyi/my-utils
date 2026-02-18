# Triton (GPU kernel) dev environment - source when working on Triton / GPU kernels.
# Usage: source "$MYRC_PATH/triton.bash"  or  source "$MY_UTILS_ROOT/config/triton.bash"
# Requires: base env (resetrc) and CUDA on Linux; macOS Metal backend may differ.

[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
[ -f "$MYRC_PATH/resetrc.bash" ] && source "$MYRC_PATH/resetrc.bash"

# Optional: set if you have Triton repo or install path
# export TRITON_HOME="${TRITON_HOME:-$HOME/repos/triton}"
# [ -d "$TRITON_HOME/bin" ] && export PATH="$TRITON_HOME/bin:$PATH"

# CUDA (Linux): resetrc may already set CUDA_*; ensure nvcc and libs for Triton
case "$(uname -s)" in
  Linux*)
    if [ -d "${CUDA_PATH:-/usr/local/cuda}/bin" ]; then
      export PATH="${CUDA_PATH}/bin:${PATH}"
    fi
    if [ -d "${CUDA_PATH:-/usr/local/cuda}/lib64" ]; then
      export LD_LIBRARY_PATH="${CUDA_PATH}/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
    ;;
  Darwin*) ;;  # Triton on macOS often uses conda/pip; no CUDA
  *) ;;
esac

# Python / pip: triton is usually `pip install triton`
# Use pyenv/virtualenv as needed; no change here.
