# >>> proxy setting >>>
# Shell-only env proxies (http_proxy / HTTPS_PROXY). Do not write /etc/apt or other
# system files — keep privilege surface in $HOME / current session only.

# PROXY_IP=192.168.3.25:1081
PROXY_IP=http://127.0.0.1:7897
# PROXY_IP=127.0.0.1:1081
# PROXY_IP=http://i.yulong.wang:1080
alias hp="http_proxy=$PROXY_IP https_proxy=$PROXY_IP"
proxy () {
        export ALL_PROXY="$PROXY_IP"
        export all_proxy="$PROXY_IP"
        export http_proxy="$PROXY_IP"
        export HTTP_PROXY="$PROXY_IP"
        export https_proxy="$PROXY_IP"
        export HTTPS_PROXY="$PROXY_IP"
        export no_proxy=127.0.0.1,localhost,local,.local,172.28.0.0/16,.aliyun.com,.tencent.com,.huawei.com
        export NO_PROXY=127.0.0.1,localhost,local,.local,172.28.0.0/16,.aliyun.com,.tencent.com,.huawei.com

        [ "${1-}" = "-q" ] || curl myip.ipip.net
        }

noproxy () {
        unset ALL_PROXY
        unset all_proxy
        unset http_proxy
        unset HTTP_PROXY
        unset https_proxy
        unset HTTPS_PROXY
        unset NO_PROXY 

        unset all_proxy
        unset http_proxy
        unset https_proxy
        unset no_proxy
        [ "${1-}" = "-q" ] || curl myip.ipip.net
        }

# Auto-enable when sourced (quiet: skip curl on shell startup).
# Disable on a single machine with: export MY_UTILS_PROXY=off  # in ~/.env.rc
case "${MY_UTILS_PROXY:-on}" in
  off|OFF|0|false|no|NO) ;;
  *) proxy -q ;;
esac
