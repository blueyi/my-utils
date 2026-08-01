#!/usr/bin/env bash
# Regression tests for git-dual-remote wrapper (bash + zsh compatible lib).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/common/git-dual-remote-lib.sh"
ENV="$ROOT/config/git-dual-remote.env"

failures=0
pass() { printf '  OK  %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }
assert_eq() {
  local got="$1" want="$2" msg="$3"
  [[ "$got" == "$want" ]] && pass "$msg" || fail "$msg (got='$got' want='$want')"
}
assert_ok() {
  local rc=$1 msg="$2"
  [[ "$rc" -eq 0 ]] && pass "$msg" || fail "$msg (exit $rc)"
}
assert_ne_ok() {
  local rc=$1 msg="$2"
  [[ "$rc" -ne 0 ]] && pass "$msg" || fail "$msg (expected non-zero, got $rc)"
}

setup_mock_git() {
  MOCK_DIR="$(mktemp -d)"
  MOCK_LOG="$MOCK_DIR/git.log"
  export MOCK_LOG
  cat >"$MOCK_DIR/git" <<'MOCK'
#!/usr/bin/env bash
echo "$*" >> "${MOCK_LOG}"
case "$1" in
  --version) echo "git version 2.43.0.mock"; exit 0 ;;
  rev-parse)
    if [[ "${2:-}" == "--is-inside-work-tree" ]]; then exit 128; fi
    exit 0 ;;
  clone)
    if [[ "$2" == *unreachable.test* ]]; then
      echo "ssh: Could not resolve hostname unreachable.test" >&2
      exit 255
    fi
    echo "Cloning into mock"; exit 0 ;;
  fetch|pull|push) echo "mock $*"; exit 0 ;;
  remote)
    if [[ "$2" == "get-url" ]]; then
      echo "git@github.com:blueyi/my-utils.git"
      exit 0
    fi
    exit 0 ;;
  *) echo "mock $*"; exit 0 ;;
esac
MOCK
  chmod +x "$MOCK_DIR/git"
  export PATH="$MOCK_DIR:$PATH"
}

teardown_mock_git() {
  [[ -n "${MOCK_DIR:-}" && -d "$MOCK_DIR" ]] && rm -rf "$MOCK_DIR"
}

load_lib() {
  unset _GIT_DUAL_REMOTE_LIB_LOADED
  # shellcheck source=/dev/null
  . "$ENV"
  # shellcheck source=/dev/null
  . "$LIB"
}

echo "=== URL helpers ==="
load_lib
assert_eq "$(git_dual_extract_namespace 'git@github.com:blueyi/foo.git')" "blueyi" "extract namespace ssh"
assert_eq "$(git_dual_to_gitcode_url 'git@github.com:blueyi/foo.git')" "git@gitcode.com:blueyi/foo.git" "github→gitcode"
assert_ne_ok "$(git_dual_url_is_mirrorable 'git@github.com:pyenv/pyenv.git'; echo $?)" "third-party not mirrorable"
assert_ok "$(git_dual_url_is_mirrorable 'git@github.com:blueyi/foo.git'; echo $?)" "own repo mirrorable"

echo "=== timeout wrapper (must not exec shell functions) ==="
setup_mock_git
load_lib
out="$(_git_dual_git_with_timeout 5 --version 2>&1)" || true
assert_ok "$?" "timeout --version exit 0"
[[ "$out" == *"2.43.0.mock"* ]] && pass "timeout runs real git binary" || fail "timeout runs real git binary (out=$out)"
last_line="$(tail -1 "$MOCK_LOG")"
[[ "$last_line" == "--version" ]] && pass "mock git received --version" || fail "mock git argv (line=$last_line)"
teardown_mock_git

echo "=== git_dual_fetch argument routing ==="
setup_mock_git
load_lib
git_dual_fetch --all >/dev/null
last_line="$(tail -1 "$MOCK_LOG")"
[[ "$last_line" == "fetch --all" ]] && pass "fetch --all passthrough" || fail "fetch --all passthrough (line=$last_line)"
: >"$MOCK_LOG"
git_dual_fetch origin --tags >/dev/null 2>&1 || true
# outside repo → direct passthrough
last_line="$(tail -1 "$MOCK_LOG")"
[[ "$last_line" == "fetch origin --tags" ]] && pass "fetch origin --tags passthrough outside repo" || fail "fetch origin --tags (line=$last_line)"
teardown_mock_git

echo "=== git_dual_pull fallback preserves original args ==="
setup_mock_git
load_lib
# Outside repo: must forward full original argv, not empty $@
git_dual_pull --rebase origin main >/dev/null 2>&1 || true
last_line="$(tail -1 "$MOCK_LOG")"
[[ "$last_line" == "pull --rebase origin main" ]] && pass "pull fallback preserves --rebase origin main" || fail "pull fallback (line=$last_line)"
teardown_mock_git

echo "=== git_dual_clone timeout path ==="
setup_mock_git
load_lib
GIT_DUAL_REMOTE_VERBOSE=0
git_dual_clone git@github.com:blueyi/unreachable.test.git /tmp/mock-clone-target --depth 1 >/dev/null 2>&1 || true
grep -q "clone git@github.com:blueyi/unreachable.test.git /tmp/mock-clone-target --depth 1" "$MOCK_LOG" && \
  pass "clone invokes git with full argv" || fail "clone argv missing in mock log"
teardown_mock_git

