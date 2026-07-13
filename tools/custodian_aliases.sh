# ── Custodian Aliases & Commands ──────────────────────────────────────────
#
# Source this file from your .bashrc / .zshrc:
#   source "$HOME/Projects/CUSTODIAN/tools/custodian_aliases.sh"
#
# Project root variables ──────────────────────────────────────────────────
export CUSTODIAN_REPO="${HOME}/Projects/CUSTODIAN"
export CUSTODIAN_GODOT="${CUSTODIAN_REPO}/custodian"

# Quick navigation ────────────────────────────────────────────────────────
alias croot='cd "${CUSTODIAN_REPO}"'
alias cgodot='cd "${CUSTODIAN_GODOT}"'
alias cpack='"${CUSTODIAN_REPO}/scripts/ai/pack-context.sh"'

# Usage log helper ────────────────────────────────────────────────────────
_update_usage() {
  local name="$1"
  local usage_file="${HOME}/.custodian_alias_usage.log"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${name}" >>"${usage_file}"
}

# Commands ────────────────────────────────────────────────────────────────

# -- Show the Custodian operator color guide
opcolor() {
  bat "${CUSTODIAN_GODOT}/OPERATOR_COLOR.MD"
}

# -- Generate JSON sidecar manifests (dry run — preview only)
dryjson() {
  _update_usage "dryjson"
  python "${CUSTODIAN_GODOT}/tools/pipelines/generate_inbox_manifests.py" --dry-run
}

# -- Generate JSON sidecar manifests (live — writes files)
runjson() {
  _update_usage "runjson"
  python "${CUSTODIAN_GODOT}/tools/pipelines/generate_inbox_manifests.py"
}

# -- Run sprite ingest pipeline
runsprite() {
  _update_usage "runsprite"
  python3 "${CUSTODIAN_GODOT}/tools/pipelines/ingest.py" "$@"
}

# -- Run focused Operator ingest (dry run by default; pass --apply to write)
opingest() {
  _update_usage "opingest"
  "${CUSTODIAN_REPO}/tools/operator_ingest.sh" "$@"
}

# -- Match one sprite sheet's palette to a reference (CIE LAB nearest-color)
#    Usage: matchpal <reference.png> <target.png> <output.png> [strength] [max_colors]
matchpal() {
  _update_usage "matchpal"
  local ref="$1" target="$2" out="$3" strength="${4:-0.65}" max_colors="${5:-64}"
  python3 "${CUSTODIAN_GODOT}/tools/pipelines/match_sprite_palette.py" \
    --reference "$ref" --target "$target" --output "$out" \
    --strength "$strength" --max-colors "$max_colors"
}

# -- Batch-match all fast_strike_01 palettes to their fast_windup_01 counterparts
batchstrike() {
  _update_usage "batchstrike"
  python3 "${CUSTODIAN_GODOT}/tools/pipelines/batch_match_fast_strike_palette.py"
}

# -- List current assets in sprite pipeline inbox
listbox() {
  _update_usage "listbox"
  eza "${CUSTODIAN_GODOT}/content/sprites/_pipeline/inbox"
}

# -- Run the prompt menu interactively
promptmenu() {
  bash "${CUSTODIAN_REPO}/scripts/prompt-menu.sh"
}

# Usage tally ─────────────────────────────────────────────────────────────
alias_usage() {
  local usage_file="${HOME}/.custodian_alias_usage.log"
  if [[ ! -f "$usage_file" ]]; then
    echo "No usage data yet."
    return
  fi
  echo "Custodian alias usage counts:"
  for cmd in dryjson runjson runsprite opingest listbox matchpal batchstrike opcolor promptmenu; do
    local count
    count=$(grep -c "$cmd" "$usage_file" 2>/dev/null || echo 0)
    printf "  %-12s %d\n" "${cmd}:" "${count}"
  done
  echo "---"
  echo "Total: $(wc -l <"${usage_file}") invocations"
}

echo "  Custodian commands ready: croot, cgodot, cpack, opcolor, dryjson, runjson, runsprite, opingest, listbox, matchpal, batchstrike, promptmenu"
echo "  Type 'alias_usage' for usage counts."
