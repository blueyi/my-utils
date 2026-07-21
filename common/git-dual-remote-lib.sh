#!/usr/bin/env bash
# git-dual-remote-lib.sh — GitHub + GitCode mirror helpers (source only, do not execute).
#
# Provides:
#   git_dual_remote_enabled, git_dual_extract_namespace, git_dual_url_is_mirrorable
#   git_dual_to_gitcode_url, git_dual_to_github_url
#   git_dual_ensure_remotes, git_dual_push, git_dual_pull, git_dual_fetch
#
# Env (see config/git-dual-remote.env):
#   GIT_DUAL_REMOTE_ENABLED, GIT_DUAL_REMOTE_GITHUB_USER, GIT_DUAL_REMOTE_GITCODE_USER
#   GIT_DUAL_REMOTE_TIMEOUT, GIT_DUAL_REMOTE_FALLBACK_REMOTE, GIT_DUAL_REMOTE_VERBOSE
# Bypass wrapper: GIT_DUAL_REMOTE=0 command git push ...

[[ -n "${_GIT_DUAL_REMOTE_LIB_LOADED:-}" ]] && return 0
_GIT_DUAL_REMOTE_LIB_LOADED=1

_git_dual_real() {
  command git "$@"
}

# Run real git under timeout(1) / background watchdog (never pass shell function names).
_git_dual_git_with_timeout() {
  local secs="$1"
  shift
  _git_dual_run_with_timeout "$secs" "$@"
}

_git_dual_verbose() {
  [[ "${GIT_DUAL_REMOTE_VERBOSE:-}" == 1 ]] || return 0
  printf 'git-dual-remote: %s\n' "$*" >&2
}

git_dual_remote_enabled() {
  [[ "${GIT_DUAL_REMOTE:-${GIT_DUAL_REMOTE_ENABLED:-}}" != 0 && \
     "${GIT_DUAL_REMOTE:-${GIT_DUAL_REMOTE_ENABLED:-}}" != false ]]
}

# --- URL helpers (bash + zsh; no BASH_REMATCH) ---

_git_dual_strip_git_suffix() {
  local r="$1"
  r="${r%/}"
  r="${r%.git}"
  printf '%s.git' "$r"
}

# Owner/namespace from git@host:owner/repo or https://host/owner/repo
git_dual_extract_namespace() {
  local url="$1" repo owner
  url="${url#"${url%%[![:space:]]*}"}"
  url="${url%"${url##*[![:space:]]}"}"
  [[ -n "$url" ]] || return 1

  case "$url" in
    git@github.com:*|git@gitcode.com:*)
      repo="${url#git@github.com:}"
      repo="${repo#git@gitcode.com:}"
      owner="${repo%%/*}"
      [[ -n "$owner" && "$owner" != "$repo" ]] || return 1
      printf '%s' "$owner"
      return 0
      ;;
    https://github.com/*|http://github.com/*|https://gitcode.com/*|http://gitcode.com/*)
      repo="${url#*://github.com/}"
      repo="${repo#*://gitcode.com/}"
      owner="${repo%%/*}"
      [[ -n "$owner" && "$owner" != "$repo" ]] || return 1
      printf '%s' "$owner"
      return 0
      ;;
  esac
  return 1
}

