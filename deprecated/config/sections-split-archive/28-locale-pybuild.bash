# Section: locale (optional) + pyenv build defaults
# export LANG=zh_CN.UTF-8
_is_linux && export TERMINAL=gnome-terminal

export PYTHON_BUILD_MIRROR_URL="https://www.python.org/ftp/python/"
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHON_CONFIGURE_OPTS="--enable-shared"
