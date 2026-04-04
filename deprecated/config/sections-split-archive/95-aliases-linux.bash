# Section: Linux-only aliases (personal paths — trim or move to optional_home if not yours)
if _is_linux; then
  alias wn='watch -n 1 nvidia-smi'
  alias ess='sudo service ssh start'
  [ -d "$HOME/soft/xdm-linux-portable-x64" ] && alias exdm="cd $HOME/soft/xdm-linux-portable-x64 && ./xdman"
  [ -f "$HOME/bin/clion/bin/clion.sh" ] && alias clion='sh $HOME/bin/clion/bin/clion.sh'
  [ -f "$HOME/soft/clash/clash.sh" ] && alias ecc="${HOME}/soft/clash/clash.sh"
  alias winetricks='env LANG=zh_CN.UTF-8 winetricks'
  alias wine='env LANG=zh_CN.UTF-8 wine'
  [ -f "$HOME/.wine/drive_c/Program Files (x86)/Tencent/WeChat/WeChat.exe" ] && alias wechat='env LANG=zh_CN.UTF-8 wine "'"$HOME"'/.wine/drive_c/Program Files (x86)/Tencent/WeChat/WeChat.exe"'
  [ -f "${MY_UTILS_ROOT}/bin/v2ray/Qv2ray-v2.7.0-linux-x64.AppImage" ] && alias ev2="${MY_UTILS_ROOT}/bin/v2ray/Qv2ray-v2.7.0-linux-x64.AppImage"
fi
