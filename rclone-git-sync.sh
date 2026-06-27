#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
G_DRIVE_REMOTE="git-gdrive-sync:git-backups/home/braydenchaffee/Projects/CUSTODIAN"
ACTION="${1:-sync}"  # "sync" (default, local→remote) or "restore" (remote→local)

# --- Pre-flight checks ---

if ! command -v rclone &> /dev/null; then
  echo "ERROR: rclone is not installed."
  exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "git-gdrive-sync:"; then
  echo "ERROR: rclone remote 'git-gdrive-sync' is not configured."
  echo "  Run: rclone config create git-gdrive-sync drive ..."
  exit 1
fi

# --- Mode ---

case "$ACTION" in
  sync)
    echo "Syncing $REPO_DIR → G-Drive (local is source)..."
    DIRECTION=("$REPO_DIR" "$G_DRIVE_REMOTE")
    ;;
  restore)
    echo "Restoring G-Drive → $REPO_DIR (remote is source)..."
    echo "  WARNING: This overwrites local files not in the backup."
    DIRECTION=("$G_DRIVE_REMOTE" "$REPO_DIR")
    ;;
  *)
    echo "Usage: $0 [sync|restore]"
    echo "  sync    (default)  Copy local changes to G-Drive"
    echo "  restore            Pull G-Drive backup down to local"
    exit 1
    ;;
esac

# --- Exclude args ---

EXCLUDE_ARGS=(
  # Baseline safety — always exclude these regardless of .gitignore
  --exclude ".git/**"
  --exclude ".godot/**"
  --exclude ".venv/**"
  --exclude "__pycache__/**"
  --exclude "node_modules/**"
  --exclude ".import/**"

  # Note: full .gitignore compatibility requires rclone's --gitignore flag which
  # is only available in rclone sync, not copy. The explicit excludes above cover
  # the high-noise patterns. For additional gitignore-like rules, add them to
  # a .rcloneignore file — it will be picked up if present.

  # Keep rclone metadata for faster re-syncs
  --metadata

  # Track renames so moved files don't get re-uploaded
  --track-renames

  # Check file hashes for integrity
  --checksum
)

# Optional: respect .rcloneignore if it exists (rclone-specific overrides)
if [ -f "$REPO_DIR/.rcloneignore" ]; then
  EXCLUDE_ARGS+=(--exclude-from "$REPO_DIR/.rcloneignore")
  echo "  Using .rcloneignore for additional exclude patterns."
fi

# --- Execute ---

rclone copy "${DIRECTION[@]}" "${EXCLUDE_ARGS[@]}" --progress

echo "G-Drive ${ACTION} complete."
