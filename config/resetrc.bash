# For proxy
unset ALL_PROXY
unset all_proxy
unset http_proxy
unset HTTP_PROXY
unset https_proxy
unset HTTPS_PROXY

# For PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
unset LD_LIBRARY_PATH
unset LIBRARY_PATH
unset PYTHONPATH

# For Chinese language
# export LANG=zh_CN.UTF-8

# For gogh terminal theme
export TERMINAL=gnome-terminal

# export MYRC_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd);
export MYRC_PATH=$HOME/repos/my-utils/config
source $MYRC_PATH/proxy.bash

# http_proxy
# alias hp="http_proxy=http://127.0.0.1:1081 https_proxy=http://127.0.0.1:1081"
alias hp="http_proxy=http://192.168.3.98:1081 https_proxy=http://192.168.3.98:1081"

# for python complete in interactive shell
export PYTHONSTARTUP=$HOME/.pythonstartup

# jdk
# export JAVA_HOME=/usr/lib/jvm/java-8-oracle
# export JRE_HOME=$JAVA_HOME/jre
# export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib
# export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin

# node for hexo
# export PATH=$PATH:$HOME/node_modules/.bin
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# cuda
export CUDA_PATH=/usr/local/cuda
export CUDA_BIN_PATH=$CUDA_PATH/bin
export CUDA_LIB_PATH=$CUDA_PATH/lib64:$CUDA_PATH/extras/CUPTI/lib64

# my bin
MY_BIN=$HOME/my-utils/common
HOME_BIN=$HOME/bin

# for pip
export LOCAL_BIN_PATH=$HOME/.local/bin

# for llvm
# cmake -S llvm -B build -G "Ninja" -DLLVM_ENABLE_PROJECTS="clang" -DCMAKE_INSTALL_PREFIX=/home/wangyulong/bin/llvm_12 -DCMAKE_BUILD_TYPE=Debug
# cmake --build build
export LLVM_PATH=$HOME/bin/llvm-12/bin

# for cmake
export CMAKE_PATH=$HOME/bin/cmake/bin

export PATH=$PATH:$CMAKE_PATH:$LOCAL_BIN_PATH:$MY_BIN:$HOME_BIN:$CUDA_BIN_PATH

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$CUDA_LIB_PATH:
export LIBRARY_PATH=$LD_LIBRARY_PATH

# pyenv
export PYTHON_BUILD_MIRROR_URL="http://npm.taobao.org/mirrors/python/"
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_CONFIGURE_OPTS="--enable-shared"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# auto run n times
function myrun() {
  number=$1
  shift
  for n in $(seq $number); do
    $@
  done
}

# run cmd run_times with thread_num multi-threads
function run_multi_thread() {
  thread_num=10
  run_times=100
  run_cmd=$@

  mkfifo tm1
  exec 5<>tm1
  rm -f tm1
  for ((i=1;i<=${thread_num};i++)) do
    echo >&5
  done

  for ((j=1;j<=${run_times};j++)) do
    read -u5
    {
      ${run_cmd}
      sleep 1
      echo >&5
    }&
  done
  wait
  exec 5>&-
  exec 5<&-
}


# For bazel
# source $HOME/.bazel/bin/bazel-complete.bash

# alias
alias wn='watch -n 1 nvidia-smi'
alias exdm='cd $HOME/soft/xdm-linux-portable-x64;./xdman'
alias ess='sudo service ssh start'
alias clion='sh $HOME/bin/clion/bin/clion.sh'
alias ecc='$HOME/soft/clash/clash.sh'
alias winetricks='env LANG=zh_CN.UTF-8 winetricks'
alias wine='env LANG=zh_CN.UTF-8 wine'
alias wechat='env LANG=zh_CN.UTF-8 wine "/home/wangyulong/.wine/drive_c/Program Files (x86)/Tencent/WeChat/WeChat.exe"'
alias ev2='/home/wangyulong/repos/my-utils/bin/v2ray/Qv2ray-v2.7.0-linux-x64.AppImage'
