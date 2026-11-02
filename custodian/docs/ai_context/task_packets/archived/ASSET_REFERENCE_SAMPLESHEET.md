# ASSET REFERENCE SAMPLESHEET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14
- Created: 2026-05-14
- Last updated: 2026-05-14

## Task

Create a script that samples active tilesheets, prop sheets, walls, floors, and active art directories into a single reference samplesheet for new design work.

## Outcome

Designers and agents can regenerate `custodian/content/reference/active_art_samplesheet.png` from active runtime-facing art using one deterministic Python command.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Active runtime/docs files: `custodian/content/`, `custodian/tools/`, `custodian/docs/ai_context/`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed:
  - `custodian/tools/art/build_reference_samplesheet.py`
  - `custodian/content/reference/active_art_samplesheet.png`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Files read but not changed:
  - `custodian/AGENTS.md`
  - `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Out-of-scope areas:
  - Editing source art.
  - Selecting final design palettes manually.
  - Importing the samplesheet as runtime art.

## Constraints

- Determinism concerns: scan order and crop selection must be stable across runs.
- Simulation/UI boundary concerns: none; this is an offline reference tool.
- Asset requirements: uses existing active PNG/WebP art only.
- Compatibility or migration concerns: requires Pillow, already available in the environment.
- Clarifying questions or assumptions: active directories exclude source/archive/pipeline/temp/preview-style folders by default.

## Implementation Plan

1. Add a Pillow-based art utility under `custodian/tools/art/`.
2. Scan active tiles, ruin props, and environment prop directories by default.
3. Infer tile/frame sizes from filenames where possible and sample non-transparent cells.
4. Compose labeled cards into one PNG samplesheet.
5. Generate the initial samplesheet and update AI context indexes.

## Acceptance

- Runtime behavior: no runtime behavior changes.
- Documentation: current state, file index, and task packet index updated.
- Path/reference validation: generated output and script paths exist.
- Manual validation: inspected generated image metadata.
- Automated/headless validation: Python compilation and script execution.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, updated.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: `build_reference_samplesheet.py` with deterministic active-art scanning, non-transparent crop selection, labeled sample cards, and configurable CLI options.
- Validated: `python3 -m py_compile`, `--list-only`, default generation, and output image metadata.
- Deferred: adding a Godot/editor menu entry; CLI regeneration is enough for the current request.

## Next Steps

- Next action: when new active art lands, rerun `python3 custodian/tools/art/build_reference_samplesheet.py`.
- Best starting files: `custodian/tools/art/build_reference_samplesheet.py`, `custodian/content/reference/active_art_samplesheet.png`.
- Required context: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`.
- Validation to run: `python3 -m py_compile custodian/tools/art/build_reference_samplesheet.py` and the default generation command.
- Blockers or open questions: none.
