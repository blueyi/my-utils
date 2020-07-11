# For golang
export PATH=$PATH:/usr/local/go/bin

# alias
# alias wn='watch -n 1 nvidia-smi'
# alias st='source ~/tensorflow/bin/activate'

# for python complete in interactive shell
export PYTHONSTARTUP=$HOME/.pythonstartup

# jdk
JAVA_HOME=/usr/lib/jvm/java-8-oracle
JRE_HOME=$JAVA_HOME/jre
CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin

export JAVA_HOME
export JRE_HOME
export CLASSPATH
export PATH

#nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# cuda
export CUDA_PATH=/usr/local/cuda
export PATH=$CUDA_PATH/bin:${PATH}}
export LD_LIBRARY_PATH=$CUDA_PATH/lib64:${LD_LIBRARY_PATH}}
# cupti
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_PATH/extras/CUPTI/lib64


# my bin
MY_BIN=$HOME/my-utils/common
FFMPEG_BIN=$HOME/bin
PATH=$PATH:$MY_BIN:$FFMPEG_BIN
export PATH

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# http_proxy
alias hp="http_proxy=http://127.0.0.1:1081 https_proxy=http://127.0.0.1:1081"

# pip
export PATH=$HOME/.local/bin:$PATH

# auto run n times
function run() {
    number=$1
    shift
    for n in $(seq $number); do
      $@
    done
}

# For bazel
# source /home/blueyi/.bazel/bin/bazel-complete.bash

# for tvm
export TVM_HOME=$HOME/github/tvm
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TVM_HOME/build
export PYTHONPATH=$PYTHONPATH:$TVM_HOME/python:$TVM_HOME/topi/python:$TVM_HOME/nnvm/python

