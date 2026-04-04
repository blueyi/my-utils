# Optional Fish: same exports as bash/zsh (resetrc + optional_home via emit script).
# Enable: install fish, uncomment link.ini Fish lines, run bootstrap links.

command -sq bash; or return
test -f ~/.my-utils.emit-fish-env.bash; or return

source (bash --noprofile --norc ~/.my-utils.emit-fish-env.bash | psub)
