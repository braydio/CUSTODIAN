#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
G_DRIVE_REMOTE="git-gdrive-sync:git-backups/home/braydenchaffee/Projects/CUSTODIAN"
ACTION="${1:-sync}"

LOG_DIR="$REPO_DIR/.git/hooks-logs"
LOCK_FILE="$LOG_DIR/rclone-git-sync.lock"

mkdir -p "$LOG_DIR"

# Prevent overlapping backups from rapid successive commits.
exec 9>"$LOCK_FILE"

if command -v flock >/dev/null 2>&1; then
    if ! flock -n 9; then
        echo "Another CUSTODIAN backup is already running; skipping."
        exit 0
    fi
else
    echo "Warning: flock not available; continuing without backup locking." >&2
fi


# ─────────────────────────────────────────────
# Preconditions
# ─────────────────────────────────────────────
if ! command -v rclone >/dev/null 2>&1; then
    echo "ERROR: rclone is not installed." >&2
    exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -qx 'git-gdrive-sync:'; then
    echo "ERROR: rclone remote 'git-gdrive-sync:' is not configured." >&2
    exit 1
fi


# ─────────────────────────────────────────────
# Direction
# ─────────────────────────────────────────────
case "$ACTION" in
    sync|backup)
        echo "Backing up $REPO_DIR -> $G_DRIVE_REMOTE"
        SOURCE="$REPO_DIR"
        DESTINATION="$G_DRIVE_REMOTE"
        ;;

    restore)
        echo "Restoring $G_DRIVE_REMOTE -> $REPO_DIR"
        echo "WARNING: restore may overwrite local files."
        SOURCE="$G_DRIVE_REMOTE"
        DESTINATION="$REPO_DIR"
        ;;

    *)
        echo "Usage: $0 [backup|sync|restore]" >&2
        exit 1
        ;;
esac


ARGS=(
    --exclude ".git/**"
    --exclude ".godot/**"
    --exclude ".venv/**"
    --exclude "__pycache__/**"
    --exclude "node_modules/**"
    --exclude ".import/**"
    --metadata
    --checksum
)

if [ -f "$REPO_DIR/.rcloneignore" ]; then
    ARGS+=(--exclude-from "$REPO_DIR/.rcloneignore")
fi

# Intentionally use COPY, not SYNC.
# Backups should not delete remote-only files.
rclone copy \
    "$SOURCE" \
    "$DESTINATION" \
    "${ARGS[@]}" \
    --stats 30s

echo "Google Drive $ACTION complete."
