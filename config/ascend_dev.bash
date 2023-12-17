source $HOME/repos/my-utils/config/resetrc.bash

export ASCEND_PATH=$HOME/Ascend
# export ASCEND_CUSTOM_PATH=${ASCEND_PATH}/ascend-toolkit/20.10.0.B023
export ASCEND_CUSTOM_PATH=${ASCEND_PATH}/ascend-toolkit/20.1
export TOOLKIT_PATH=${ASCEND_CUSTOM_PATH} # /x86_64-linux_gcc7.3.0
export ACL_SO_PATH=$TOOLKIT_PATH/pyACL/python/site-packages/acl
export ATC_CCE_BIN_PATH=$TOOLKIT_PATH/atc/ccec_compiler/bin:$TOOLKIT_PATH/atc/bin
export ATC_PY_PATH=$TOOLKIT_PATH/atc/python/site-packages:$TOOLKIT_PATH/atc/python/site-packages/auto_tune.egg/auto_tune:$TOOLKIT_PATH/atc/python/site-packages/schedule_search.egg
export ATC_LIB_PATH=$TOOLKIT_PATH/atc/lib64
export ADC_BIN_PATH=$TOOLKIT_PATH/toolkit/bin
export OP_TEST_PY_PATH=$TOOLKIT_PATH/toolkit/python/site-packages
export IMPL_PATH=$TOOLKIT_PATH/opp/op_impl/built-in/ai_core/tbe

export PYTHONPATH=${PYTHONPATH}:$ACL_SO_PATH:$ATC_PY_PATH:$OP_TEST_PY_PATH:$IMPL_PATH
export PATH=${PATH}:$ATC_CCE_BIN_PATH:$ADC_BIN_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ATC_LIB_PATH

# For run ATC
export DUMP_OP=1
export DUMP_GE_GRAPH=2
export SLOG_PRINT_TO_STDOUT=1

export DDK_VERSION=1.76.T1.0.B101

# Model Convert cmd
# python3 -m tf2onnx.convert --opset 11 --input topk_16_128_float16.pb --inputs Placeholder:0 --outputs TopKV2:0,TopKV2:1 -- output topk_16_128_float16.onnx
# atc --model=topk_16_128_float16.onnx --framework=5 --output=topk_16_128_float16.om --disable_reuse_memory=1 -log=debug --soc_version=Ascend310
