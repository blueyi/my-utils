# resetrc.bash - Shell init base for Linux + macOS
# MY_UTILS_ROOT from ~/.my-utils.env (bootstrap) or derived from this script path (config/resetrc.bash -> ..)
[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"

# Platform
_is_linux() { [[ "$(uname -s)" = Linux* ]]; }
_is_macos() { [[ "$(uname -s)" = Darwin* ]]; }

# For proxy
[ -f "$MYRC_PATH/proxy.bash" ] && source "$MYRC_PATH/proxy.bash"

# Base PATH and lib env - initialize to baseline so repeated source does not accumulate (idempotent)
if _is_macos; then
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
  # macOS baseline PATH (no $PATH - avoid duplicate when source multiple times)
  _path="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
  _ldflags=""
  _cppflags=""
  _pkg_config_path=""
  _brew_prefix=""
  [ -d /opt/homebrew ] && _brew_prefix="/opt/homebrew"
  [ -z "$_brew_prefix" ] && [ -d /usr/local/Homebrew ] && _brew_prefix="/usr/local"
  if [ -n "$_brew_prefix" ]; then
    _path="${_brew_prefix}/bin:${_brew_prefix}/sbin:$_path"
    [ -d "${_brew_prefix}/opt/curl/bin" ] && _path="${_brew_prefix}/opt/curl/bin:$_path"
    [ -d "${_brew_prefix}/opt/curl/lib" ] && _ldflags="-L${_brew_prefix}/opt/curl/lib $_ldflags"
    [ -d "${_brew_prefix}/opt/curl/include" ] && _cppflags="-I${_brew_prefix}/opt/curl/include $_cppflags"
    [ -d "${_brew_prefix}/opt/tcl-tk@8/bin" ] && _path="${_brew_prefix}/opt/tcl-tk@8/bin:$_path"
    for _keg in tcl-tk zlib openssl readline sqlite xz libb2 zstd; do
      [ -d "${_brew_prefix}/opt/$_keg/lib" ] && _ldflags="-L${_brew_prefix}/opt/$_keg/lib $_ldflags"
      [ -d "${_brew_prefix}/opt/$_keg/include" ] && _cppflags="-I${_brew_prefix}/opt/$_keg/include $_cppflags"
      [ -d "${_brew_prefix}/opt/$_keg/lib/pkgconfig" ] && _pkg_config_path="${_brew_prefix}/opt/$_keg/lib/pkgconfig:$_pkg_config_path"
    done
    unset _keg
  fi
  export PATH="$_path"
  export LDFLAGS="${_ldflags% }"
  export CPPFLAGS="${_cppflags% }"
  export PKG_CONFIG_PATH="${_pkg_config_path%:}"
  unset _path _ldflags _cppflags _pkg_config_path
else
  # Linux: baseline PATH (no $PATH); clear lib paths so repeated source is idempotent
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
  _path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  [ -d /usr/games ] && _path="$_path:/usr/games"
  [ -d /usr/local/games ] && _path="$_path:/usr/local/games"
  [ -d /snap/bin ] && _path="$_path:/snap/bin"
  export PATH="$_path"
  unset _path
fi
unset PYTHONPATH

# C++ / CMake build environment (CC/CXX; PATH already set above)
if _is_macos; then
  [ -x /usr/bin/clang ] && export CC=/usr/bin/clang
  [ -x /usr/bin/clang++ ] && export CXX=/usr/bin/clang++
else
  [ -x /usr/bin/gcc ] && export CC=/usr/bin/gcc
  [ -x /usr/bin/g++ ] && export CXX=/usr/bin/g++
fi
# CMake finds Ninja via PATH; optionally set CMAKE_MAKE_PROGRAM for scripts that use it
if [ -z "${CMAKE_MAKE_PROGRAM:-}" ]; then
  _ninja=$(command -v ninja 2>/dev/null || command -v ninja-build 2>/dev/null)
  [ -n "$_ninja" ] && export CMAKE_MAKE_PROGRAM="$_ninja"
fi
unset _ninja 2>/dev/null || true

# For Chinese language
# export LANG=zh_CN.UTF-8

# For gogh terminal theme (Linux only)
_is_linux && export TERMINAL=gnome-terminal

# pyenv build options
export PYTHON_BUILD_MIRROR_URL="https://www.python.org/ftp/python/"
# export PYTHON_BUILD_MIRROR_URL="https://mirrors.huaweicloud.com/python/"
# export PYTHON_BUILD_MIRROR_URL="https://mirrors.aliyun.com/python/"
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_CONFIGURE_OPTS="--enable-shared"

# NVM, pyenv, rbenv - works on both platforms
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" 2>/dev/null || true
[ -s "$NVM_DIR/zsh_completion" ] && . "$NVM_DIR/zsh_completion" 2>/dev/null || true

# pyenv (prepend only if not already in PATH - idempotent for repeated source)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) export PATH="$PYENV_ROOT/bin:$PATH";; esac
command -v pyenv >/dev/null && eval "$(pyenv init -)" || true
eval "$(pyenv virtualenv-init -)"

# rbenv
case ":$PATH:" in *":$HOME/.rbenv/bin:"*) ;; *) export PATH="$HOME/.rbenv/bin:$PATH";; esac
command -v rbenv >/dev/null && eval "$(rbenv init - 2>/dev/null)" || true

