# Procgen Wall Top Source Preprocessing

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-04
- Created: 2026-05-04
- Last updated: 2026-05-04

## Task

Add a preprocessing path for `custodian/content/tiles/walls/Wall_Tops.png` so the wall atlas builder can alpha-split
the sheet into connected components and emit top-oriented runtime wall cells through a `--top-source` flag.

## Outcome

`tools/tiles/build_procgen_wall_atlas.py` accepts `--top-source`, top-aligns connected components from the wall-top
sheet into `32x32` cells, and routes them through the existing procgen semantic buckets without requiring manual
pre-slicing.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md`
- Active runtime/docs files: `tools/tiles/build_procgen_wall_atlas.py`, `custodian/assets/tiles/walls/generated/README.md`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files expected to change: `tools/tiles/build_procgen_wall_atlas.py`, wall bridge design doc, generated wall README,
  AI context docs, this packet.
- Files expected to be read but not changed: `custodian/content/tiles/walls/Wall_Tops.png`, generated mapping JSON,
  current procgen scene/runtime files.
- Out-of-scope areas: runtime collision, traversable doorway carving, procgen topology logic.

## Constraints

- Determinism concerns: connected-component ordering and slice placement must remain stable for the same input sheet.
- Simulation/UI boundary concerns: preprocessing only, no runtime gameplay logic changes.
- Asset requirements: filter tiny alpha islands and top-align the cropped components.
- Compatibility or migration concerns: preserve the existing `--passage-dir` flow and current runtime bucket names.
- Clarifying questions or assumptions: treat the wall-top sheet as a visual source sheet, not a direct runtime atlas.

## Implementation Plan

1. Add `--top-source` and optional noise-threshold handling to the atlas builder.
2. Split the wall-top sheet into alpha-connected components and slice them into `32x32` cells with top alignment.
3. Route the new cells into existing semantic buckets and update the generated asset docs.
4. Validate the builder help output and a real generation run.

## Acceptance

- Runtime behavior: the builder can consume `Wall_Tops.png` without manual pre-splitting.
- Documentation: the wall bridge doc and generated README mention the top-source path.
- Path/reference validation: `Wall_Tops.png` is referenced with the new flag in docs.
- Manual validation: inspect the builder help text and the generated mapping output.
- Automated/headless validation: builder help succeeds and the pipeline runs without errors.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md`.

## Completion Notes

- Implemented: `--top-source` support now alpha-splits wall-top sheets into connected components and top-aligns them into runtime cells.
- Validated: `python3 -m py_compile tools/tiles/build_procgen_wall_atlas.py`; `python3 tools/tiles/build_procgen_wall_atlas.py --help`; real atlas generation to `/tmp/procgen_wall_top_test.png` and `/tmp/procgen_wall_top_test.mapping.json`; `godot --headless --path custodian --quit`.
- Deferred: runtime top-source-specific tuning beyond the preprocessing path.

## Next Steps

- Next action: decide whether the top-source cells should be routed into additional curated semantic overrides for corner-heavy sheets.
- Best starting files: `tools/tiles/build_procgen_wall_atlas.py`, `custodian/assets/tiles/walls/generated/README.md`.
- Required context: the active wall bridge design doc and the current generated wall atlas workflow.
- Validation to run: the builder command already passed; follow-up runtime validation is optional because this is preprocessing only.
- Blockers or open questions: whether any top-source buckets should receive extra curated semantic overrides later.
