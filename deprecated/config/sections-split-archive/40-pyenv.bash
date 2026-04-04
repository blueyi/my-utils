# Section: pyenv + virtualenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && case ":$PATH:" in *":$PYENV_ROOT/bin:"*) ;; *) export PATH="$PYENV_ROOT/bin:$PATH";; esac
command -v pyenv >/dev/null && eval "$(pyenv init -)" || true
eval "$(pyenv virtualenv-init -)" || true
