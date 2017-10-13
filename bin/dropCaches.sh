#!/bin/sh

# sudo chmod a+x /lib/systemd/system-sleep/dropcaches
# Add to ~/.bashrc (or ~/.bash_aliases): alias susp='systemctl suspend -i
set -e

_cache() {
    free -m | awk '{if ($1 == "Mem:") print $6;}'
}

case $1 in
    pre)
        # systemctl stop daemond
        _before=$(_cache)
        sync && echo 3 > /proc/sys/vm/drop_caches
        _after=$(_cache)
        echo "Dropped $(($_before-$_after)) Mb of caches..."
        ;;
    post)
        # systemctl start daemond
        ;;
esac
