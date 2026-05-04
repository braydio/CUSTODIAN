#!/bin/bash
# prompt-menu.sh - Interactive prompt selector for custodian/docs/ai_context/prompts/

PROMPT_DIR="/home/linux/Projects/CUSTODIAN/custodian/docs/ai_context/prompts"
TEMP_FILE="/tmp/prompt_preview.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get list of prompts
prompts=( "$PROMPT_DIR"/*.md )
prompt_names=()

# Extract prompt names from filenames
for f in "${prompts[@]}"; do
    prompt_names+=("$(basename "$f" .md)")
done

# Print header
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${CYAN}           CUSTODIAN AI Prompt Menu                           ${BLUE}║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════════════╣${NC}"

# List prompts with numbers
for i in "${!prompt_names[@]}"; do
    num=$((i + 1))
    name="${prompt_names[$i]}"
    # Extract first line (title) from the prompt
    title=$(head -n 1 "${prompts[$i]}" 2>/dev/null | sed 's/^# //')
    printf "${BLUE}║${NC} ${GREEN}%-2d${NC} ${YELLOW}%-40s${NC} %s\n" "$num" "$name" "$title"
done

echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}Enter prompt number (or 'q' to quit):${NC} \c"
