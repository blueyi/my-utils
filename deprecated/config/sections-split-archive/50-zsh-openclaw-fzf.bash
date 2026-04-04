# Section: zsh-only — OpenClaw completions + fzf key bindings
# When sourced from bash or Fish emit, ZSH_VERSION is unset; this block is skipped.
if [ -n "${ZSH_VERSION:-}" ]; then
  if _is_macos; then
    if ! type compinit >/dev/null 2>&1; then
      autoload -Uz compinit
      compinit
    fi
    if ! type bashcompinit >/dev/null 2>&1; then
      autoload -Uz bashcompinit
      bashcompinit
    fi
    [ -f "$HOME/.openclaw/completions/openclaw.zsh" ] && source "$HOME/.openclaw/completions/openclaw.zsh"
  elif _is_linux; then
    _oc_comp="$HOME/.npm-global/lib/node_modules/openclaw/completons/openclaw.zsh"
    [ -f "$_oc_comp" ] && source "$_oc_comp"
    unset _oc_comp
  fi
  if _is_linux; then
    [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && . /usr/share/doc/fzf/examples/key-bindings.zsh
    [ -f /usr/share/doc/fzf/examples/completion.zsh ] && . /usr/share/doc/fzf/examples/completion.zsh
  elif _is_macos; then
    _fzf_prefix=""
    command -v brew >/dev/null 2>&1 && _fzf_prefix="$(brew --prefix fzf 2>/dev/null)"
    [ -n "$_fzf_prefix" ] && [ -f "$_fzf_prefix/shell/key-bindings.zsh" ] && . "$_fzf_prefix/shell/key-bindings.zsh"
    [ -n "$_fzf_prefix" ] && [ -f "$_fzf_prefix/shell/completion.zsh" ] && . "$_fzf_prefix/shell/completion.zsh"
    unset _fzf_prefix
  fi
fi
