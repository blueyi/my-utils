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
# Format: "path" (use default branch) or "path:branch"
# Default list (used when no OS-specific list is set)
BACKUP_DIRS=(
    "$HOME/.openclaw"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    # "$HOME/workspace/repos/kora:main"  # disabled: auto-backup breaks in-progress edits
    "$HOME/.openclaw:macos"
    # "$HOME/some-other-repo:master"
    # "/path/to/another/dir"
)

# Optional: per-OS lists — same path can backup to different branches per OS
# BACKUP_DIRS_MACOS=(
#     "$HOME/workspace/my-utils:main-macos"
#     "$HOME/.openclaw"
# )
BACKUP_DIRS_LINUX=(
    "$HOME/.openclaw:ucloud"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    # "$HOME/workspace/repos/kora:main"  # disabled: auto-backup breaks in-progress edits
    "$HOME/repos/my-utils:main"
    "$HOME/.openclaw:wsl"
    "$HOME/.hermes:wsl"
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

DEFAULT_BRANCH="${AUTO_GIT_BRANCH:-main}"
LOG_FILE="${AUTO_GIT_LOG:-$HOME/workspace/auto-git-backup.log}"

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
# Usage: backup_one_dir <directory> [branch]
backup_one_dir() {
    local dir="$1"
    local branch="${2:-$DEFAULT_BRANCH}"
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

    # Always try to pull latest from remote before backing up
    log "[$name] Updating from remote (git pull --rebase)..."
    if ! git pull --rebase 2>&1 | while IFS= read -r line; do [ -n "$line" ] && log "[$name] $line"; done; then
        log "[$name] ERROR: git pull --rebase failed (uncommitted changes or conflicts); skip backup for this repo"
        return 1
    fi

    if git diff-index --quiet HEAD -- 2>/dev/null && [ -z "$(git status --porcelain)" ]; then
        log "[$name] No changes after pull"
        return 0
    fi

    local changed
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

    local push_out push_ret
    push_out=$(git push origin "$branch" 2>&1)
    push_ret=$?
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
        dir="$entry"
        branch="$DEFAULT_BRANCH"
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
