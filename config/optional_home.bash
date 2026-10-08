# optional_home.bash — optional snippets under $HOME (not in repo); bash/zsh safe
# Hermes keys: ~/.hermes/.env (private git). Machine knobs: config/env.rc.
[ -f "$HOME/claude_conf.bash" ] && . "$HOME/claude_conf.bash"
[ -f "$HOME/github.bash" ] && . "$HOME/github.bash"
[ -d "$HOME/.openclaw/bin" ] && case ":${PATH:-}:" in *":$HOME/.openclaw/bin:"*) ;; *) export PATH="$HOME/.openclaw/bin:$PATH";; esac

# Codex helper PATH / extras (optional)
[ -f "$HOME/.codex/load-env.sh" ] && . "$HOME/.codex/load-env.sh"
