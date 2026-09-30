# p10k-ide-overrides.zsh — Powerlevel10k tweaks for Cursor / VS Code terminals.
#
# Problem: xterm.js often fails to erase multiline / transient prompt redraws,
# so async gitstatus / time / transient-trim leave stacked ghost "╭─ ..." lines.
#
# Loaded from zsh_entry.zsh after ~/.p10k.zsh. Opt out: MYU_P10K_IDE_OVERRIDES=0
# Force on outside IDE: MYU_P10K_IDE_OVERRIDES=1

[[ -n ${ZSH_VERSION:-} ]] || return 0

# Already applied this session.
[[ -n ${MYU_P10K_IDE_OVERRIDES_APPLIED:-} ]] && return 0

_myu_p10k_ide_want() {
  case "${MYU_P10K_IDE_OVERRIDES:-}" in
    0|false|no|off) return 1 ;;
    1|true|yes|on)  return 0 ;;
  esac
  # Cursor / VS Code integrated terminal (and agent shells that inherit the same).
  [[ "${TERM_PROGRAM:-}" == vscode || "${TERM_PROGRAM:-}" == cursor ]] && return 0
  [[ -n ${VSCODE_INJECTION:-} || -n ${VSCODE_PID:-} ]] && return 0
  [[ -n ${CURSOR_TRACE_ID:-} || "${CURSOR_AGENT:-}" == 1 ]] && return 0
  return 1
}

_myu_p10k_ide_want || return 0

# Core: do not rewrite accepted prompts (biggest ghost-line source in IDE TTYs).
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Single-line left: avoid ╭─ / ╰─ two-row redraw height.
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
)

# Slim right: drop time (periodic refresh) and unused wizard segments / newline.
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  virtualenv
  anaconda
  context
)

# Clear multiline frame ornaments if still referenced elsewhere.
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

typeset -g MYU_P10K_IDE_OVERRIDES_APPLIED=1

# Apply immediately when p10k is already loaded.
(( $+functions[p10k] )) && p10k reload

unfunction _myu_p10k_ide_want 2>/dev/null
