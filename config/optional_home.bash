# optional_home.bash — optional snippets under $HOME (not in repo); bash/zsh safe
# Prefer AI keys in config/env.rc (loaded by resetrc). These home files are legacy overlays.
[ -f "$HOME/claude_conf.bash" ] && . "$HOME/claude_conf.bash"
[ -f "$HOME/github.bash" ] && . "$HOME/github.bash"
[ -d "$HOME/.openclaw/bin" ] && case ":${PATH:-}:" in *":$HOME/.openclaw/bin:"*) ;; *) export PATH="$HOME/.openclaw/bin:$PATH";; esac

# Codex helper PATH / extras (keys should live in config/env.rc)
[ -f "$HOME/.codex/load-env.sh" ] && . "$HOME/.codex/load-env.sh"
