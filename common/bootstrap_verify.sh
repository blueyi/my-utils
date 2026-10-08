#!/usr/bin/env bash
# Completeness checks for bootstrap tools (sourced by bootstrap.sh).
# Return 0 = tool looks complete (safe to stamp-skip); 1 = need (re)run.

# Requires: MY_UTILS_ROOT or COMMON set; platform.sh optionally already sourced.

_bv_common() {
  if [ -n "${COMMON:-}" ]; then
    echo "$COMMON"
  elif [ -n "${MY_UTILS_ROOT:-}" ]; then
    echo "$MY_UTILS_ROOT/common"
  else
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
}

_bv_source_platform() {
  local c
  c="$(_bv_common)"
  # shellcheck source=/dev/null
  [ -f "$c/platform.sh" ] && . "$c/platform.sh"
}

# True if dir is a usable git checkout (not a failed/partial clone).
_bv_git_ok() {
  local d="$1"
  [ -d "$d/.git" ] || return 1
  # Empty or broken clone often lacks HEAD
  [ -f "$d/.git/HEAD" ] || [ -f "$d/.git/refs/heads/master" ] || [ -f "$d/.git/refs/heads/main" ] || return 1
  return 0
}

packages_complete() {
  _bv_source_platform
  local c pm list_file line pkg
  c="$(_bv_common)"
  pm="$(detect_package_manager 2>/dev/null || echo unknown)"
  case "$pm" in
    apt)  list_file="$c/deb_app_list.ini" ;;
    yum)  list_file="$c/rpm_app_list.ini" ;;
    brew)
      # Brewfile path is covered by stamp hash; require brew + a few core formulae.
      command -v brew &>/dev/null || return 1
      brew list git &>/dev/null 2>/dev/null || return 1
      brew list zsh &>/dev/null 2>/dev/null || return 1
      return 0
      ;;
    *) return 1 ;;
  esac
  [ -f "$list_file" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    line="${line//$'\r'/}"
    [ -z "$line" ] && continue
    pkg=$(eval echo "$line")
    if [ "$pm" = apt ] && is_wsl 2>/dev/null; then
      case "$pkg" in linux-headers-*) continue ;; esac
    fi
    case "$pm" in
      apt) dpkg -s "$pkg" &>/dev/null || return 1 ;;
      yum) rpm -q "$pkg" &>/dev/null || return 1 ;;
    esac
  done < "$list_file"
  return 0
}

links_complete() {
  # Core entrypoints only; env.rc may appear later via vault restore.
  [ -L "$HOME/.shell_init.bash" ] && [ -e "$HOME/.shell_init.bash" ] || return 1
  [ -L "$HOME/.my-utils.env" ] && [ -e "$HOME/.my-utils.env" ] || return 1
  return 0
}

misc_complete() {
  local custom
  command -v git &>/dev/null || return 1
  [ -d "$HOME/.oh-my-zsh" ] || return 1
  custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  _bv_git_ok "$custom/plugins/zsh-autosuggestions" || return 1
  _bv_git_ok "$custom/plugins/zsh-syntax-highlighting" || return 1
  _bv_git_ok "$custom/themes/powerlevel10k" || return 1
  command -v uv &>/dev/null || return 1
  return 0
}

vimrc_complete() {
  [ -f "$HOME/.vim/autoload/plug.vim" ] || return 1
  return 0
}

cursor_complete() {
  local bak
  bak="${MY_UTILS_ROOT:-}/cursor_bak"
  [ -d "$bak/User" ] || return 1
  return 0
}

env_complete() {
  local root
  root="${MY_UTILS_ROOT:-}"
  [ -n "$root" ] || return 1
  [ -f "$root/config/env.rc" ] || return 1
  [ -L "$HOME/.env.rc" ] || [ -f "$HOME/.env.rc" ] || return 1
  return 0
}

hexo_complete() {
  command -v node &>/dev/null || return 1
  command -v hexo &>/dev/null || return 1
  return 0
}

# Dispatch: 0 = complete
tool_is_complete() {
  case "$1" in
    packages)      packages_complete ;;
    links)         links_complete ;;
    misc)          misc_complete ;;
    vimrc)         vimrc_complete ;;
    cursor)        cursor_complete ;;
    env|vault-restore) env_complete ;;
    hexo)          hexo_complete ;;
    vault-backup)  return 0 ;;
    *)             return 1 ;;
  esac
}
