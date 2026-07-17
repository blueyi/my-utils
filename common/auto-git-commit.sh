#!/bin/bash
# Auto Git Commit: backup multiple directories via git (add/commit/push).
# Add entries to BACKUP_DIRS below; run manually or via cron/launchd.
# Each directory must be a git repo; changes are committed and pushed to origin.
#
# Console: prints a short start/end summary to stderr (use AUTO_GIT_SILENT=1 for cron).
# Details always go to AUTO_GIT_LOG (default ~/workspace/auto-git-backup.log).
# Cron hourly example (crontab -e; use the real path to this script):
#   0 * * * * AUTO_GIT_SILENT=1 /bin/bash /home/you/workspace/my-utils/common/auto-git-commit.sh
#
# Multi-OS: to avoid different systems overwriting each other, use per-OS lists.
# Define BACKUP_DIRS_MACOS, BACKUP_DIRS_LINUX, and/or BACKUP_DIRS_WINDOWS; if set
# for current OS, that list is used; otherwise BACKUP_DIRS is used.
# WSL2 uses uname Linux and also matches common/platform.sh WSL probes below.

# --- Detect OS (macos, linux, windows) — WSL counts as linux ---
_detect_os() {
    case "$(uname -s)" in
        Darwin)   echo "macos" ;;
        Linux*)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)
            if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] \
                || grep -qi microsoft /proc/version 2>/dev/null; then
                echo "linux"
            else
                echo "unknown"
            fi
            ;;
    esac
}
BACKUP_OS="$(_detect_os)"

# --- Config: list of directories to auto backup (edit these) ---
# Format:
#   "path"          → back up whatever the current branch is.
#   "path:branch"   → ONLY back up when the current branch is `branch`. Skip
#                     otherwise. The script NEVER switches branches.
#
# Multiple entries with the same path but different branches express
# "back up this repo under different branches on different machines (or in
# different sessions)". Exactly one entry will match per host.
# Default list (used when no OS-specific list is set)
BACKUP_DIRS=(
    "$HOME/.openclaw:macos"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    # "$HOME/workspace/repos/kora:main"  # disabled: auto-backup breaks in-progress edits
    "$HOME/.hermes:macos"
)

# Optional: per-OS lists — same path can backup to different branches per OS
BACKUP_DIRS_MACOS=(
    "$HOME/.openclaw:macos"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    "$HOME/.hermes:macos"
)
BACKUP_DIRS_LINUX=(
    "$HOME/.openclaw:ucloud"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    # "$HOME/workspace/repos/kora:main"  # disabled: auto-backup breaks in-progress edits
    "$HOME/repos/my-utils:main"
    "$HOME/.openclaw:wsl"
    # ~/.hermes: Hermes home (config, optional secrets — keep remote private). wsl = GitCode branch.
    "$HOME/.hermes:wsl"
    # Optional second remote branch mirror (only if branch exists locally or on origin)
    "$HOME/.hermes:ucloud"
)
# BACKUP_DIRS_WINDOWS=(
#     "$HOME/workspace/my-utils:main-windows"
#     "$HOME/.openclaw"
# )

# Apply OS-specific list if defined (declare -p works on bash 3.x e.g. macOS)
case "$BACKUP_OS" in
    macos)   declare -p BACKUP_DIRS_MACOS   &>/dev/null && BACKUP_DIRS=("${BACKUP_DIRS_MACOS[@]}") ;;
    linux)   declare -p BACKUP_DIRS_LINUX   &>/dev/null && BACKUP_DIRS=("${BACKUP_DIRS_LINUX[@]}") ;;
    windows) declare -p BACKUP_DIRS_WINDOWS &>/dev/null && BACKUP_DIRS=("${BACKUP_DIRS_WINDOWS[@]}") ;;
esac

LOG_FILE="${AUTO_GIT_LOG:-$HOME/workspace/auto-git-backup.log}"
LOCK_FILE="${AUTO_GIT_LOCK:-$HOME/workspace/auto-git-commit.lock}"

