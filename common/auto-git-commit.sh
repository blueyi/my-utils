#!/bin/bash
# Auto Git Commit: backup multiple directories via git (add/commit/push).
# Add entries to BACKUP_DIRS below; run manually or via cron/launchd.
# Each directory must be a git repo; changes are committed and pushed to origin.

# --- Config: list of directories to auto backup (edit this list) ---
# Format: "path" (use default branch) or "path:branch"
BACKUP_DIRS=(
    "$HOME/.openclaw"
    "$HOME/workspace/my-utils:main"
    "$HOME/workspace/repos/hexoblog:master"
    # "$HOME/some-other-repo:master"
    # "/path/to/another/dir"
)
DEFAULT_BRANCH="${AUTO_GIT_BRANCH:-main}"
LOG_FILE="${AUTO_GIT_LOG:-$HOME/workspace/auto-git-backup.log}"

# --- Helpers ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
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

    if git diff-index --quiet HEAD -- 2>/dev/null && [ -z "$(git status --porcelain)" ]; then
        log "[$name] No changes"
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
    if ! git commit -m "$commit_msg"; then
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
log "=== auto-git-commit start ==="

fail=0
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

    if ! backup_one_dir "$dir" "$branch"; then
        fail=1
    fi
done

log "=== auto-git-commit end ==="
exit "$fail"
