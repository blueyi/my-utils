# Section: baseline PATH / macOS Homebrew keg flags (idempotent)
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
  [ -d /usr/games ] && _path="$_path:/usr/games"
  [ -d /usr/local/games ] && _path="$_path:/usr/local/games"
  [ -d /snap/bin ] && _path="$_path:/snap/bin"
  export PATH="$_path"
  unset _path
fi
unset PYTHONPATH
