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

# Base PATH - platform-aware (brew/node on macOS; standard Linux paths)
if _is_macos; then
  # Homebrew: Apple Silicon /opt/homebrew, Intel /usr/local
  _brew_prefix=""
  [ -d /opt/homebrew ] && _brew_prefix="/opt/homebrew"
  [ -z "$_brew_prefix" ] && [ -d /usr/local/Homebrew ] && _brew_prefix="/usr/local"
  if [ -n "$_brew_prefix" ]; then
    export PATH="${_brew_prefix}/bin:${_brew_prefix}/sbin:$PATH"
    [ -d "${_brew_prefix}/opt/curl/bin" ] && export PATH="${_brew_prefix}/opt/curl/bin:$PATH"
    [ -d "${_brew_prefix}/opt/curl/lib" ] && export LDFLAGS="${LDFLAGS:+$LDFLAGS }-L${_brew_prefix}/opt/curl/lib"
    [ -d "${_brew_prefix}/opt/curl/include" ] && export CPPFLAGS="${CPPFLAGS:+$CPPFLAGS }-I${_brew_prefix}/opt/curl/include"
  fi
  export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
else
  # Linux
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
  [ -d /usr/games ] && export PATH="$PATH:/usr/games"
  [ -d /usr/local/games ] && export PATH="$PATH:/usr/local/games"
  [ -d /snap/bin ] && export PATH="$PATH:/snap/bin"
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
fi
unset PYTHONPATH

# C++ / CMake build environment (Ninja, C/C++ compiler; paths differ on macOS vs Linux)
if _is_macos; then
  # Ninja/cmake from Homebrew; clang from Xcode Command Line Tools
  [ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
  [ -d /usr/local/bin ] && case ":$PATH:" in *":/usr/local/bin:"*) ;; *) export PATH="/usr/local/bin:$PATH";; esac
  [ -x /usr/bin/clang ] && export CC=/usr/bin/clang
  [ -x /usr/bin/clang++ ] && export CXX=/usr/bin/clang++
  # Optional: use Homebrew LLVM instead of Xcode clang (uncomment if needed)
  # [ -d /opt/homebrew/opt/llvm/bin ] && export PATH="/opt/homebrew/opt/llvm/bin:$PATH" && export CC=clang CXX=clang++
  # [ -d /usr/local/opt/llvm/bin ] && export PATH="/usr/local/opt/llvm/bin:$PATH" && export CC=clang CXX=clang++
else
  # Linux: gcc/g++, ninja(ninja-build) and cmake usually in /usr/bin or /usr/local/bin
  [ -x /usr/bin/gcc ] && export CC=/usr/bin/gcc
  [ -x /usr/bin/g++ ] && export CXX=/usr/bin/g++
  [ -d /usr/local/bin ] && case ":$PATH:" in *":/usr/local/bin:"*) ;; *) export PATH="/usr/local/bin:$PATH";; esac
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
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_CONFIGURE_OPTS="--enable-shared"

# NVM, pyenv, rbenv - works on both platforms
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" 2>/dev/null || true
[ -s "$NVM_DIR/zsh_completion" ] && . "$NVM_DIR/zsh_completion" 2>/dev/null || true

export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init -)" || true

export PATH="$HOME/.rbenv/bin:$PATH"
command -v rbenv >/dev/null && eval "$(rbenv init - 2>/dev/null)" || true

# Rust (rustup: ~/.cargo/env from rustup-init, or Homebrew /opt/homebrew/opt/rustup/bin)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d /opt/homebrew/opt/rustup/bin ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
[ -d /usr/local/opt/rustup/bin ] && export PATH="/usr/local/opt/rustup/bin:$PATH"

# CUDA (Linux, optional)
if _is_linux && [ -d /usr/local/cuda ]; then
  export CUDA_PATH=/usr/local/cuda
  export CUDA_BIN_PATH=$CUDA_PATH/bin
  export CUDA_LIB_PATH=$CUDA_PATH/lib64:$CUDA_PATH/extras/CUPTI/lib64
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$CUDA_LIB_PATH"
  export LIBRARY_PATH="${LIBRARY_PATH:-$LD_LIBRARY_PATH}"
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

# Prepend user paths (only add existing dirs)
_path_prepend=""
[ -n "$CMAKE_PATH" ] && _path_prepend="$CMAKE_PATH"
[ -d "$LOCAL_BIN_PATH" ] && _path_prepend="${_path_prepend:+$_path_prepend:}$LOCAL_BIN_PATH"
[ -d "$MY_BIN" ] && _path_prepend="${_path_prepend:+$_path_prepend:}$MY_BIN"
[ -d "$HOME_BIN" ] && _path_prepend="${_path_prepend:+$_path_prepend:}$HOME_BIN"
[ -n "${CUDA_BIN_PATH:-}" ] && [ -d "$CUDA_BIN_PATH" ] && _path_prepend="${_path_prepend:+$_path_prepend:}$CUDA_BIN_PATH"
[ -n "$LLVM_BIN_PATH" ] && [ -d "$LLVM_BIN_PATH" ] && _path_prepend="${_path_prepend:+$_path_prepend:}$LLVM_BIN_PATH"
[ -n "$_path_prepend" ] && export PATH="$_path_prepend:$PATH"
unset _path_prepend _brew_prefix

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