# Only repos under our mirrored namespace (default: blueyi) get dual-remote setup.
# e.g. github.com/pyenv/pyenv → skip; github.com/blueyi/my-utils → mirror.
git_dual_url_is_mirrorable() {
  local url="$1" ns gh_user="${GIT_DUAL_REMOTE_GITHUB_USER:-}" gc_user="${GIT_DUAL_REMOTE_GITCODE_USER:-$gh_user}"
  [[ -n "$gh_user" ]] || return 1
  ns="$(git_dual_extract_namespace "$url" 2>/dev/null)" || return 1

  case "$url" in
    git@github.com:*|https://github.com/*|http://github.com/*)
      [[ "$ns" == "$gh_user" ]]
      ;;
    git@gitcode.com:*|https://gitcode.com/*|http://gitcode.com/*)
      [[ -n "$gc_user" && "$ns" == "$gc_user" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

git_dual_to_gitcode_url() {
  local url="$1" repo repo_name gc_user="${GIT_DUAL_REMOTE_GITCODE_USER:-${GIT_DUAL_REMOTE_GITHUB_USER:-}}"
  url="${url#"${url%%[![:space:]]*}"}"
  url="${url%"${url##*[![:space:]]}"}"
  [[ -n "$url" ]] || return 1

  case "$url" in
    git@github.com:*|https://github.com/*|http://github.com/*)
      git_dual_url_is_mirrorable "$url" || return 1
      ;;
    git@gitcode.com:*)
      printf '%s\n' "$url"
      return 0
      ;;
    *)
      return 1
      ;;
  esac

  case "$url" in
    git@github.com:*)
      repo="${url#git@github.com:}"
      repo_name="${repo#*/}"
      repo_name="$(_git_dual_strip_git_suffix "$repo_name")"
      printf 'git@gitcode.com:%s/%s\n' "$gc_user" "$repo_name"
      return 0
      ;;
    https://github.com/*|http://github.com/*)
      repo="${url#*://github.com/}"
      repo_name="${repo#*/}"
      repo_name="$(_git_dual_strip_git_suffix "$repo_name")"
      printf 'git@gitcode.com:%s/%s\n' "$gc_user" "$repo_name"
      return 0
      ;;
  esac
  return 1
}

git_dual_to_github_url() {
  local url="$1" repo repo_name gh_user="${GIT_DUAL_REMOTE_GITHUB_USER:-}"
  url="${url#"${url%%[![:space:]]*}"}"
  url="${url%"${url##*[![:space:]]}"}"
  [[ -n "$url" ]] || return 1

  case "$url" in
    git@gitcode.com:*|https://gitcode.com/*|http://gitcode.com/*)
      git_dual_url_is_mirrorable "$url" || return 1
      ;;
    git@github.com:*)
      printf '%s\n' "$url"
      return 0
      ;;
    *)
      return 1
      ;;
  esac

  case "$url" in
    git@gitcode.com:*)
      repo="${url#git@gitcode.com:}"
      repo_name="${repo#*/}"
      repo_name="$(_git_dual_strip_git_suffix "$repo_name")"
      printf 'git@github.com:%s/%s\n' "$gh_user" "$repo_name"
      return 0
      ;;
    https://gitcode.com/*|http://gitcode.com/*)
      repo="${url#*://gitcode.com/}"
      repo_name="${repo#*/}"
      repo_name="$(_git_dual_strip_git_suffix "$repo_name")"
      printf 'git@github.com:%s/%s\n' "$gh_user" "$repo_name"
      return 0
      ;;
  esac
  return 1
}

git_dual_primary_fetch_url() {
  local url="$1"
  git_dual_to_github_url "$url" || git_dual_to_gitcode_url "$url" || printf '%s\n' "$url"
}

# --- Timeout / SSH ---

_git_dual_timeout_secs() {
  local t="${GIT_DUAL_REMOTE_TIMEOUT:-20}"
  [[ "$t" =~ ^[0-9]+$ ]] && [[ "$t" -gt 0 ]] || t=20
  printf '%s' "$t"
}

_git_dual_ssh_opts() {
  local t
  t="$(_git_dual_timeout_secs)"
  printf 'ssh -o BatchMode=yes -o ConnectTimeout=%s -o ConnectionAttempts=1 -o ServerAliveInterval=5 -o ServerAliveCountMax=2' "$t"
}

_git_dual_export_ssh() {
  local base="${GIT_SSH_COMMAND:-}"
  local opts
  opts="$(_git_dual_ssh_opts)"
  if [[ -z "$base" ]]; then
    export GIT_SSH_COMMAND="$opts"
  elif [[ "$base" != *ConnectTimeout=* ]]; then
    export GIT_SSH_COMMAND="$opts $base"
  fi
}

# GNU timeout exec()s argv[0]; shell functions are not executable — use bash -c + command git.
_git_dual_run_with_timeout() {
  local secs="$1"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" bash -c 'command git "$@"' _ "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" bash -c 'command git "$@"' _ "$@"
    return $?
  fi
  # macOS without GNU coreutils
  (
    command git "$@" &
    local pid=$!
    local timer_pid
    ( sleep "$secs"; kill -TERM "$pid" 2>/dev/null ) &
    timer_pid=$!
    wait "$pid" 2>/dev/null
    local st=$?
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      return 124
    fi
    return "$st"
  )
}