echo "=== git() wrapper dispatch ==="
setup_mock_git
load_lib
git() {
  case "${1:-}" in
    push) shift; git_dual_push "$@" ;;
    pull) shift; git_dual_pull "$@" ;;
    fetch) shift; git_dual_fetch "$@" ;;
    clone) shift; git_dual_clone "$@" ;;
    *) command git "$@" ;;
  esac
}
: >"$MOCK_LOG"
git status >/dev/null
[[ "$(tail -1 "$MOCK_LOG")" == "status" ]] && pass "wrapper passthrough status" || fail "wrapper passthrough status"
: >"$MOCK_LOG"
git fetch --all >/dev/null
[[ "$(tail -1 "$MOCK_LOG")" == "fetch --all" ]] && pass "wrapper fetch --all" || fail "wrapper fetch --all"
teardown_mock_git

echo "=== git_dual_push -u origin HEAD (regression) ==="
# -u takes no value; previously the parser swallowed "origin" and then treated the
# GitHub URL as a refspec → "error: src refspec git@github.com does not match any".
MOCK_DIR="$(mktemp -d)"
MOCK_LOG="$MOCK_DIR/git.log"
export MOCK_LOG
cat >"$MOCK_DIR/git" <<'MOCK'
#!/usr/bin/env bash
echo "$*" >> "${MOCK_LOG}"
case "$1" in
  rev-parse)
    case "${2:-}" in
      --is-inside-work-tree) exit 0 ;;
      --abbrev-ref)
        echo "master"; exit 0 ;;
      HEAD|master)
        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; exit 0 ;;
      *) exit 0 ;;
    esac
    ;;
  remote)
    if [[ "${2:-}" == "get-url" ]]; then
      if [[ "${3:-}" == "--push" ]]; then
        echo "git@github.com:blueyi/my-utils.git"
        echo "git@gitcode.com:blueyi/my-utils.git"
        exit 0
      fi
      if [[ "${3:-}" == "gitcode" ]]; then
        echo "git@gitcode.com:blueyi/my-utils.git"
        exit 0
      fi
      echo "git@github.com:blueyi/my-utils.git"
      exit 0
    fi
    exit 0 ;;
  update-ref|branch) exit 0 ;;
  push)
    # Fail if URL was mistaken for a refspec: `push -u origin <url> HEAD`
    for a in "$@"; do
      if [[ "$a" == git@github.com:* || "$a" == git@gitcode.com:* ]]; then
        # URL must appear as repository arg, not after a remote name + before HEAD only wrongly
        :
      fi
    done
    # Detect the historical bug: -u origin <url> HEAD
    if [[ "$*" == *"-u origin git@"* ]]; then
      echo "error: src refspec git@github.com does not match any" >&2
      exit 1
    fi
    # -u must not be passed to raw URL pushes
    if [[ "$*" == push\ -u\ git@* || "$*" == push\ --set-upstream\ git@* ]]; then
      echo "error: -u must not be passed to URL remotes" >&2
      exit 1
    fi
    echo "mock $*"; exit 0 ;;
  *) echo "mock $*"; exit 0 ;;
esac
MOCK
chmod +x "$MOCK_DIR/git"
export PATH="$MOCK_DIR:$PATH"
load_lib
GIT_DUAL_REMOTE_VERBOSE=0
: >"$MOCK_LOG"
git_dual_push -u origin HEAD >/dev/null 2>&1
assert_ok "$?" "push -u origin HEAD exits 0"
grep -q 'push git@github.com:blueyi/my-utils.git HEAD' "$MOCK_LOG" && \
  pass "push -u origin HEAD hits GitHub URL + HEAD" || \
  fail "push -u origin HEAD GitHub argv (log=$(tr '\n' '|' <"$MOCK_LOG"))"
grep -q 'push git@gitcode.com:blueyi/my-utils.git HEAD' "$MOCK_LOG" && \
  pass "push -u origin HEAD hits GitCode URL + HEAD" || \
  fail "push -u origin HEAD GitCode argv"
grep -Eq 'push -u origin git@|push --set-upstream origin git@' "$MOCK_LOG" && \
  fail "push -u must not swallow origin into opts" || \
  pass "push -u does not swallow origin"
grep -E 'update-ref refs/remotes/origin/master ' "$MOCK_LOG" >/dev/null && \
  pass "push syncs refs/remotes/origin/master" || \
  fail "push syncs tracking ref (log=$(tr '\n' '|' <"$MOCK_LOG"))"
grep -E 'branch --set-upstream-to=origin/master master' "$MOCK_LOG" >/dev/null && \
  pass "push -u sets upstream to origin/master" || \
  fail "push -u sets upstream (log=$(tr '\n' '|' <"$MOCK_LOG"))"
teardown_mock_git

echo "=== _git_dual_dst_branch_from_refspec ==="
load_lib
# Stub current branch for HEAD resolution
_git_dual_current_branch() { echo "feature-x"; }
assert_eq "$(_git_dual_dst_branch_from_refspec 'HEAD')" "feature-x" "HEAD → current branch"
assert_eq "$(_git_dual_dst_branch_from_refspec 'master')" "master" "master → master"
assert_eq "$(_git_dual_dst_branch_from_refspec 'HEAD:refs/heads/release')" "release" "HEAD:refs/heads/release"

if [[ "$failures" -eq 0 ]]; then
  echo "All tests passed."
  exit 0
fi
echo "$failures test(s) failed."
exit 1
