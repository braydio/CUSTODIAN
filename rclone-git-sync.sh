#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
G_DRIVE_REMOTE="git-gdrive-sync:git-backups/home/braydenchaffee/Projects/CUSTODIAN"

echo "Syncing $REPO_DIR to G-Drive..."

# Build exclude args array
EXCLUDE_ARGS=(
  # Baseline safety — always exclude these regardless of .gitignore
  --exclude ".git/**"
  --exclude ".godot/**"
  --exclude ".venv/**"
  --exclude "__pycache__/**"
  --exclude "node_modules/**"

  # Respect .gitignore files throughout the tree
  --gitignore

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

rclone sync "$REPO_DIR" "$G_DRIVE_REMOTE" "${EXCLUDE_ARGS[@]}" --progress

echo "G-Drive sync complete."
