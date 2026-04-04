# cmake_env.bash — forwards to resetrc.bash (see SECTION: markers there).
[ -f "$HOME/.my-utils.env" ] && . "$HOME/.my-utils.env"
: "${MYRC_PATH:=${MY_UTILS_ROOT}/config}"
[ -f "$MYRC_PATH/resetrc.bash" ] && . "$MYRC_PATH/resetrc.bash"
