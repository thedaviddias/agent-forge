#!/bin/bash
#
# OpenClaw Backup Sync Script
# Performs automated git commit and push with timestamp
#

set -e

OPENCLAW_DIR="${HOME}/.openclaw"
LOGS_DIR="${OPENCLAW_DIR}/logs"
LOG_FILE="${LOGS_DIR}/backup-sync.log"
ERROR_LOG="${LOGS_DIR}/backup-errors.log"

# Discord webhook for #alerts
DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxxxxx"

# Send Discord notification
discord_notify() {
    local message="$1"
    local color="${2:-3447003}"  # Default: blue
    curl -s -H "Content-Type: application/json" \
        -d "{\"embeds\":[{\"description\":\"$message\",\"color\":$color}]}" \
        "$DISCORD_WEBHOOK" > /dev/null 2>&1 || true
}

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Timestamp functions
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_commit_timestamp() {
    date '+%Y-%m-%d %H:%M:%S %Z'
}

# Logging
log() {
    echo "[$(get_timestamp)] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(get_timestamp)] ERROR: $1" | tee -a "$ERROR_LOG"
}

# Change to openclaw directory
cd "$OPENCLAW_DIR" || {
    log_error "Failed to cd to $OPENCLAW_DIR"
    exit 1
}

# Check if git repo
if [ ! -d ".git" ]; then
    log_error "Not a git repository. Run: git init"
    exit 1
fi

# Check if remote exists
if ! git remote get-url origin &>/dev/null; then
    log_error "No remote configured. Run: git remote add origin <url>"
    exit 1
fi

# Fetch latest from remote to detect conflicts
log "Fetching from remote..."
if ! git fetch origin &>/dev/null; then
    log_error "Failed to fetch from remote"
    exit 2
fi

# Check for conflicts (diverged branches)
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" != "$BASE" ] && [ "$REMOTE" != "$BASE" ]; then
    log_error "CONFLICT DETECTED: Local and remote have diverged"
    log_error "Manual intervention required"
    discord_notify "⚠️ **Backup Conflict**\\nLocal and remote have diverged. Manual intervention required.\\n\`cd ~/.openclaw && git status\`" "15158332"  # Red
    echo "⚠ Conflicts detected between local and remote"
    echo "   Local:  $(git log -1 --format='%h %s' $LOCAL)"
    echo "   Remote: $(git log -1 --format='%h %s' $REMOTE)"
    echo ""
    echo "Resolve manually:"
    echo "   cd ~/.openclaw"
    echo "   git status"
    echo "   git pull --rebase  # or merge"
    exit 3
fi

# Pull latest changes (fast-forward only)
log "Pulling latest changes..."
if ! git pull --ff-only origin $(git rev-parse --abbrev-ref HEAD) &>/dev/null; then
    log "No remote changes to pull (or already up to date)"
fi

# Check for local changes
if [ -z "$(git status --porcelain)" ]; then
    log "No changes to commit"
    echo "✓ No changes — already up to date"
    exit 0
fi

# Add all changes
git add -A

# Commit with timestamp
COMMIT_TIME=$(get_commit_timestamp)
git commit -m "backup: ${COMMIT_TIME}"
log "Committed changes: ${COMMIT_TIME}"

# Push to remote
log "Pushing to remote..."
if git push origin $(git rev-parse --abbrev-ref HEAD); then
    log "Backup successful: ${COMMIT_TIME}"

    # Discord notifications disabled - was too noisy
    # Get changed files list
    # CHANGED_LIST=$(git diff --name-only HEAD~1 HEAD 2>/dev/null)
    # CHANGED_COUNT=$(echo "$CHANGED_LIST" | grep -c . || echo "0")
    #
    # Format file list for Discord (limit to 8 files)
    # if [ "$CHANGED_COUNT" -gt 0 ]; then
    #     FILE_LIST=$(echo "$CHANGED_LIST" | head -8 | sed 's|.*/||' | sed 's/^/• /' | tr '\n' '|' | sed 's/|$//' | sed 's/|/\\n/g')
    #     if [ "$CHANGED_COUNT" -gt 8 ]; then
    #         FILE_LIST="${FILE_LIST}\\n_...and $((CHANGED_COUNT - 8)) more_"
    #     fi
    #     discord_notify "✅ **GitHub Backup**\\n\`${COMMIT_TIME}\`\\n\\n**${CHANGED_COUNT} file(s):**\\n${FILE_LIST}" "3066993"  # Green
    # fi

    echo "✓ Backup successful: ${COMMIT_TIME}"
else
    log_error "Push failed"
    # Error notifications also disabled - check logs instead
    # discord_notify "❌ **Backup Failed**\\nPush to GitHub failed. Check error log." "15158332"  # Red
    echo "✗ Push failed — check error log"
    exit 2
fi

exit 0
