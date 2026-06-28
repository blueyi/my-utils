# resetrc.bash — shared shell env for bash/zsh (optional Fish: emit_fish_env.bash sources this file).
# Sections below are delimiter comments only (single file). Search for "SECTION:" to jump.

[ -f "$HOME/.my-utils.env" ] && source "$HOME/.my-utils.env"
[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
export MY_CONF_PATH="${MYRC_PATH}"

# Linux + WSL: WSL2 reports Linux in uname; extra probes match common/platform.sh is_wsl for edge cases.
_is_linux() {
  [[ "$(uname -s)" = Linux* ]] && return 0
  [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
  [ -n "${WSL_INTEROP:-}" ] && return 0
  grep -qi microsoft /proc/version 2>/dev/null && return 0
  return 1
}
_is_macos() { [[ "$(uname -s)" = Darwin* ]]; }

# =============================================================================
# SECTION: Proxy (optional)
# =============================================================================
[ -f "$MYRC_PATH/proxy.bash" ] && source "$MYRC_PATH/proxy.bash"

# =============================================================================
# SECTION: Baseline PATH / macOS Homebrew keg flags
# =============================================================================
if _is_macos; then
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
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
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
  _path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  [ -d /usr/lib/wsl/lib ] && _path="/usr/lib/wsl/lib:$_path"
  [ -d /usr/games ] && _path="$_path:/usr/games"
  [ -d /usr/local/games ] && _path="$_path:/usr/local/games"
  [ -d /snap/bin ] && _path="$_path:/snap/bin"
  export PATH="$_path"
  unset _path
fi
unset PYTHONPATH

# =============================================================================
# SECTION: CC/CXX and Ninja (CMake)
# =============================================================================
if _is_macos; then
  [ -x /usr/bin/clang ] && export CC=/usr/bin/clang
  [ -x /usr/bin/clang++ ] && export CXX=/usr/bin/clang++
else
  [ -x /usr/bin/gcc ] && export CC=/usr/bin/gcc
  [ -x /usr/bin/g++ ] && export CXX=/usr/bin/g++
fi
if [ -z "${CMAKE_MAKE_PROGRAM:-}" ]; then
  _ninja=$(command -v ninja 2>/dev/null || command -v ninja-build 2>/dev/null)
  [ -n "$_ninja" ] && export CMAKE_MAKE_PROGRAM="$_ninja"
fi
unset _ninja 2>/dev/null || true

# =============================================================================
# SECTION: Locale hints
# =============================================================================
# export LANG=zh_CN.UTF-8
# Skip on WSL (/proc/version contains Microsoft); gnome-terminal is not the host GUI there.
_is_linux && ! grep -qi microsoft /proc/version 2>/dev/null && export TERMINAL=gnome-terminal

# pyenv build defaults (deprecated — uv uses prebuilt CPython; keep commented for reference)
# export PYTHON_BUILD_MIRROR_URL="https://www.python.org/ftp/python/"
# export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
# export PYTHON_CONFIGURE_OPTS="--enable-shared"

# =============================================================================
# SECTION: NVM
# =============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" 2>/dev/null || true
[ -s "$NVM_DIR/zsh_completion" ] && . "$NVM_DIR/zsh_completion" 2>/dev/null || true

# =============================================================================
# SECTION: npm global bin
# =============================================================================
if [ -d "$HOME/.npm-global/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.npm-global/bin:"*) ;;
    *) export PATH="$HOME/.npm-global/bin:$PATH" ;;
  esac
fi

# =============================================================================
# SECTION: uv (Python toolchain — versions, venv, packages)
# =============================================================================
# Install:  curl -LsSf https://astral.sh/uv/install.sh | sh   OR   brew install uv
#
# Python versions:
#   uv python list                         # available & installed interpreters
#   uv python install 3.12                 # install CPython 3.12 (prebuilt)
#   uv python install 3.10 --default       # install and set as default `python`
#   uv python pin 3.12                     # write .python-version in cwd
#   uv python pin --global 3.12            # global default (~/.local/share/uv/global-python-pin)
#   uv python find                         # resolve active interpreter
#
# Virtual environments:
#   uv venv                                # create .venv (uses pinned / default Python)
#   uv venv ~/.venvs/myproj -p 3.12        # custom path + version
#   source .venv/bin/activate
#
# Projects (pyproject.toml):
#   uv init                                # new project
#   uv add requests                        # add dependency + update lockfile
#   uv sync                                # install locked deps into .venv
#   uv run python script.py                # run in project env (no activate)
#   uv run pytest
#
# Ad-hoc packages / CLI tools:
#   uv pip install numpy
#   uv tool install ruff                   # isolated tool env under ~/.local/bin
#
# Misc:
#   uv self update
#   UV_PYTHON=3.11 uv run ...              # one-shot Python override
#
export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-$HOME/.local/share/uv/python}"
export UV_TOOL_DIR="${UV_TOOL_DIR:-$HOME/.local/share/uv/tools}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$HOME/.cache/uv}"