# GitHub + GitCode fallback (same as interactive git wrapper).
_AUTO_GIT_DUAL_LIB=""
for _lib_candidate in \
    "${MY_UTILS_ROOT:-}/common/git-dual-remote-lib.sh" \
    "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/git-dual-remote-lib.sh"; do
    if [ -f "$_lib_candidate" ]; then
        _AUTO_GIT_DUAL_LIB="$_lib_candidate"
        break
    fi
done
if [ -n "$_AUTO_GIT_DUAL_LIB" ]; then
    [ -f "${MY_UTILS_ROOT:-}/config/git-dual-remote.env" ] && . "${MY_UTILS_ROOT}/config/git-dual-remote.env"
    # shellcheck source=git-dual-remote-lib.sh
    . "$_AUTO_GIT_DUAL_LIB"
fi
unset _lib_candidate _AUTO_GIT_DUAL_LIB

# Non-interactive SSH for pull/push (cron, scripts): first connect to a host like gitcode.com
# otherwise stops at "Are you sure you want to continue connecting". Override by exporting
# GIT_SSH_COMMAND before running this script.
if [ -z "${GIT_SSH_COMMAND:-}" ]; then
    export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new'
fi
# Avoid blocking on HTTPS credential prompts when no TTY.
export GIT_TERMINAL_PROMPT="${GIT_TERMINAL_PROMPT:-0}"

# --- Helpers ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

_say() {
    [ -n "${AUTO_GIT_SILENT:-}" ] && return 0
    printf '%s\n' "$*" >&2
}

# Backup one git directory: commit and push if there are changes.
# Usage: backup_one_dir <directory> [expected_branch]
#
# Semantics of expected_branch:
#   - If empty: back up whatever the current branch is, push to that same branch.
#   - If set: ONLY back up when the current branch matches. Otherwise skip.
#     (Never switch branches — switching mid-session can corrupt working state.)
#   - This means multiple entries with the same path but different branches in
#     BACKUP_DIRS_* express "this repo backs up under different branches on
#     different machines" — exactly one entry will match per host.
#
# Other safety nets:
#   - .no-auto-backup sentinel file in the repo root → skip entirely.
backup_one_dir() {
    local dir="$1"
    local expected_branch="${2:-}"
    local name
    name="$(basename "$dir")"

    if [ ! -d "$dir" ]; then
        log "[$name] SKIP: directory not found: $dir"
        return 0
    fi

    cd "$dir" || {
        log "[$name] ERROR: cannot cd to $dir"
        return 1
    }

    if [ ! -d ".git" ]; then
        log "[$name] SKIP: not a git repository"
        return 0
    fi

    # SAFETY: opt-out sentinel — drop a `.no-auto-backup` file in the repo root
    # to pause auto-backup during long interactive sessions.
    if [ -f "$dir/.no-auto-backup" ]; then
        log "[$name] SKIP: .no-auto-backup sentinel present"
        return 0
    fi

    # Determine current branch (detached HEAD reports "HEAD")
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$current_branch" ] || [ "$current_branch" = "HEAD" ]; then
        log "[$name] SKIP: detached HEAD or unknown branch state"
        return 0
    fi

    # SAFETY: if entry pinned a branch, only back up when current matches.
    # Never switch branches.
    if [ -n "$expected_branch" ] && [ "$expected_branch" != "$current_branch" ]; then
        log "[$name] SKIP: current branch '$current_branch' != entry branch '$expected_branch' (no branch switching)"
        return 0
    fi

    # Branch we'll push to: the entry's branch (if specified) or current.
    # In normal operation these are equal because the safety check above passed.
    local branch="${expected_branch:-$current_branch}"

    # Ensure dual remotes when lib is available (no-op for non-GitHub repos).
    if declare -F git_dual_ensure_remotes >/dev/null 2>&1; then
        git_dual_ensure_remotes origin 2>/dev/null || true
    fi

    # Commit local changes FIRST so pull --rebase is not blocked by a dirty tree.
    local changed=""
    if ! git diff-index --quiet HEAD -- 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
        changed=$(git status --porcelain)
        log "[$name] Changes detected"
        echo "$changed" | while IFS= read -r line; do [ -n "$line" ] && log "[$name]   $line"; done

        local commit_msg="Auto-backup: $(date '+%Y-%m-%d %H:%M:%S')
Changed files:
$changed"

        git add -A
        if ! git commit -q -m "$commit_msg"; then
            log "[$name] ERROR: git commit failed"
            return 1
        fi
        log "[$name] Committed local changes"
    else
        log "[$name] No local changes to commit"
    fi

    # Sync with remote, then push (GitCode fallback on timeout when dual lib is loaded).
    log "[$name] On branch $branch; updating from remote (git pull --rebase)..."
    local pull_out pull_ret
    if declare -F git_dual_pull >/dev/null 2>&1; then
        pull_out=$(git_dual_pull --rebase 2>&1)
        pull_ret=$?
    else
        pull_out=$(git pull --rebase 2>&1)
        pull_ret=$?
    fi
    echo "$pull_out" | while IFS= read -r line; do [ -n "$line" ] && log "[$name] $line"; done
    if [ $pull_ret -ne 0 ]; then
        log "[$name] ERROR: git pull --rebase failed (conflicts or remote error); skip push for this repo"
        return 1
    fi

    local push_out push_ret
    if declare -F git_dual_push >/dev/null 2>&1; then
        push_out=$(git_dual_push origin "$branch" 2>&1)
        push_ret=$?
    else
        push_out=$(git push origin "$branch" 2>&1)
        push_ret=$?
    fi
    echo "$push_out" | while IFS= read -r line; do [ -n "$line" ] && log "[$name] $line"; done
    if [ $push_ret -ne 0 ]; then
        log "[$name] ERROR: git push failed (exit $push_ret)"
        return 1
    fi
    log "[$name] Pushed to origin/$branch"
    return 0
}

