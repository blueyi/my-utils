# zsh_entry.zsh — Oh My Zsh + shared my-utils config (sourced from ~/.zshrc)
[ -f "$HOME/.my-utils.env" ] && . "$HOME/.my-utils.env"

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [ -d "$ZSH/custom/themes/powerlevel10k" ]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
  # Without ~/.p10k.zsh (e.g. before create_links), skip the interactive wizard.
  [[ ! -f "$HOME/.p10k.zsh" ]] && typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
else
  ZSH_THEME="robbyrussell"
fi
DISABLE_AUTO_UPDATE="true"
# zsh-syntax-highlighting must be last
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

[ -r "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"

[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

[ -n "${MYRC_PATH:-}" ] && [ -f "$MYRC_PATH/resetrc.bash" ] && . "$MYRC_PATH/resetrc.bash"
[ -n "${MYRC_PATH:-}" ] && [ -f "$MYRC_PATH/optional_home.bash" ] && . "$MYRC_PATH/optional_home.bash"
