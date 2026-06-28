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

if [[ "$failures" -eq 0 ]]; then
  echo "All tests passed."
  exit 0
fi
echo "$failures test(s) failed."
exit 1
