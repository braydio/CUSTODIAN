#!/usr/bin/env bash
# codex_ingest.sh — Parse PRE_TASK.md and append new tasks to CODEX_TASK.md
#
# Usage:
#   bash tools/codex_ingest.sh              # Interactive mode (prompts for priority)
#   bash tools/codex_ingest.sh --auto       # Auto-assign priority from context
#   bash tools/codex_ingest.sh --dry-run    # Preview without writing
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRE_TASK="$REPO_ROOT/PRE_TASK.md"
CODEX_TASK="$REPO_ROOT/CODEX_TASK.md"

MODE="interactive"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --auto) MODE="auto" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: bash tools/codex_ingest.sh [--auto] [--dry-run]"
      echo ""
      echo "  --auto      Auto-assign priority (high if contains 'urgent|critical|asap',"
      echo "              medium if 'should|need|want', low otherwise)"
      echo "  --dry-run   Preview tasks without writing"
      exit 0
      ;;
  esac
done

if [[ ! -f "$PRE_TASK" ]]; then
  echo "Error: PRE_TASK.md not found at $PRE_TASK"
  exit 1
fi

if [[ ! -f "$CODEX_TASK" ]]; then
  echo "Error: CODEX_TASK.md not found at $CODEX_TASK"
  exit 1
fi

# Extract tasks from PRE_TASK.md
# Lines starting with "- " or "* " are tasks
# Lines starting with "## " are section headers (context for following tasks)
# Blank lines and comments are ignored
# Lines between --- and --- at the top are ignored (header block)

TASKS=()
CONTEXT=""
PAST_HEADER=false

while IFS= read -r line; do
  # Skip everything until we hit the first --- (end of header template)
  if [[ "$PAST_HEADER" == false ]]; then
    if [[ "$line" == "---" ]]; then
      PAST_HEADER=true
    fi
    continue
  fi

  # Skip blank lines, comments, and template examples
  trimmed="$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
  [[ -z "$trimmed" ]] && continue
  [[ "$trimmed" == "#"* && "$trimmed" != "## "* ]] && continue
  [[ "$trimmed" == "<!--"* ]] && continue

  # Section headers become context
  if [[ "$trimmed" == "## "* ]]; then
    CONTEXT="${trimmed## }"
    continue
  fi

  # Extract task from bullet points
  TASK_TEXT=""
  if [[ "$trimmed" == "- "* ]]; then
    TASK_TEXT="${trimmed#- }"
  elif [[ "$trimmed" == "* "* ]]; then
    TASK_TEXT="${trimmed#* }"
  elif [[ "$trimmed" == "-["* ]]; then
    # Checkbox format: - [ ] task
    TASK_TEXT=$(echo "$trimmed" | sed 's/^- \[.\] //')
  fi

  if [[ -n "$TASK_TEXT" ]]; then
    # Skip if it's a template example
    [[ "$TASK_TEXT" == *"<--"* ]] && continue
    TASKS+=("${CONTEXT}|${TASK_TEXT}")
    CONTEXT=""
  fi
done < "$PRE_TASK"

if [[ ${#TASKS[@]} -eq 0 ]]; then
  echo "No tasks found in PRE_TASK.md"
  exit 0
fi

echo "Found ${#TASKS[@]} task(s) in PRE_TASK.md"
echo ""

# Generate task IDs
TIMESTAMP=$(date +%Y%m%d_%H%M)
TASK_NUM=0

# Build the new tasks section
NEW_TASKS=""

for entry in "${TASKS[@]}"; do
  TASK_NUM=$((TASK_NUM + 1))
  CONTEXT_PART="${entry%%|*}"
  TASK_TEXT="${entry#*|}"

  # Auto-assign priority
  PRIORITY="medium"
  if [[ "$MODE" == "auto" ]]; then
    LOWER_TASK="$(echo "$TASK_TEXT" | tr '[:upper:]' '[:lower:]')"
    if echo "$LOWER_TASK" | grep -qiE "urgent|critical|asap|blocker|broken"; then
      PRIORITY="high"
    elif echo "$LOWER_TASK" | grep -qiE "should|need|want|improve|add|fix"; then
      PRIORITY="medium"
    else
      PRIORITY="low"
    fi
  else
    # Interactive mode
    echo "Task $TASK_NUM: $TASK_TEXT"
    [[ -n "$CONTEXT_PART" ]] && echo "  Context: $CONTEXT_PART"
    echo -n "  Priority [low/medium/high] (default: medium): "
    read -r INPUT_PRIORITY
    if [[ -n "$INPUT_PRIORITY" ]]; then
      PRIORITY="$INPUT_PRIORITY"
    fi
    echo ""
  fi

  TASK_ID="${TIMESTAMP}_$(printf '%02d' $TASK_NUM)"

  NEW_TASKS+="- [ ] **[$PRIORITY]** $TASK_TEXT
  - ID: $TASK_ID
  - Added: $(date +%Y-%m-%d)
"
  [[ -n "$CONTEXT_PART" ]] && NEW_TASKS+="  - Context: $CONTEXT_PART
"
  NEW_TASKS+="
"
done

if [[ "$DRY_RUN" == true ]]; then
  echo "=== DRY RUN — Would add: ==="
  echo ""
  echo "$NEW_TASKS"
  exit 0
fi

# Insert new tasks into CODEX_TASK.md under ## Ready
# Find the line after "## Ready" and before "_No tasks queued._" or first task
READY_LINE=$(grep -n "^## Ready" "$CODEX_TASK" | head -1 | cut -d: -f1)

if [[ -z "$READY_LINE" ]]; then
  echo "Error: Could not find '## Ready' section in CODEX_TASK.md"
  exit 1
fi

# Check if there's a placeholder
PLACEHOLDER_LINE=$(grep -n "_No tasks queued._" "$CODEX_TASK" | head -1 | cut -d: -f1)

if [[ -n "$PLACEHOLDER_LINE" ]]; then
  # Replace placeholder with new tasks
  HEAD=$(sed -n "1,$((PLACEHOLDER_LINE - 1))p" "$CODEX_TASK")
  TAIL=$(sed -n "$((PLACEHOLDER_LINE + 1)),$ p" "$CODEX_TASK")
  echo "${HEAD}
${NEW_TASKS}
${TAIL}" > "$CODEX_TASK"
else
  # Insert after ## Ready line
  HEAD=$(sed -n "1,${READY_LINE}p" "$CODEX_TASK")
  TAIL=$(sed -n "$((READY_LINE + 1)),$ p" "$CODEX_TASK")
  echo "${HEAD}
${NEW_TASKS}
${TAIL}" > "$CODEX_TASK"
fi

echo "Added ${#TASKS[@]} task(s) to CODEX_TASK.md"

# Archive PRE_TASK.md content
ARCHIVE_DIR="$REPO_ROOT/docs/task_archive"
mkdir -p "$ARCHIVE_DIR"
ARCHIVE_FILE="$ARCHIVE_DIR/pre_task_$(date +%Y%m%d_%H%M%S).md"
cp "$PRE_TASK" "$ARCHIVE_FILE"

# Clear PRE_TASK.md but keep template
cat > "$PRE_TASK" << 'EOF'
# Pre-Task Queue

Dump raw task ideas here. No formatting required — just get it out of your head.

When you're ready to process, run: `bash tools/codex_ingest.sh`

---

EOF

echo "Archived PRE_TASK.md to $ARCHIVE_FILE"
echo "PRE_TASK.md cleared"
