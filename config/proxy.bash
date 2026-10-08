# >>> proxy setting >>>
# Shell-only env proxies (http_proxy / HTTPS_PROXY). Do not write /etc/apt or other
# system files — keep privilege surface in $HOME / current session only.
#
# Multi-device (shared my-utils repo):
#   - Do NOT hardcode a machine-specific host/IP here.
#   - WSL → Windows host (Clash Verge mixed-port) via default gateway.
#   - Native Linux/macOS → 127.0.0.1 (local Clash / ClashX / …).
#   - Per-machine overrides in config/env.rc (→ ~/.env.rc via link.ini; loaded first):
#       export MY_UTILS_PROXY=on                  # REQUIRED to auto-enable (default: off)
#       export PROXY_IP=http://192.168.x.x:7890   # full URL wins
#       export MY_UTILS_PROXY_HOST=172.28.112.1   # WSL host override
#       export MY_UTILS_PROXY_PORT=7897           # port only (default 7897)
#   - Manual anytime: `proxy` / `noproxy` (functions always available).

_my_utils_is_wsl() {
  [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
  [ -n "${WSL_INTEROP:-}" ] && return 0
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && return 0
  return 1
}

# Windows host IP as seen from WSL2. Prefer default gateway — resolv.conf may be
# Tailscale DNS (100.x) and is not the Clash listener.
_my_utils_wsl_windows_host() {
  ip route show default 2>/dev/null | awk '{print $3; exit}'
}

: "${MY_UTILS_PROXY_PORT:=7897}"

# Resolve PROXY_IP only if not already set (e.g. in ~/.env.rc).
if [ -z "${PROXY_IP:-}" ]; then
  if _my_utils_is_wsl; then
    _proxy_host="${MY_UTILS_PROXY_HOST:-$(_my_utils_wsl_windows_host)}"
    if [ -n "${_proxy_host}" ]; then
      PROXY_IP="http://${_proxy_host}:${MY_UTILS_PROXY_PORT}"
    else
      PROXY_IP="http://127.0.0.1:${MY_UTILS_PROXY_PORT}"
    fi
    unset _proxy_host
  else
    # Native Linux / macOS: local proxy client
    _proxy_host="${MY_UTILS_PROXY_HOST:-127.0.0.1}"
    PROXY_IP="http://${_proxy_host}:${MY_UTILS_PROXY_PORT}"
    unset _proxy_host
  fi
fi

# Accept host:port without scheme
case "${PROXY_IP}" in
  http://*|https://*|socks5://*|socks5h://*) ;;
  *) PROXY_IP="http://${PROXY_IP}" ;;
esac

# Extra NO_PROXY entries for WSL ↔ Windows host (avoid proxy loops / LAN noise)
_my_utils_no_proxy_base='127.0.0.1,localhost,local,.local,::1,172.28.0.0/16,.aliyun.com,.tencent.com,.huawei.com'
if _my_utils_is_wsl; then
  _wsl_host="${MY_UTILS_PROXY_HOST:-$(_my_utils_wsl_windows_host)}"
  if [ -n "${_wsl_host}" ]; then
    _my_utils_no_proxy_base="${_my_utils_no_proxy_base},${_wsl_host}"
  fi
  unset _wsl_host
fi

alias hp="http_proxy=$PROXY_IP https_proxy=$PROXY_IP"
proxy () {
        export ALL_PROXY="$PROXY_IP"
        export all_proxy="$PROXY_IP"
        export http_proxy="$PROXY_IP"
        export HTTP_PROXY="$PROXY_IP"
        export https_proxy="$PROXY_IP"
        export HTTPS_PROXY="$PROXY_IP"
        export no_proxy="${MY_UTILS_NO_PROXY:-$_my_utils_no_proxy_base}"
        export NO_PROXY="${MY_UTILS_NO_PROXY:-$_my_utils_no_proxy_base}"

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

# Opt-in auto-enable (quiet). Default off so new machines stay clean.
# Enable on a machine that needs it: export MY_UTILS_PROXY=on  # in config/env.rc
case "${MY_UTILS_PROXY:-off}" in
  on|ON|1|true|yes|YES) proxy -q ;;
  *) ;;
esac
