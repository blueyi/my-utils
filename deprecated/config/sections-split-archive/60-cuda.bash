# Section: CUDA (Linux, optional)
if _is_linux && [ -d /usr/local/cuda ]; then
  export CUDA_PATH=/usr/local/cuda
  export CUDA_BIN_PATH=$CUDA_PATH/bin
  export CUDA_LIB_PATH=$CUDA_PATH/lib64:$CUDA_PATH/extras/CUPTI/lib64
  export LD_LIBRARY_PATH="$CUDA_LIB_PATH"
  export LIBRARY_PATH="$CUDA_LIB_PATH"
fi
