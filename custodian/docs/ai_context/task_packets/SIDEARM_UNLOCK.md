# Sidearm Unlock

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-06
- Created: 2026-06-06
- Last updated: 2026-06-06

## Task

Implement the Sundered Keep P-9 Field Sidearm unlock from `design/SIDEARM_UNLOCK.md`.

## Outcome

The Operator starts with the sidearm fallback locked, receives the P-9 from a Sundered Keep Great Hall locker/chest, and uses the sidearm only as the ranged-ready fallback when no primary ranged weapon is actively selected.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/SIDEARM_UNLOCK.md`, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/tools/validation/operator_ranged_ready_input_smoke.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: completed sidearm playback/ingest packets in `custodian/docs/ai_context/task_packets/`

## Work Surface

- Files or folders expected to change: Operator sidearm gate, Sundered Keep interactable/reward path and authored level marker, ranged-ready and focused unlock smoke tests, combat feel doc, current-state/index docs, required asset trackers, this packet.
- Files or folders expected to be read but not changed: Sundered Keep validation scripts, sidearm weapon resources, HUD/interactable helpers, required asset trackers.
- Out-of-scope areas: production sidearm animation creation, global save/load persistence, new GameState ownership unless an existing pattern already requires it.

## Constraints

- Determinism concerns: unlock state should be local runtime state and interaction-driven, with no random grant behavior.
- Simulation/UI boundary concerns: Operator owns weapon readiness; Sundered Keep owns map-local interactable and pickup messaging.
- Asset requirements: use existing sidearm resources and keep missing production sidearm animation assets tracked in both `REQUIRED_ASSETS.md` copies.
- Compatibility or migration concerns: active ranged primary must keep priority over sidearm fallback.
- Clarifying questions or assumptions: persist opened/acquired for the run using Sundered Keep local state unless a verified existing autoload inventory pattern is appropriate.

## Implementation Plan

1. Inspect current Operator sidearm and ranged-ready code.
2. Add locked default plus a `grant_sidearm(...)` method.
3. Add Sundered Keep sidearm locker interaction and run-local state.
4. Update smoke validation for locked/granted/primary-priority behavior.
5. Update design/current-state docs and completion notes.

## Acceptance

- Runtime behavior: locked sidearm cannot enter fallback ranged-ready; looting the locker grants P-9 fallback; actively selected ranged primary still wins.
- Documentation: combat-feel and current-state docs describe progression-locked sidearm fallback.
- Path/reference validation: changed docs reference live files.
- Manual validation: not performed unless Godot/editor playtest is requested.
- Automated/headless validation: run targeted Operator and Sundered Keep smoke commands from `design/SIDEARM_UNLOCK.md` when feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No, unless workflow rules change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes; the focused unlock smoke and completed packet are indexed.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`.

## Completion Notes

- Implemented: the Operator starts with the sidearm locked; `grant_sidearm(...)` unlocks the P-9, initializes ammunition when needed, refreshes weapon state, and preserves the selected melee/unarmed loadout. Sundered Keep now builds a one-time field-retention locker at authored tile `[73, 27]`; it only consumes the locker after a successful Operator grant and then disables interaction for the run.
- Validated: Operator ranged-ready smoke covers locked/granted behavior, pistol profile values, non-`ranged_2h` classification, and selected-primary priority. The focused Sundered Keep unlock smoke covers locker availability, successful one-time grant, melee selection preservation, fallback activation, and opened/non-interactable state. Sundered Keep asset, layout, and large-layout smokes pass.
- Deferred: manual editor playtest and production art. The locker currently uses a wet-crate stand-in, and the modular sidearm ready/fire/recover/reload directional suite remains incomplete; both needs are tracked identically in the two `REQUIRED_ASSETS.md` copies.

## Next Steps

- Next action: replace the locker stand-in and complete the modular sidearm animation suite when production assets are supplied.
- Best starting files: `REQUIRED_ASSETS.md`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`, and `custodian/content/sprites/operator/new_operator/modular/sidearm/`.
- Required context: `design/SIDEARM_UNLOCK.md` and `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`.
- Validation to run after future changes: the Operator ranged-ready smoke, focused Sundered Keep sidearm unlock smoke, and Sundered Keep asset/layout smokes.
- Blockers or open questions: no runtime blockers; production assets and a manual playtest remain.