# --- Main ---
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Single-instance guard (launchd StartInterval can overlap a long run).
if command -v shlock >/dev/null 2>&1; then
    if ! shlock -f "$LOCK_FILE" -p $$; then
        _say "auto-git-commit: another instance is running; exit 0"
        log "=== auto-git-commit skip (lock held: $LOCK_FILE) ==="
        exit 0
    fi
    trap 'rm -f "$LOCK_FILE"' EXIT
else
    # Fallback: mkdir lock (atomic on POSIX).
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        _say "auto-git-commit: another instance is running; exit 0"
        log "=== auto-git-commit skip (lock held: $LOCK_FILE) ==="
        exit 0
    fi
    trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT
fi

_say "auto-git-commit: started (OS=$BACKUP_OS)"
_say "auto-git-commit: log file -> $LOG_FILE"
log "=== auto-git-commit start (OS: $BACKUP_OS) ==="

fail=0
failed_entries=()
for entry in "${BACKUP_DIRS[@]}"; do
    # Skip empty and comment lines
    [[ -z "$entry" ]] && continue
    [[ "$entry" =~ ^[[:space:]]*# ]] && continue
    entry=$(echo "$entry" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$entry" ]] && continue

    dir="" branch=""
    if [[ "$entry" == *:* ]]; then
        dir="${entry%%:*}"
        branch="${entry#*:}"
        branch=$(echo "$branch" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    else
        # No ":branch" → back up whatever the current branch is (empty filter).
        dir="$entry"
        branch=""
    fi
    [[ -z "$dir" ]] && continue

    if [ ! -d "$dir" ]; then
        name="$(basename "$dir")"
        log "[$name] SKIP: directory not found: $dir"
        continue
    fi

    if ! backup_one_dir "$dir" "$branch"; then
        fail=1
        failed_entries+=("$dir (branch: $branch)")
    fi
done

log "=== auto-git-commit end ==="
if [ "$fail" -eq 0 ]; then
    _say "auto-git-commit: finished OK (exit 0). Per-repo detail in log."
else
    _say "auto-git-commit: finished with errors (exit 1). See: $LOG_FILE"
    if [ "${#failed_entries[@]}" -gt 0 ]; then
        _say "auto-git-commit: backup failed for:"
        for _fe in "${failed_entries[@]}"; do
            _say "  - $_fe"
            log "FAILED entry: $_fe"
        done
        unset _fe
    fi
fi
exit "$fail"
