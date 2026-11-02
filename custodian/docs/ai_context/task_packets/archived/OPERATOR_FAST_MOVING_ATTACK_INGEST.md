# OPERATOR FAST MOVING ATTACK INGEST

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Ingest the latest operator melee fast moving attack layer sheets from the sprite pipeline inbox and summarize the next modular animation authoring list.

## Outcome

The latest moving fast attack body, weapon, and FX sheets are processed through the sprite intake pipeline into runtime sprite domains, with provenance preserved in archive, normalized previews, and logs.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/COMBAT_FEATURE_CHANGES.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/ingest_runtime.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/sprites/_pipeline/archive/`
  - `custodian/content/sprites/_pipeline/logs/`
  - `custodian/content/sprites/_pipeline/normalized/`
  - `custodian/content/sprites/operator/runtime/body/melee/`
  - `custodian/content/sprites/operator/runtime/overlay/melee/`
  - `custodian/content/sprites/weapons/fallen_star_katana/animations/`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/_pipeline/README.md`
  - `custodian/tools/pipelines/README.md`
  - `custodian/tools/pipelines/ingest_runtime.gd`
- Out-of-scope areas:
  - runtime code wiring for modular overlay composition
  - replacing current `SpriteFrames` mappings
  - deleting unrelated dirty worktree files

## Constraints

- Determinism concerns: asset ingest only; no simulation logic changes.
- Simulation/UI boundary concerns: no runtime authority moved into UI/rendering.
- Asset requirements: source PNGs must be horizontal `96x96` frame strips.
- Compatibility or migration concerns: runtime outputs are additive until operator animation composition is rewired to consume them.
- Clarifying questions or assumptions: source files were named `7f`, but dimensions are `864x96`, so ingest preserved all 9 frames and wrote corrected `9f` runtime outputs.

## Implementation Plan

1. Inspect sprite pipeline docs and current inbox files.
2. Create sidecar manifests for the latest moving fast attack body, weapon, and FX sheets.
3. Dry-run and then run ingest for each manifest.
4. Run Godot import for generated runtime PNGs.
5. Summarize the modular animation list and validation results.

## Acceptance

- Runtime behavior: no runtime behavior changed in this slice.
- Documentation: packet records ingested assets and frame-count correction.
- Path/reference validation: generated runtime output paths exist.
- Manual validation: pending in-editor visual review.
- Automated/headless validation: pipeline dry-runs, ingest runs, and Godot import pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No runtime behavior changed.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No new ownership entrypoint.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Not for ingest only; modular overlay implementation should update design docs when runtime wiring changes.

## Completion Notes

- Implemented: created sidecar manifests for the latest moving fast attack body, weapon, and FX inbox sheets; ingested them into corrected `9f` runtime outputs under operator body/overlay paths and the Fallen Star Katana animation domain; preserved source provenance in archive, logs, and normalized previews.
- Validated: dry-run ingest passed for all three manifests; actual ingest completed for all three manifests; `godot --headless --import --quit` generated `.import` metadata for the new runtime PNGs.
- Deferred: runtime code still needs a modular composition pass before these sheets are consumed by active attack playback.

## Next Steps

- Next action: wire modular lower-body plus attack overlay composition after reviewing the ingested sheets.
- Best starting files: `custodian/game/actors/operator/operator.gd`, `custodian/tools/pipelines/update_operator_curated_resources.gd`
- Required context: moving attack profile task packet, operator animation overlay sprites, current melee fast mapping.
- Validation to run: `cd custodian && godot --headless --quit`, plus in-editor moving attack visual review.
- Blockers or open questions: whether to consume the full 9-frame fast moving strip as-is or trim/remap it during the modular overlay implementation.
