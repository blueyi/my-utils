# CMake/Ninja/C++ environment - source this before running cmake when your shell
# did not load the full rc (e.g. Cursor terminal, IDE build).
# Usage: source /path/to/my-utils/config/cmake_env.bash
#    or: source "$MY_UTILS_ROOT/config/cmake_env.bash"

[ -z "${MY_UTILS_ROOT:-}" ] && export MY_UTILS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "${MY_UTILS_ROOT}/config/path.bash" ] && . "${MY_UTILS_ROOT}/config/path.bash"

case "$(uname -s)" in
  Darwin*)
    [ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
    [ -d /usr/local/bin ] && case ":$PATH:" in *":/usr/local/bin:"*) ;; *) export PATH="/usr/local/bin:$PATH";; esac
    [ -x /usr/bin/clang ] && export CC=/usr/bin/clang
    [ -x /usr/bin/clang++ ] && export CXX=/usr/bin/clang++
    ;;
  Linux*)
    [ -x /usr/bin/gcc ] && export CC=/usr/bin/gcc
    [ -x /usr/bin/g++ ] && export CXX=/usr/bin/g++
    [ -d /usr/local/bin ] && case ":$PATH:" in *":/usr/local/bin:"*) ;; *) export PATH="/usr/local/bin:$PATH";; esac
    ;;
  *) ;;
esac

if [ -z "${CMAKE_MAKE_PROGRAM:-}" ]; then
  _ninja=$(command -v ninja 2>/dev/null || command -v ninja-build 2>/dev/null)
  [ -n "$_ninja" ] && export CMAKE_MAKE_PROGRAM="$_ninja"
fi
unset _ninja 2>/dev/null || true