_git_dual_is_timeout_or_unreachable() {
  local out="$1" code="${2:-1}"
  [[ "$code" -eq 124 ]] && return 0
  [[ "$code" -eq 143 ]] && return 0   # SIGTERM (e.g. timeout helper on macOS)
  [[ "$code" -eq 137 ]] && return 0   # SIGKILL
  [[ "$code" -eq 255 ]] && return 0
  [[ "$out" == *"timed out"* || "$out" == *"Timeout"* || "$out" == *"Could not resolve"* || \
     "$out" == *"Connection refused"* || "$out" == *"Network is unreachable"* || \
     "$out" == *"Operation timed out"* || "$out" == *"Connection reset"* || \
     "$out" == *"No route to host"* ]] && return 0
  return 1
}

# Clone fallback: unreachable OR repo missing on the preferred host.
_git_dual_should_try_alternate_clone() {
  local out="$1" code="${2:-1}"
  _git_dual_is_timeout_or_unreachable "$out" "$code" && return 0
  [[ "$out" == *"Repository not found"* || "$out" == *"repository not found"* || \
     "$out" == *"does not exist"* || "$out" == *"Could not read from remote repository"* ]] && return 0
  return 1
}

_git_dual_url_is_gitcode() {
  case "$1" in
    git@gitcode.com:*|https://gitcode.com/*|http://gitcode.com/*) return 0 ;;
  esac
  return 1
}

_git_dual_url_is_github() {
  case "$1" in
    git@github.com:*|https://github.com/*|http://github.com/*) return 0 ;;
  esac
  return 1
}

# Remove incomplete clone target before retry (git leaves an empty dir on failure).
_git_dual_cleanup_failed_clone_target() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" && ! -d "$dir/.git" ]] || return 0
  rm -rf "$dir"
}

_git_dual_capture() {
  local out rc
  out="$("$@" 2>&1)"
  rc=$?
  printf '%s' "$out"
  return "$rc"
}

# --- Repo detection ---

git_dual_in_repo() {
  _git_dual_real rev-parse --is-inside-work-tree &>/dev/null
}

git_dual_repo_root() {
  _git_dual_real rev-parse --show-toplevel 2>/dev/null
}

# --- Remote setup ---

