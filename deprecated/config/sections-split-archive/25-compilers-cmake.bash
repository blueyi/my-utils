# Section: default CC/CXX and Ninja for CMake
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
