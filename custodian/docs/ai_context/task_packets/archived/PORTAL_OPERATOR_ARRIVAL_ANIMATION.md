# PORTAL OPERATOR ARRIVAL ANIMATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-12
- Created: 2026-05-12
- Last updated: 2026-05-12

## Task

Ingest the inboxed unarmed operator arrival animation and play it on the operator after portal teleport arrival.

## Outcome

The south-facing 9-frame unarmed arrival sheet is a runtime operator body asset, rebuilt into `operator_runtime_frames.tres` as `unarmed_arrival` and `unarmed_arrival_down`, and `PortalTeleporter` asks the operator to play that one-shot immediately after moving them to the linked portal landing point.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md`, `design/02_features/animation/WEAPON_OWNED_ANIMATION_SYSTEM.md`
- Active runtime/docs files: `custodian/content/sprites/_pipeline/README.md`, `custodian/tools/pipelines/ingest.py`, `custodian/tools/pipelines/update_operator_curated_resources.gd`, `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/actors/operator/operator.gd`

## Work Surface

- Changed files: operator arrival runtime sprite asset, operator runtime frames, operator animation playback, portal teleport handoff, sprite pipeline archive, this packet, current state.
- Out-of-scope areas: new directional arrival sheets, combat animation state machine refactor, manual visual tuning.

## Constraints

- Determinism concerns: teleport position remains unchanged; the new behavior is visual/input lock only after relocation.
- Simulation/UI boundary concerns: portal teleport authority stays in `PortalTeleporter`; the operator owns body animation playback.
- Asset requirements: the source sheet is `864x96`, parsed as nine `96x96` frames.
- Clarifying questions or assumptions: only a south-facing arrival sheet exists, so portal arrival forces the operator visual direction down during the one-shot.

## Implementation Plan

1. Add a sidecar manifest for the inbox arrival sheet.
2. Extend the curated operator frame rebuild script with `unarmed_arrival` and `unarmed_arrival_down`.
3. Add an operator one-shot playback hook that suppresses normal locomotion/input animation until the clip finishes.
4. Call the hook after portal relocation and validate with targeted Godot checks.

## Acceptance

- Runtime behavior: after teleport relocation, the operator plays the unarmed arrival body clip once.
- Runtime behavior: normal movement and weapon overlays do not overwrite the arrival clip before it finishes.
- Asset pipeline: source PNG/JSON are archived, runtime PNG and `.import` exist, and `operator_runtime_frames.tres` contains the new animation names.
- Automated/headless validation: dry-run ingest, actual ingest, Godot import, and targeted script checks pass.

## Completion Notes

- Implemented: ingested `operator__body__unarmed__arrival_01__s__9f__96.png`, added `unarmed_arrival` and `unarmed_arrival_down` SpriteFrames entries, added `play_portal_arrival_animation()` to the operator, and queued it from portal teleport arrival.
- Validated: `python tools/pipelines/ingest.py --dry-run --manifest content/sprites/_pipeline/inbox/operator__body__unarmed__arrival_01__s__9f__96.json`; `python tools/pipelines/ingest.py --manifest content/sprites/_pipeline/inbox/operator__body__unarmed__arrival_01__s__9f__96.json`; `godot --headless --path . --import --quit`; `godot --headless --path . --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --path . --check-only --script res://game/world/procgen/portal_teleporter.gd`; `rg unarmed_arrival game/actors/operator/operator_runtime_frames.tres`.
- Deferred: in-editor visual review of the arrival timing against portal arrival FX.

## Next Steps

- Next action: visually test portal traversal in Godot and tune the arrival FPS or portal arrival delay if the body clip feels early or late against the destination FX.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/actors/operator/operator.gd`
- Required context: current portal single-state-sprite model and platform-horizon occlusion behavior.
- Validation to run: in-editor portal traversal.