git_dual_ensure_remotes() {
  local remote="${1:-origin}"
  local fetch_url github_url gitcode_url
  local fetch_is_github=0 fetch_is_gitcode=0

  git_dual_in_repo || return 1
  fetch_url="$(_git_dual_real remote get-url "$remote" 2>/dev/null)" || return 1

  _git_dual_url_is_github "$fetch_url" && fetch_is_github=1
  _git_dual_url_is_gitcode "$fetch_url" && fetch_is_gitcode=1

  if ! git_dual_url_is_mirrorable "$fetch_url"; then
    local owner="${GIT_DUAL_REMOTE_GITHUB_USER:-blueyi}"
    local ns
    ns="$(git_dual_extract_namespace "$fetch_url" 2>/dev/null || echo unknown)"
    _git_dual_verbose "skip $remote: namespace '$ns' is not mirrored (expected $owner)"
    return 1
  fi

  github_url="$(git_dual_to_github_url "$fetch_url" 2>/dev/null || true)"
  gitcode_url="$(git_dual_to_gitcode_url "$fetch_url" 2>/dev/null || true)"

  if [[ -z "$github_url" && -z "$gitcode_url" ]]; then
    _git_dual_verbose "skip $remote: not a GitHub/GitCode repo ($fetch_url)"
    return 1
  fi

  [[ -n "$github_url" ]] || github_url="$fetch_url"
  [[ -n "$gitcode_url" ]] || gitcode_url="$(git_dual_to_gitcode_url "$github_url")" || return 1

  # Fetch URL: GitHub when origin is GitHub; keep GitCode when cloned from GitCode only.
  if (( fetch_is_github )); then
    if [[ "$fetch_url" != "$github_url" ]]; then
      _git_dual_real remote set-url "$remote" "$github_url"
      _git_dual_verbose "set $remote fetch → $github_url"
    fi
  elif (( fetch_is_gitcode )); then
    if [[ -n "$gitcode_url" && "$fetch_url" != "$gitcode_url" ]]; then
      _git_dual_real remote set-url "$remote" "$gitcode_url"
      _git_dual_verbose "set $remote fetch → $gitcode_url"
    fi
  fi

  # Dual push URLs.
  local -a push_urls=()
  local u
  while IFS= read -r u; do
    [[ -n "$u" ]] && push_urls+=("$u")
  done < <(_git_dual_real remote get-url --push --all "$remote" 2>/dev/null || true)

  local need_gh=1 need_gc=1
  for u in "${push_urls[@]}"; do
    [[ "$u" == "$github_url" ]] && need_gh=0
    [[ "$u" == "$gitcode_url" ]] && need_gc=0
  done

  if ((${#push_urls[@]} == 0)); then
    _git_dual_real remote set-url --push "$remote" "$github_url"
    push_urls=("$github_url")
    need_gh=0
  fi
  if ((need_gh)); then
    _git_dual_real remote set-url --add --push "$remote" "$github_url"
    _git_dual_verbose "add $remote push → $github_url"
  fi
  if ((need_gc)); then
    _git_dual_real remote set-url --add --push "$remote" "$gitcode_url"
    _git_dual_verbose "add $remote push → $gitcode_url"
  fi

  # Fallback remote for fetch/pull when primary host is GitHub (GitHub down → gitcode).
  local fb="${GIT_DUAL_REMOTE_FALLBACK_REMOTE:-gitcode}"
  if (( fetch_is_github )); then
    if _git_dual_real remote get-url "$fb" &>/dev/null; then
      local cur_fb
      cur_fb="$(_git_dual_real remote get-url "$fb" 2>/dev/null)"
      [[ "$cur_fb" != "$gitcode_url" ]] && _git_dual_real remote set-url "$fb" "$gitcode_url"
    else
      _git_dual_real remote add "$fb" "$gitcode_url"
      _git_dual_verbose "add remote $fb → $gitcode_url"
    fi
  fi

  return 0
}

# --- Remote operations ---

_git_dual_current_branch() {
  _git_dual_real rev-parse --abbrev-ref HEAD 2>/dev/null
}

_git_dual_resolve_remote_branch() {
  local remote="$1" branch="$2"
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    branch="$(_git_dual_current_branch)"
  fi
  printf '%s' "$branch"
}

git_dual_fetch() {
  local -a _saved_args=("$@")
  local remote="" rest=()

  # git fetch --all / git fetch (no remote) — pass through unchanged.
  if ((${#_saved_args[@]} == 0)) || [[ "${_saved_args[0]}" == -* ]]; then
    _git_dual_real fetch "${_saved_args[@]}"
    return $?
  fi

  remote="${_saved_args[0]}"
  rest=("${_saved_args[@]:1}")

  local secs out rc fb

  git_dual_in_repo || { _git_dual_real fetch "${_saved_args[@]}"; return $?; }
  git_dual_ensure_remotes "$remote" || { _git_dual_real fetch "${_saved_args[@]}"; return $?; }

  _git_dual_export_ssh
  secs="$(_git_dual_timeout_secs)"
  fb="${GIT_DUAL_REMOTE_FALLBACK_REMOTE:-gitcode}"

  out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" fetch "$remote" "${rest[@]}")"
  rc=$?
  if [[ "$rc" -eq 0 ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  printf '%s\n' "$out" >&2

  if ! _git_dual_is_timeout_or_unreachable "$out" "$rc"; then
    return "$rc"
  fi

  _git_dual_verbose "fetch $remote timed out; trying $fb ..."
  out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" fetch "$fb" "${rest[@]}")"
  rc=$?
  printf '%s\n' "$out"
  [[ "$rc" -eq 0 ]] && _git_dual_verbose "fetch OK via $fb"
  return "$rc"
}

git_dual_pull() {
  local -a _saved_args=("$@")
  local remote="" branch="" extra=() use_rebase=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --rebase) use_rebase=1; extra+=("$1"); shift ;;
      --no-rebase) use_rebase=0; extra+=("$1"); shift ;;
      --ff-only|--no-ff|--verify-signatures|--autostash) extra+=("$1"); shift ;;
      -r) use_rebase=1; extra+=("$1"); shift ;;
      --*) extra+=("$1"); shift ;;
      *)
        if [[ -z "$remote" ]]; then
          remote="$1"
        elif [[ -z "$branch" ]]; then
          branch="$1"
        else
          extra+=("$1")
        fi
        shift
        ;;
    esac
  done

  remote="${remote:-origin}"
  branch="$(_git_dual_resolve_remote_branch "$remote" "$branch")"
  local secs out rc fb

  git_dual_in_repo || { _git_dual_real pull "${_saved_args[@]}"; return $?; }
  git_dual_ensure_remotes "$remote" || { _git_dual_real pull "${_saved_args[@]}"; return $?; }

  _git_dual_export_ssh
  secs="$(_git_dual_timeout_secs)"
  fb="${GIT_DUAL_REMOTE_FALLBACK_REMOTE:-gitcode}"

  if ((${#extra[@]})); then
    out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" pull "${extra[@]}" "$remote" ${branch:+"$branch"})"
  else
    out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" pull "$remote" ${branch:+"$branch"})"
  fi
  rc=$?
  if [[ "$rc" -eq 0 ]]; then
    printf '%s\n' "$out"
    return 0
  fi
  printf '%s\n' "$out" >&2

  if ! _git_dual_is_timeout_or_unreachable "$out" "$rc"; then
    return "$rc"
  fi

  _git_dual_verbose "pull $remote timed out; fetch + merge via $fb ..."
  out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" fetch "$fb" "$branch")"
  rc=$?
  printf '%s\n' "$out"
  [[ "$rc" -ne 0 ]] && return "$rc"

  if ((use_rebase)); then
    out="$(_git_dual_capture _git_dual_real rebase "$fb/$branch")"
  else
    out="$(_git_dual_capture _git_dual_real merge "$fb/$branch")"
  fi
  rc=$?
  printf '%s\n' "$out"
  [[ "$rc" -eq 0 ]] && _git_dual_verbose "pull OK via $fb/$branch"
  return "$rc"
}

git_dual_push() {
  local -a _saved_args=("$@")

  if ! git_dual_in_repo; then
    _git_dual_real push "${_saved_args[@]}"
    return $?
  fi

  local remote="" saw_remote=0
  local -a opts=() refs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      origin)
        remote="origin"
        saw_remote=1
        shift
        ;;
      gitcode|upstream)
        _git_dual_real push "${_saved_args[@]}"
        return $?
        ;;
      --all|--tags|--dry-run|-n)
        opts+=("$1")
        shift
        ;;
      -u|--set-upstream)
        opts+=("$1")
        shift
        [[ $# -gt 0 && "$1" != --* ]] && { opts+=("$1"); shift; }
        ;;
      --force|-f|--force-with-lease|--no-force-with-lease|--no-verify|--porcelain|--quiet|-q)
        opts+=("$1")
        shift
        ;;
      --*)
        opts+=("$1")
        shift
        [[ $# -gt 0 && "$1" != --* ]] && { opts+=("$1"); shift; }
        ;;
      *)
        refs+=("$1")
        shift
        ;;
    esac
  done

  if (( saw_remote )) && [[ "$remote" != "origin" ]]; then
    _git_dual_real push "${_saved_args[@]}"
    return $?
  fi

  remote="${remote:-origin}"
  git_dual_ensure_remotes "$remote" || { _git_dual_real push "${_saved_args[@]}"; return $?; }

  _git_dual_export_ssh
  local secs out rc github_url gitcode_url fb gh_ok=0 gc_ok=0
  secs="$(_git_dual_timeout_secs)"
  fb="${GIT_DUAL_REMOTE_FALLBACK_REMOTE:-gitcode}"

  local fetch_url
  fetch_url="$(_git_dual_real remote get-url "$remote" 2>/dev/null)" || fetch_url=""
  github_url="$(git_dual_to_github_url "$fetch_url" 2>/dev/null || echo "$fetch_url")"
  gitcode_url="$(_git_dual_real remote get-url "$fb" 2>/dev/null || git_dual_to_gitcode_url "$github_url" 2>/dev/null || true)"

  # Bare `git push` — use upstream when no refs given.
  if ((${#refs[@]} == 0)); then
    _git_dual_real push "${opts[@]}" "$remote"
    return $?
  fi

  # Push GitHub first (best-effort), then GitCode mirror.
  if [[ -n "$github_url" ]]; then
    out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" push "${opts[@]}" "$github_url" "${refs[@]}")"
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      gh_ok=1
      printf '%s\n' "$out"
    else
      printf '%s\n' "$out" >&2
      _git_dual_verbose "push to GitHub failed (exit $rc); will still try $fb"
    fi
  fi

  if [[ -n "$gitcode_url" ]]; then
    out="$(_git_dual_capture _git_dual_git_with_timeout "$secs" push "${opts[@]}" "$gitcode_url" "${refs[@]}")"
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      gc_ok=1
      printf '%s\n' "$out"
      _git_dual_verbose "push OK via GitCode"
    else
      printf '%s\n' "$out" >&2
    fi
  else
    rc=1
  fi

  if ((gc_ok)); then
    ((gh_ok)) || _git_dual_verbose "GitHub unreachable; GitCode push succeeded"
    return 0
  fi
  if ((gh_ok)); then
    return 0
  fi
  return "${rc:-1}"
}

git_dual_clone() {
  local url="" target="" args=() post_setup=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-dual-remote-setup) post_setup=0; shift ;;
      --) shift; args+=("$@"); break ;;
      *)
        if [[ -z "$url" ]]; then
          url="$1"
        elif [[ -z "$target" ]]; then
          target="$1"
        else
          args+=("$1")
        fi
        shift
        ;;
    esac
  done

  local rc clone_url github_url gitcode_url mirrorable=0 alt_url=""

  _git_dual_export_ssh
  git_dual_url_is_mirrorable "$url" && mirrorable=1
  gitcode_url="$(git_dual_to_gitcode_url "$url" 2>/dev/null || true)"
  github_url="$(git_dual_to_github_url "$url" 2>/dev/null || true)"

  # Clone from the host the user specified.
  if _git_dual_url_is_gitcode "$url"; then
    clone_url="${gitcode_url:-$url}"
  elif _git_dual_url_is_github "$url"; then
    clone_url="${github_url:-$url}"
  else
    clone_url="${github_url:-$url}"
  fi

  if [[ -n "$target" ]]; then
    _git_dual_real clone "$clone_url" "$target" "${args[@]}"
  else
    _git_dual_real clone "$clone_url" "${args[@]}"
  fi
  rc=$?

  # Fallback to the other mirror host (no wall-clock timeout on clone).
  if [[ "$rc" -ne 0 ]] && (( mirrorable )); then
    if [[ "$clone_url" == "$github_url" && -n "$gitcode_url" && "$gitcode_url" != "$clone_url" ]]; then
      alt_url="$gitcode_url"
      _git_dual_verbose "clone from GitHub failed; trying GitCode ..."
    elif [[ "$clone_url" == "$gitcode_url" && -n "$github_url" && "$github_url" != "$clone_url" ]]; then
      alt_url="$github_url"
      _git_dual_verbose "clone from GitCode failed; trying GitHub ..."
    fi
    if [[ -n "$alt_url" ]]; then
      _git_dual_cleanup_failed_clone_target "$target"
      if [[ -n "$target" ]]; then
        _git_dual_real clone "$alt_url" "$target" "${args[@]}"
      else
        _git_dual_real clone "$alt_url" "${args[@]}"
      fi
      rc=$?
    fi
  fi

  [[ "$rc" -ne 0 ]] && return "$rc"
  ((post_setup)) || return 0

  local root="$target"
  if [[ -z "$root" ]]; then
    root="$(basename "${url%/}")"
    root="${root%.git}"
  fi
  if (( mirrorable )) && [[ -d "$root/.git" ]]; then
    ( cd "$root" && git_dual_ensure_remotes origin ) || true
  fi
  return 0
}
