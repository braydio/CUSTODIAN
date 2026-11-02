# SPRITE INBOX INGEST 2026-05-12

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-12
- Created: 2026-05-12
- Last updated: 2026-05-12

## Task

Create sprite pipeline manifests for the current inbox PNGs and run the manifest-driven ingest pipeline.

## Outcome

The current inbox PNGs are processed into live runtime sprite domains, with source provenance preserved in archive, normalized previews, and logs.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/SPRITE_PIPELINE_SYSTEM.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/ingest_runtime.gd`, `custodian/game/actors/terminal/command_terminal.gd`, `custodian/tools/pipelines/update_operator_curated_resources.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/content/sprites/_pipeline/inbox/`, `custodian/content/sprites/_pipeline/archive/`, `custodian/content/sprites/_pipeline/logs/`, `custodian/content/sprites/_pipeline/normalized/`, `custodian/content/sprites/environment/props/terminal/runtime/body/`, `custodian/content/sprites/operator/runtime/body/ranged_2h/`, `custodian/content/sprites/operator/runtime/overlay/unarmed/`, `custodian/content/sprites/operator/runtime/curated/weapon/ranged_2h/carbine_rifle_mk1/`, `custodian/content/sprites/weapons/carbine_rifle/animations/`, `custodian/game/actors/operator/operator_melee_overlay_frames.tres`, this packet
- Files or folders expected to be read but not changed: sprite pipeline docs, terminal runtime script, operator curated rebuild script
- Out-of-scope areas: wiring the new ranged run body/weapon strips into live operator movement playback, deleting unrelated dirty files

## Constraints

- Determinism concerns: asset ingest only; no simulation logic changes.
- Simulation/UI boundary concerns: no runtime authority moved into UI/rendering.
- Asset requirements: operator sheets must parse as horizontal `96x96` strips; terminal pickup source parses as four `224x128` frames and resizes into `48x48` runtime cells.
- Compatibility or migration concerns: terminal pickup output includes canonical `command_terminal`, current primary `builder_terminal`, and legacy `computer_terminal` compatibility names.
- Clarifying questions or assumptions: ranged run body/weapon strips are additive outputs until a later runtime wiring pass consumes them.

## Implementation Plan

1. Inspect inbox dimensions and runtime consumers.
2. Create sidecar manifests for all inbox PNGs.
3. Run dry-run ingest, actual ingest, Godot import, and path checks.

## Acceptance

- Runtime behavior: ranged 2H horizontal sprinting should use the new dedicated body strip, and the visible ranged weapon overlay should use the new weapon strip.
- Documentation: packet records outputs and assumptions.
- Path/reference validation: generated output paths exist after ingest and import metadata is generated.
- Manual validation: pending in-editor visual review.
- Automated/headless validation: dry-run ingest, actual ingest, and Godot import pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Not for additive ingest only unless runtime wiring changes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No new ownership entrypoint.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No runtime behavior or architecture change in this slice.

## Completion Notes

- Implemented: created sidecar manifests for the current terminal pickup, ranged 2H run body, ranged 2H run weapon, and unarmed east fast FX inbox sheets; ingested them into runtime sprite domains; archived the processed source PNG/JSON pairs; removed stale inbox `.png.import` stubs after archive/runtime imports were generated; wired the new ranged run body strip as `ranged_2h_run_right`; wired the new ranged run weapon strip as `equipped_run_right`; updated horizontal ranged sprint playback to prefer the new body animation.
- Validated: `python custodian/tools/pipelines/ingest.py --dry-run`; `python custodian/tools/pipelines/ingest.py`; `godot --headless --path custodian --import --quit`; `godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd`; `godot --headless --path custodian --quit`; path checks for runtime PNG and `.import` outputs; resource reference checks for `ranged_2h_run_right` and `equipped_run_right`.
- Deferred: in-editor visual review and any future non-east ranged run directional sheets.

## Next Steps

- Next action: visually review ranged 2H horizontal sprinting in editor/gameplay.
- Best starting files: `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/ingest_runtime.gd`
- Required context: this packet and current sprite pipeline README.
- Validation to run: in-editor visual review for terminal pickup/deploy and ranged 2H run playback once wired.
- Blockers or open questions: none for asset ingest.
