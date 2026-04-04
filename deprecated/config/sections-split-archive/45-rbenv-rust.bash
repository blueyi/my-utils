# Section: rbenv + Rust (rustup)
case ":$PATH:" in *":$HOME/.rbenv/bin:"*) ;; *) export PATH="$HOME/.rbenv/bin:$PATH";; esac
command -v rbenv >/dev/null && eval "$(rbenv init - 2>/dev/null)" || true

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d /opt/homebrew/opt/rustup/bin ] && case ":$PATH:" in *":/opt/homebrew/opt/rustup/bin:"*) ;; *) export PATH="/opt/homebrew/opt/rustup/bin:$PATH";; esac
[ -d /usr/local/opt/rustup/bin ] && case ":$PATH:" in *":/usr/local/opt/rustup/bin:"*) ;; *) export PATH="/usr/local/opt/rustup/bin:$PATH";; esac