# uv binary lives in ~/.local/bin (also prepended later in PATH section)
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

if command -v uv >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(uv generate-shell-completion zsh 2>/dev/null)" || true
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(uv generate-shell-completion bash 2>/dev/null)" || true
  fi
fi

# =============================================================================
# SECTION: pyenv + virtualenv (deprecated — replaced by uv above)
# =============================================================================
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d "$PYENV_ROOT/bin" ]] && case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) export PATH="$PYENV_ROOT/bin:$PATH";; esac
# command -v pyenv >/dev/null && eval "$(pyenv init -)" || true
# eval "$(pyenv virtualenv-init -)" || true

# =============================================================================
# SECTION: rbenv + Rust (rustup)
# =============================================================================
case ":$PATH:" in *":$HOME/.rbenv/bin:"*) ;; *) export PATH="$HOME/.rbenv/bin:$PATH";; esac
command -v rbenv >/dev/null && eval "$(rbenv init - 2>/dev/null)" || true

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d /opt/homebrew/opt/rustup/bin ] && case ":$PATH:" in *":/opt/homebrew/opt/rustup/bin:"*) ;; *) export PATH="/opt/homebrew/opt/rustup/bin:$PATH";; esac
[ -d /usr/local/opt/rustup/bin ] && case ":$PATH:" in *":/usr/local/opt/rustup/bin:"*) ;; *) export PATH="/usr/local/opt/rustup/bin:$PATH";; esac

# =============================================================================
# SECTION: OpenClaw — CLI env (doctor: compile cache + no respawn; all shells)
# =============================================================================
export NODE_COMPILE_CACHE="${NODE_COMPILE_CACHE:-/var/tmp/openclaw-compile-cache}"
export OPENCLAW_NO_RESPAWN="${OPENCLAW_NO_RESPAWN:-1}"
[ -d "$NODE_COMPILE_CACHE" ] || mkdir -p "$NODE_COMPILE_CACHE" 2>/dev/null || true

# =============================================================================
# SECTION: zsh-only — OpenClaw + fzf
# =============================================================================
if [ -n "${ZSH_VERSION:-}" ]; then
  if _is_macos; then
    if ! type compinit >/dev/null 2>&1; then
      autoload -Uz compinit
      compinit
    fi
    if ! type bashcompinit >/dev/null 2>&1; then
      autoload -Uz bashcompinit
      bashcompinit
    fi
  fi
  # OpenClaw (zsh): ~/.openclaw install first; else npm-global (completions or upstream completons path).
  _oc_zsh=""
  [ -f "$HOME/.openclaw/completions/openclaw.zsh" ] && _oc_zsh="$HOME/.openclaw/completions/openclaw.zsh"
  [ -z "$_oc_zsh" ] && [ -f "$HOME/.npm-global/lib/node_modules/openclaw/completions/openclaw.zsh" ] && _oc_zsh="$HOME/.npm-global/lib/node_modules/openclaw/completions/openclaw.zsh"
  [ -z "$_oc_zsh" ] && [ -f "$HOME/.npm-global/lib/node_modules/openclaw/completons/openclaw.zsh" ] && _oc_zsh="$HOME/.npm-global/lib/node_modules/openclaw/completons/openclaw.zsh"
  [ -n "$_oc_zsh" ] && source "$_oc_zsh"
  unset _oc_zsh
  if _is_linux; then
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && . /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && . /usr/share/doc/fzf/examples/completion.zsh
  elif _is_macos; then
    _fzf_prefix=""
    command -v brew >/dev/null 2>&1 && _fzf_prefix="$(brew --prefix fzf 2>/dev/null)"
    [ -n "$_fzf_prefix" ] && [ -f "$_fzf_prefix/shell/key-bindings.zsh" ] && . "$_fzf_prefix/shell/key-bindings.zsh"
    [ -n "$_fzf_prefix" ] && [ -f "$_fzf_prefix/shell/completion.zsh" ] && . "$_fzf_prefix/shell/completion.zsh"
    unset _fzf_prefix
  fi
