#!/bin/bash
# prompt-menu.sh - Interactive prompt selector with variable rendering
#
# Select a prompt template, fill in {{variable}} markers interactively,
# and get a copy-paste-ready rendered prompt.
#
# Variables use {{name}} or {{name:default_value}} syntax.

set -euo pipefail

# ---- Resolve paths relative to script location ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROMPT_DIR="$PROJECT_ROOT/custodian/docs/ai_context/prompts"
TEMP_FILE=$(mktemp)

cleanup() { rm -f "$TEMP_FILE"; }
trap cleanup EXIT

# ---- Colors ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ---- Detect clipboard tool ----
CLIP_CMD=""
if command -v pbcopy &>/dev/null; then
    CLIP_CMD="pbcopy"
elif command -v xclip &>/dev/null; then
    CLIP_CMD="xclip -selection clipboard"
elif command -v wl-copy &>/dev/null; then
    CLIP_CMD="wl-copy"
fi

# ---- Validate prompts directory ----
if [[ ! -d "$PROMPT_DIR" ]]; then
    echo -e "${RED}Prompt directory not found: $PROMPT_DIR${NC}"
    echo "Check that the script is in CUSTODIAN/scripts/"
    exit 1
fi

# ---- Gather prompt files (exclude README) ----
prompt_files=()
while IFS= read -r -d '' f; do
    basename_f=$(basename "$f")
    [[ "$basename_f" == "README.md" ]] && continue
    prompt_files+=("$f")
done < <(find "$PROMPT_DIR" -maxdepth 1 -name '*.md' -print0 | sort -z)

