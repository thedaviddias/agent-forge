#!/bin/bash
#
# Obsidian File Watcher
# Triggers backup sync when files change, with 30-second debounce
#

OPENCLAW_DIR="${HOME}/.openclaw"
OBSIDIAN_DIR="${OPENCLAW_DIR}/obsidian"
SYNC_SCRIPT="${OPENCLAW_DIR}/skills/openclaw-backup/scripts/sync.sh"
LOG_FILE="${OPENCLAW_DIR}/logs/watcher.log"
DEBOUNCE_SECONDS=30
LAST_SYNC_FILE="/tmp/obsidian-watcher-last-sync"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

should_sync() {
    if [ ! -f "$LAST_SYNC_FILE" ]; then
        return 0  # Never synced, do it
    fi
    
    local last_sync=$(cat "$LAST_SYNC_FILE")
    local now=$(date +%s)
    local diff=$((now - last_sync))
    
    if [ $diff -ge $DEBOUNCE_SECONDS ]; then
        return 0  # Enough time passed
    fi
    
    return 1  # Still in debounce window
}

do_sync() {
    date +%s > "$LAST_SYNC_FILE"
    log "Triggering sync..."
    "$SYNC_SCRIPT" >> "$LOG_FILE" 2>&1
    log "Sync complete"
}

log "=== Watcher started ==="
log "Watching: $OBSIDIAN_DIR"
log "Debounce: ${DEBOUNCE_SECONDS}s"

# Watch for file changes
fswatch -o "$OBSIDIAN_DIR" --exclude '\.git' --exclude '\.DS_Store' | while read -r count; do
    log "Detected $count change(s)"
    
    if should_sync; then
        do_sync
    else
        log "Debounced (too soon since last sync)"
    fi
done
