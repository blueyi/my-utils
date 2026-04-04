# shell_init.bash — single entry from ~/.bashrc / ~/.zshrc (symlink ~/.shell_init.bash → this file)
# Optional Fish: see link.ini (commented) + config/fish/my-utils.fish.
# Loads ~/.my-utils.env, then dispatches: zsh → zsh_entry; bash → bash_interactive + resetrc + optional_home.

[ -f "$HOME/.my-utils.env" ] && . "$HOME/.my-utils.env"
[ -z "${MYRC_PATH:-}" ] && [ -n "${MY_UTILS_ROOT:-}" ] && MYRC_PATH="${MY_UTILS_ROOT}/config"
if [ -z "${MYRC_PATH:-}" ] || [ ! -d "$MYRC_PATH" ]; then
  echo "my-utils: MYRC_PATH missing; run: ./bootstrap.sh --yes (or --tools links)" >&2
  return 0 2>/dev/null || exit 0
fi

if [ -n "${ZSH_VERSION:-}" ]; then
  [ -f "$MYRC_PATH/zsh_entry.zsh" ] && . "$MYRC_PATH/zsh_entry.zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
  [ -f "$MYRC_PATH/bash_interactive.bash" ] && . "$MYRC_PATH/bash_interactive.bash"
  [ -f "$MYRC_PATH/resetrc.bash" ] && . "$MYRC_PATH/resetrc.bash"
  [ -f "$MYRC_PATH/optional_home.bash" ] && . "$MYRC_PATH/optional_home.bash"
else
  [ -f "$MYRC_PATH/resetrc.bash" ] && . "$MYRC_PATH/resetrc.bash"
fi
