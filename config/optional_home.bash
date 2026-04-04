# optional_home.bash — optional snippets under $HOME (not in repo); bash/zsh safe
[ -f "$HOME/claude_conf.bash" ] && . "$HOME/claude_conf.bash"
[ -f "$HOME/github.bash" ] && . "$HOME/github.bash"
[ -d "$HOME/.openclaw/bin" ] && case ":${PATH:-}:" in *":$HOME/.openclaw/bin:"*) ;; *) export PATH="$HOME/.openclaw/bin:$PATH";; esac
