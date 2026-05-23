# PORTAL AND MOVING ATTACK SPRITE INGEST

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Clean and ingest the latest sprite pipeline inbox sheets for melee moving fast attack layers, unarmed east fast FX, and portal teleport FX.

## Outcome

The pipeline inbox has been processed into runtime sprite domains, with corrected portal frame counts and source provenance preserved in archive, logs, and normalized previews.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/ingest_runtime.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/content/sprites/_pipeline/archive/`
  - `custodian/content/sprites/_pipeline/logs/`
  - `custodian/content/sprites/_pipeline/normalized/`
  - `custodian/content/sprites/operator/runtime/body/melee/`
  - `custodian/content/sprites/operator/runtime/overlay/melee/`
  - `custodian/content/sprites/operator/runtime/overlay/unarmed/`
  - `custodian/content/sprites/weapons/fallen_star_katana/animations/`
  - `custodian/content/sprites/effects/runtime/portal_ring/`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/sprites/_pipeline/README.md`
  - `custodian/tools/pipelines/README.md`
- Out-of-scope areas:
  - wiring portal FX playback
  - wiring moving attack layer composition
  - deleting unrelated dirty worktree files

## Constraints

- Determinism concerns: asset ingest only; no simulation logic changed.
- Simulation/UI boundary concerns: no runtime authority moved into UI.
- Asset requirements: horizontal transparent strips.
- Compatibility or migration concerns: source filenames for portal sheets used `193`, but actual frame dimensions are `161x98`; output filenames use corrected frame counts with `161` token.
- Clarifying questions or assumptions: no `teleort` file was present under `custodian/`; duplicate baked `operator__body__melee__moving_fast_01__e__8f__96` inbox PNG/import plus noncanonical Aseprite source were removed from the ingest set.

## Implementation Plan

1. Inspect current inbox and frame dimensions.
2. Remove duplicate baked moving-fast source and look for typo `teleort`.
3. Remove opaque white first-frame artifact from `teleport__activate`.
4. Create sidecar JSON manifests.
5. Dry-run ingest, run ingest, import generated assets, and verify outputs.

## Acceptance

- Runtime assets: melee moving fast body/weapon outputs exist.
- Runtime assets: unarmed east fast FX output exists.
- Runtime assets: portal idle, activate, and arrival FX outputs exist with corrected frame counts.
- Documentation: packet records corrections and validation.
- Automated/headless validation: dry-run ingest, actual ingest, and Godot import pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No new ownership files.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: removed duplicate baked moving-fast inbox source; cleaned opaque white pixels from the first portal activation frame; added manifests; ingested melee moving-fast body/weapon, unarmed fast east FX, and portal teleport idle/activate/arrival FX into runtime domains.
- Validated: `python custodian/tools/pipelines/ingest.py --dry-run`; `python custodian/tools/pipelines/ingest.py`; `cd custodian && godot --headless --import --quit`; verified output dimensions and `.import` files.
- Deferred: portal FX playback and moving attack layer composition still need runtime wiring.

## Next Steps

- Next action: wire portal FX playback on idle/activation/arrival.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: generated `effects/runtime/portal_ring/` sheets.
- Validation to run: in-editor portal walk-through test.
- Blockers or open questions: none for ingest; runtime playback still needs implementation.