# Rust (rustup)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d /opt/homebrew/opt/rustup/bin ] && case ":$PATH:" in *":/opt/homebrew/opt/rustup/bin:"*) ;; *) export PATH="/opt/homebrew/opt/rustup/bin:$PATH";; esac
[ -d /usr/local/opt/rustup/bin ] && case ":$PATH:" in *":/usr/local/opt/rustup/bin:"*) ;; *) export PATH="/usr/local/opt/rustup/bin:$PATH";; esac

# OpenClaw CLI Tab completion (must run after compinit, e.g. after oh-my-zsh)
[[ -f ~/.openclaw/completions/openclaw.zsh ]] && source ~/.openclaw/completions/openclaw.zsh

# OpenClaw Completion
source "$HOME/.openclaw/completions/openclaw.zsh"


# CUDA (Linux, optional) - set explicitly so repeated source does not accumulate
if _is_linux && [ -d /usr/local/cuda ]; then
  export CUDA_PATH=/usr/local/cuda
  export CUDA_BIN_PATH=$CUDA_PATH/bin
  export CUDA_LIB_PATH=$CUDA_PATH/lib64:$CUDA_PATH/extras/CUPTI/lib64
  export LD_LIBRARY_PATH="$CUDA_LIB_PATH"
  export LIBRARY_PATH="$CUDA_LIB_PATH"
fi

# My bins
MY_BIN=${MY_UTILS_ROOT}/common
HOME_BIN=$HOME/bin
export LOCAL_BIN_PATH=$HOME/.local/bin

# LLVM (optional, guard)
if [ -n "${LLVM_PATH-}" ] && [ -f "${LLVM_PATH}/build/bin/clang" ]; then
  export LLVM_BIN_PATH=${LLVM_PATH}/build/bin
elif [ -d "$HOME/bin/llvm-19.1.1/bin" ]; then
  export LLVM_BIN_PATH=$HOME/bin/llvm-19.1.1/bin
else
  LLVM_BIN_PATH=""
fi

# CMake (optional, guard)
[ -d "$HOME/bin/cmake/bin" ] && export CMAKE_PATH=$HOME/bin/cmake/bin || CMAKE_PATH=""

# Prepend user paths (idempotent: only add if not already in PATH)
_path_add() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH";; esac; }
[ -n "$CMAKE_PATH" ] && _path_add "$CMAKE_PATH"
[ -n "$LOCAL_BIN_PATH" ] && _path_add "$LOCAL_BIN_PATH"
[ -n "$MY_BIN" ] && _path_add "$MY_BIN"
[ -n "$HOME_BIN" ] && _path_add "$HOME_BIN"
[ -n "${CUDA_BIN_PATH:-}" ] && _path_add "$CUDA_BIN_PATH"
[ -n "$LLVM_BIN_PATH" ] && _path_add "$LLVM_BIN_PATH"
unset -f _path_add 2>/dev/null; unset _brew_prefix 2>/dev/null

# Zellij
export ZELLIJ_SOCKET_DIR=/tmp/zellij

# Functions
run_n_times() {
  local n=$1 i=1; shift
  while [ "$i" -le "$n" ]; do
    "$@"
    i=$((i+1))
  done
}

run_multi_thread() {
  local thread_num=10 run_times=100
  local cmd=("$@")
  mkfifo tm1 2>/dev/null || return 1
  exec 5<>tm1
  rm -f tm1
  for ((i=1;i<=thread_num;i++)); do echo >&5; done
  for ((j=1;j<=run_times;j++)); do
    read -u5
    { "${cmd[@]}"; sleep 1; echo >&5; }&
  done
  wait
  exec 5>&-
  exec 5<&-
}

# Aliases - Linux-specific guarded
if _is_linux; then
  alias wn='watch -n 1 nvidia-smi'
  alias ess='sudo service ssh start'
  [ -d "$HOME/soft/xdm-linux-portable-x64" ] && alias exdm="cd $HOME/soft/xdm-linux-portable-x64 && ./xdman"
  [ -f "$HOME/bin/clion/bin/clion.sh" ] && alias clion='sh $HOME/bin/clion/bin/clion.sh'
  [ -f "$HOME/soft/clash/clash.sh" ] && alias ecc="${HOME}/soft/clash/clash.sh"
  alias winetricks='env LANG=zh_CN.UTF-8 winetricks'
  alias wine='env LANG=zh_CN.UTF-8 wine'
  [ -f "$HOME/.wine/drive_c/Program Files (x86)/Tencent/WeChat/WeChat.exe" ] && alias wechat='env LANG=zh_CN.UTF-8 wine "'"$HOME"'/.wine/drive_c/Program Files (x86)/Tencent/WeChat/WeChat.exe"'
  [ -f "${MY_UTILS_ROOT}/bin/v2ray/Qv2ray-v2.7.0-linux-x64.AppImage" ] && alias ev2="${MY_UTILS_ROOT}/bin/v2ray/Qv2ray-v2.7.0-linux-x64.AppImage"
fi
