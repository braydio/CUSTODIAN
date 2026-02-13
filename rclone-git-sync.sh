#!/usr/bin/env bash

REPO_DIR="$(git rev-parse --show-toplevel)"
DROPBOX_REMOTE="git-dropbox-sync:git-backups/$REPO_DIR"

echo "Syncing $REPO_DIR to Dropbox..."

rclone sync "$REPO_DIR" "$DROPBOX_REMOTE" \
  --exclude ".git/**" \
  --exclude ".venv/**" \
  --exclude "__pycache__/**" \
  --progress

echo "Dropbox sync complete."
