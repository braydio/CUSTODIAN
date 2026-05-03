#!/usr/bin/env bash

REPO_DIR="$(git rev-parse --show-toplevel)"
G_DRIVE_REMOTE="CUSTODIAN-GDRIVE:git-backups/home/braydenchaffee/Projects/CUSTODIAN"

echo "Syncing $REPO_DIR to G-Drive..."

rclone sync "$REPO_DIR" "$G_DRIVE_REMOTE" \
  --exclude ".git/**" \
  --exclude ".godot/**" \
  --exclude ".venv/**" \
  --exclude "__pycache__/**" \
  --progress

echo "G-Drive sync complete."
