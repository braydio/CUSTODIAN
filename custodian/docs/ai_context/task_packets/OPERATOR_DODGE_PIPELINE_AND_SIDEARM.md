# Operator Dodge Pipeline And Sidearm

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-05
- Created: 2026-06-05
- Last updated: 2026-06-05

## Task

Update the Operator animation pipeline to accept split dodge/recovery clips, and add a sidearm inventory-slot fallback so holding aim with no ranged primary equipped readies a default pistol profile.

## Outcome

The runtime accepts a two-phase dodge (`dodge` then `dodge_recovery`) with optional aim-backstep variants, and the Operator can enter ranged-ready through a default pistol sidearm when no primary ranged weapon is equipped. Missing production dodge and sidearm clips are tracked explicitly.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/tools/pipelines/*`, `REQUIRED_ASSETS.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: Operator runtime, sidearm definition resource, sprite pipeline docs/rebuild script, required asset trackers, validation smoke.
- Files or folders expected to be read but not changed: current weapon data/profile files, existing Operator SpriteFrames.
- Out-of-scope areas: full inventory UI, production art creation, separate sidearm ammo economy.

## Constraints

- Determinism concerns: dodge phase timers and weapon profile resolution must remain deterministic.
- Simulation/UI boundary concerns: input and gameplay state remain in Operator runtime; asset pipeline only prepares resources.
- Asset requirements: production dodge/recovery and sidearm clips are needed; runtime uses current ranged placeholders until art arrives.
- Compatibility or migration concerns: keep existing `operator_dodge_step` and carbine ready behavior working.
- Clarifying questions or assumptions: user confirmed pistol default profile and current ranged placeholder animations.

## Implementation Plan

1. Add default sidearm weapon definition and Operator slot fallback for ranged-ready.
2. Add split dodge/recovery runtime support with optional aim-backstep names.
3. Update pipeline docs/rebuild script and required asset trackers for dodge/recovery and sidearm clips.
4. Extend smoke validation for sidearm fallback and recovery phase.

## Acceptance

- Runtime behavior: aiming with no ranged primary can ready the sidearm and use pistol stats/profile.
- Documentation: pipeline names and asset needs are tracked.
- Path/reference validation: new resource paths load in Godot.
- Manual validation: not required.
- Automated/headless validation: Operator script check and ranged-ready smoke.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Combat feel docs should mention sidearm/dodge direction.

## Completion Notes

- Implemented: Added `sidearm_pistol` as a separate ready fallback slot, pistol profile resolution, ranged visual fallback support, split dodge/recovery state, optional backstep tracks, curated rebuild hooks, pipeline docs, and required asset tracking.
- Validated: `godot --headless --path custodian --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --path custodian --script res://tools/validation/operator_ranged_ready_input_smoke.gd`; `python3 custodian/tools/pipelines/generate_inbox_manifests.py --help`.
- Deferred: Production sidearm, directional dodge/recovery, aim-backstep, and modular ranged art remain required assets.

## Next Steps

- Next action: Supply or ingest production sidearm/dodge clips when available.
- Best starting files: `custodian/game/actors/operator/operator.gd`
- Required context: `operator_ranged_ready_input_smoke.gd`
- Validation to run: Godot check-only and smoke script.
- Blockers or open questions: production animation art is still pending.