if [[ ${#prompt_files[@]} -eq 0 ]]; then
    echo -e "${RED}No prompt files found in $PROMPT_DIR${NC}"
    exit 1
fi

# ---- Extract prompt names from filenames ----
prompt_names=()
for f in "${prompt_files[@]}"; do
    prompt_names+=("$(basename "$f" .md)")
done

# ---- Helpers ----
get_title() {
    head -n 1 "$1" 2>/dev/null | sed 's/^# //'
}

extract_vars() {
    local file="$1"
    # Preserve order of appearance (no sort — awk dedup keeps first occurrence)
    grep -oP '\{\{[^}]+\}\}' "$file" 2>/dev/null | awk '!seen[$0]++'
}

# Parse {{name}} or {{name:default}} → output "name|default" or "name|"
parse_var() {
    local var="$1"
    local inner="${var#\{\{}"
    inner="${inner%\}\}}"
    if [[ "$inner" == *:* ]]; then
        echo "${inner%%:*}|${inner#*:}"
    else
        echo "${inner}|"
    fi
}

render_prompt() {
    local file="$1"
    shift
    cp "$file" "$TEMP_FILE"
    local sub var_name var_value escaped_value
    for sub in "$@"; do
        var_name="${sub%%|*}"
        var_value="${sub#*|}"
        # Escape & and / for sed replacement
        escaped_value=$(printf '%s\n' "$var_value" | sed 's/[\/&]/\\&/g')
        # Replace {{name}} and {{name:anything}} with the value
        # NOTE: bare {{ }} (no backslash escapes) because this is GNU sed.
        sed -i "s/{{$var_name\(:[^}]*\)*}}/$escaped_value/g" "$TEMP_FILE"
    done
    cat "$TEMP_FILE"
}

prompt_for_variables() {
    local file="$1"
    shift
    local -n _subs=$1
    _subs=()

    mapfile -t variables < <(extract_vars "$file")

    if [[ ${#variables[@]} -eq 0 ]]; then
        return 0
    fi

    clear
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  Fill in variables${NC}"
    echo -e "${MAGENTA}  Enter values or press Enter to accept defaults${NC}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════════════════${NC}"
    echo

    local parsed var_name var_default user_input
    for var in "${variables[@]}"; do
        parsed=$(parse_var "$var")
        var_name="${parsed%%|*}"
        var_default="${parsed#*|}"

        if [[ -n "$var_default" ]]; then
            echo -e "  ${CYAN}${var_name}${NC} [${YELLOW}${var_default}${NC}]: \c"
        else
            echo -e "  ${CYAN}${var_name}${NC}: \c"
        fi
        IFS= read -r user_input

        if [[ -z "$user_input" && -n "$var_default" ]]; then
            _subs+=("${var_name}|${var_default}")
        elif [[ -z "$user_input" ]]; then
            # Keep the original marker
            _subs+=("${var_name}|${var}")
        else
            _subs+=("${var_name}|${user_input}")
        fi
    done
    return 0
}

render_and_show() {
    local file="$1"
    shift
    local name="$1"
    shift
    local -a subs=("$@")

    clear
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Rendered Prompt: ${YELLOW}${name}${NC}"
    echo -e "${GREEN}──────────────────────────────────────────────────────────────────────${NC}"

    # Show what was substituted
    if [[ ${#subs[@]} -gt 0 ]]; then
        local sub var_name var_value
        echo -e "${CYAN}  Variables:${NC}"
        for sub in "${subs[@]}"; do
            var_name="${sub%%|*}"
            var_value="${sub#*|}"
            echo -e "    ${YELLOW}${var_name}${NC} → ${var_value}"
        done
        echo -e "${GREEN}──────────────────────────────────────────────────────────────────────${NC}"
    fi

    echo
    render_prompt "$file" "${subs[@]}"
    echo
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"

    if [[ -n "$CLIP_CMD" ]]; then
        render_prompt "$file" "${subs[@]}" | eval "$CLIP_CMD"
        echo -e "${CYAN}Copied to clipboard.${NC}"
    fi

    echo
    echo -e "${YELLOW}Press Enter to return to menu...${NC}"
    read -r
}

# ---- Main menu loop ----
while true; do
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN}                                    CUSTODIAN AI Prompt Menu                                   ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"

    for i in "${!prompt_names[@]}"; do
        num=$((i + 1))
        name="${prompt_names[$i]}"
        title=$(get_title "${prompt_files[$i]}")
        printf "${BLUE}║${NC} ${GREEN}%-2d${NC}  ${YELLOW}%-44s${NC}  %s\n" "$num" "$name" "$title"
    done

    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}Enter number (or 'q' to quit):${NC} \c"
    read -r choice

    if [[ "$choice" == "q" ]]; then
        echo
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input. Enter a number or 'q'.${NC}"
        sleep 1
        continue
    fi

    idx=$((choice - 1))
    if [[ $idx -lt 0 || $idx -ge ${#prompt_files[@]} ]]; then
        echo -e "${RED}Invalid selection.${NC}"
        sleep 1
        continue
    fi

    selected_file="${prompt_files[$idx]}"
    selected_name="${prompt_names[$idx]}"

    # Check if file has any {{...}} variables
    if grep -qP '\{\{[^}]+\}\}' "$selected_file" 2>/dev/null; then
        # Has variables: prompt for each one
        substitutions=()
        prompt_for_variables "$selected_file" substitutions
        render_and_show "$selected_file" "$selected_name" "${substitutions[@]}"
    else
        # No variables: just show the prompt
        clear
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ${YELLOW}${selected_name}${NC}"
        echo -e "${GREEN}  (No variables to fill — plain copy)${NC}"
        echo -e "${GREEN}──────────────────────────────────────────────────────────────────────${NC}"
        echo
        cat "$selected_file"
        echo
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════${NC}"

        if [[ -n "$CLIP_CMD" ]]; then
            cat "$selected_file" | eval "$CLIP_CMD"
            echo -e "${CYAN}Copied to clipboard.${NC}"
        fi

        echo
        echo -e "${YELLOW}Press Enter to return to menu...${NC}"
        read -r
    fi
done
