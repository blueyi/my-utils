source $HOME/repos/my-utils/config/resetrc.bash

export TOOLKIT_PATH=$HOME/Ascend/ascend-toolkit/20.10.0.B023/x86_64-linux_gcc7.3.0
export ACL_SO_PATH=$TOOLKIT_PATH/pyACL/python/site-packages/acl
export ATC_CCE_BIN_PATH=$TOOLKIT_PATH/atc/ccec_compiler/bin:$TOOLKIT_PATH/atc/bin
export ATC_PY_PATH=$TOOLKIT_PATH/atc/python/site-packages:$TOOLKIT_PATH/atc/python/site-packages/auto_tune.egg/auto_tune:$TOOLKIT_PATH/atc/python/site-packages/schedule_search.egg
export ATC_LIB_PATH=$TOOLKIT_PATH/atc/lib64
export ADC_BIN_PATH=$TOOLKIT_PATH/toolkit/bin
export OP_TEST_PY_PATH=$TOOLKIT_PATH/toolkit/python/site-packages

export PYTHONPATH=${PYTHONPATH}:$ACL_SO_PATH:$ATC_PY_PATH:$OP_TEST_PY_PATH
export PATH=${PATH}:$ATC_CCE_BIN_PATH:$ADC_BIN_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ATC_LIB_PATH