fi

# =============================================================================
# SECTION: Hermes shell completion (bash/zsh)
# =============================================================================
if command -v hermes >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz compinit 2>/dev/null || true
    compinit 2>/dev/null || true
    eval "$(hermes completion zsh 2>/dev/null)" || true
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(hermes completion bash 2>/dev/null)" || true
  fi
fi

# =============================================================================
# SECTION: CUDA (Linux, optional)
# =============================================================================
if _is_linux && [ -d /usr/local/cuda ]; then
  export CUDA_PATH=/usr/local/cuda
  export CUDA_BIN_PATH=$CUDA_PATH/bin
  export CUDA_LIB_PATH=$CUDA_PATH/lib64:$CUDA_PATH/extras/CUPTI/lib64
  if [ -d /usr/lib/wsl/lib ]; then
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$CUDA_LIB_PATH"
    export LIBRARY_PATH="/usr/lib/wsl/lib:$CUDA_LIB_PATH"
  else
    export LD_LIBRARY_PATH="$CUDA_LIB_PATH"
    export LIBRARY_PATH="$CUDA_LIB_PATH"
  fi
fi

# =============================================================================
# SECTION: Repo common bin + user layout
# =============================================================================
MY_BIN=${MY_UTILS_ROOT}/common
HOME_BIN=$HOME/bin
export LOCAL_BIN_PATH=$HOME/.local/bin

[ -d "$HOME/bin/cmake/bin" ] && export CMAKE_PATH=$HOME/bin/cmake/bin || CMAKE_PATH=""

# =============================================================================
# SECTION: LLVM checkout + LLVM_BIN_PATH
# =============================================================================
export LLVM_PATH="${LLVM_PATH:-$HOME/workspace/repos/llvm-project}"
alias cllvm='cd ${LLVM_PATH}'

if [ -n "${LLVM_PATH-}" ] && [ -f "${LLVM_PATH}/build/bin/clang" ]; then
  export LLVM_BIN_PATH=${LLVM_PATH}/build/bin
elif [ -d "$HOME/bin/llvm-19.1.1/bin" ]; then
  export LLVM_BIN_PATH=$HOME/bin/llvm-19.1.1/bin
else
  LLVM_BIN_PATH=""
fi

# =============================================================================
# SECTION: PATH prepend (cmake, cuda, llvm, …)
# =============================================================================
_path_add() { [ -d "$1" ] && case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH";; esac; }
[ -n "${CMAKE_PATH:-}" ] && _path_add "$CMAKE_PATH"
[ -n "${LOCAL_BIN_PATH:-}" ] && _path_add "$LOCAL_BIN_PATH"
_path_add "$HOME/.local/go/bin"
[ -n "${MY_BIN:-}" ] && _path_add "$MY_BIN"
[ -n "${HOME_BIN:-}" ] && _path_add "$HOME_BIN"
[ -n "${CUDA_BIN_PATH:-}" ] && _path_add "$CUDA_BIN_PATH"
[ -n "${LLVM_BIN_PATH:-}" ] && _path_add "$LLVM_BIN_PATH"
unset -f _path_add 2>/dev/null; unset _brew_prefix 2>/dev/null

# =============================================================================
# SECTION: Zellij
# =============================================================================
export ZELLIJ_SOCKET_DIR=/tmp/zellij

# =============================================================================
# SECTION: Git dual-remote (GitHub + GitCode mirror)
# =============================================================================
[ -f "$MYRC_PATH/git-dual-remote.bash" ] && . "$MYRC_PATH/git-dual-remote.bash"

# =============================================================================
# SECTION: Functions
# =============================================================================
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

# =============================================================================
# SECTION: Linux-only aliases
# =============================================================================
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
