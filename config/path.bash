# PATH setup: cross-shell (bash/zsh) and cross-platform (macOS/Linux).
# Sourced from config/myrc.bash and config/_bashrc; no dependency on .my-utils.env for PATH.
case "$(uname -s)" in
  Darwin*)
    for d in /opt/homebrew/bin /usr/local/bin; do
      if [ -d "$d" ]; then
        export PATH="$d:$PATH"
        break
      fi
    done
    ;;
  Linux*)
    # Ensure common tool paths (e.g. for CMake/ninja on apt)
    for d in /usr/local/bin /usr/bin; do
      if [ -d "$d" ]; then
        case ":$PATH:" in
          *":$d:"*) ;;
          *) export PATH="$d:$PATH" ;;
        esac
      fi
    done
    ;;
  *) ;;
esac
