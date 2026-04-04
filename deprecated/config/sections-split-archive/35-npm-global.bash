# Section: npm global bin (e.g. openclaw CLI)
if [ -d "$HOME/.npm-global/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.npm-global/bin:"*) ;;
    *) export PATH="$HOME/.npm-global/bin:$PATH" ;;
  esac
fi
