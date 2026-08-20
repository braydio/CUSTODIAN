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
  "${CUSTODIAN_GODOT}/tools/operator/operator_ingest.sh" "$@"
}

# -- Analyze the latest or an explicitly provided Developer Observatory session
obsreport() {
  _update_usage "obsreport"
  python3 "${CUSTODIAN_GODOT}/tools/analysis/analyze_dev_observatory_session.py" "$@"
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

# -- Convert a spritesheet to pixel art frame-by-frame and reassemble it
#    Filename must end in '__<frames>f__<size>', e.g. operator__run__8f__96
#    Usage: pixelart <source> [output] [--frames N] [--size 96] [--colors 24] [--choose 1|2|3] [--force]
pixelart() {
  _update_usage "pixelart"
  python3 "${CUSTODIAN_GODOT}/tools/art/spritesheet_pixelart.py" "$@"
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

# -- Check modular upper/lower combo fit (bounding box, alignment, overlap)
opcombo() {
  _update_usage "opcombo"
  python3 "${CUSTODIAN_GODOT}/tools/operator/modular_combo_check.py" "$@"
}

# -- Run operator animation contract report (completeness vs production contract)
opcontract() {
  _update_usage "opcontract"
  python3 "${CUSTODIAN_GODOT}/tools/validation/operator_animation_contract_report.py" "$@"
}

# -- Audit modular sprite sources for missing/extra/malformed assets
opaudit() {
  _update_usage "opaudit"
  python3 "${CUSTODIAN_GODOT}/tools/operator/check_operator_modular_assets.py" "$@"
}

# -- Audit PNG sprite sheets (generates vertical audit sheet)
pngaudit() {
  _update_usage "pngaudit"
  local dir="${1:-.}"
  (cd "$dir" && python3 "${CUSTODIAN_GODOT}/tools/validation/png_audit.py" "${@:2}")
}

# -- Asset Pipeline V2 (unified intake)
asset() {
  _update_usage "asset"
  python3 "${CUSTODIAN_GODOT}/tools/assets/asset.py" "$@"
}

# -- Generate prioritized next-actions report (fit + contract joined)
opnext() {
  _update_usage "opnext"
  python3 "${CUSTODIAN_GODOT}/tools/operator/operator_next_actions_report.py" "$@"
}

# -- Interactive Operator V2 alignment repair conveyor (pass --report-only for analysis only)
oprepair() {
  _update_usage "oprepair"
  python3 "${CUSTODIAN_GODOT}/tools/operator/modular_alignment_repair.py" "$@"
}

# -- Alignment repair analysis only (never launches Aseprite, never writes pixels)
oprepair-report() {
  _update_usage "oprepair-report"
  python3 "${CUSTODIAN_GODOT}/tools/operator/modular_alignment_repair.py" --report-only --no-open "$@"
}

# -- Run the Operator alignment repair regression smoke suite
oprepair-smoke() {
  _update_usage "oprepair-smoke"
  python3 "${CUSTODIAN_GODOT}/tools/validation/operator_modular_alignment_repair_smoke.py" "$@"
}

# -- Run CUSTODIAN validation (defaults to --changed --json for the shared-tree ask)
opvalidate() {
  _update_usage "opvalidate"
  if [[ $# -eq 0 ]]; then
    python3 "${CUSTODIAN_GODOT}/tools/validation/run_validation.py" --changed --json
  else
    python3 "${CUSTODIAN_GODOT}/tools/validation/run_validation.py" "$@"
  fi
}

# List all commands ───────────────────────────────────────────────────────
clisting() {
  echo "Custodian commands:"
  echo ""
  echo "  Navigation"
  echo "    croot          cd to repo root"
  echo "    cgodot         cd to custodian/ (Godot project)"
  echo "    cpack          run context pack script"
  echo ""
  echo "  Sprites & Pipelines"
  echo "    dryjson        generate JSON sidecar manifests (dry run)"
  echo "    runjson        generate JSON sidecar manifests (live)"
  echo "    runsprite      run sprite ingest pipeline"
  echo "    opingest       focused operator ingest (dry run; --apply to write)"
  echo "    pixelart       spritesheet -> frame-by-frame pixel art -> chosen PNG"
  echo "    matchpal       match sprite palette to a reference (CIE LAB)"
  echo "    batchstrike    batch-match fast_strike palettes to fast_windup"
  echo "    listbox        list current assets in pipeline inbox"
  echo ""
  echo "  Operator Animation"
  echo "    opcombo        check upper/lower modular combo fit & alignment"
  echo "    opcontract     report animation completeness vs production contract"
  echo "    opaudit        audit modular sprite sources for missing/extra assets"
  echo "    opnext         prioritized next-actions report (fit + contract)"
  echo "    oprepair       interactive Operator V2 alignment repair conveyor"
  echo "    oprepair-report alignment repair analysis only (no Aseprite, no writes)"
  echo "    oprepair-smoke run the alignment repair regression smoke suite"
  echo "    opcolor        show operator color guide"
  echo ""
  echo "  Debug & Reporting"
  echo "    obsreport      analyze a Developer Observatory session"
  echo "    opvalidate     run CUSTODIAN validation (defaults to --changed --json)"
  echo ""
  echo "  Misc"
  echo "    promptmenu     run the prompt menu interactively"
  echo "    alias_usage    show usage counts per command"
  echo "    clisting       this list"
}

# Usage tally ─────────────────────────────────────────────────────────────
alias_usage() {
  local usage_file="${HOME}/.custodian_alias_usage.log"
  if [[ ! -f "$usage_file" ]]; then
    echo "No usage data yet."
    return
  fi
  echo "Custodian alias usage counts:"
  for cmd in dryjson runjson runsprite opingest obsreport listbox pixelart matchpal batchstrike opcolor promptmenu opcombo opcontract opaudit opnext oprepair oprepair-report oprepair-smoke opvalidate clisting; do
    local count
    count=$(grep -c "$cmd" "$usage_file" 2>/dev/null || echo 0)
    printf "  %-12s %d\n" "${cmd}:" "${count}"
  done
  echo "---"
  echo "Total: $(wc -l <"${usage_file}") invocations"
}

echo "  Custodian commands ready: croot, cgodot, cpack, opcolor, dryjson, runjson, runsprite, opingest, obsreport, listbox, pixelart, matchpal, batchstrike, promptmenu, opcombo, opcontract, opaudit, opnext, oprepair, oprepair-report, oprepair-smoke, opvalidate, clisting"
echo "  Type 'clisting' for all commands with descriptions, 'alias_usage' for usage counts."
