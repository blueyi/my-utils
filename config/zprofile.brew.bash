# Homebrew in login shells (macOS). Appended to ~/.zprofile / ~/.bash_profile by misc.sh.
# Do not source this file from interactive rc alone — resetrc already sets brew PATH.
# Marker-managed block: # >>> my-utils brew >>> … # <<< my-utils brew <<<

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
