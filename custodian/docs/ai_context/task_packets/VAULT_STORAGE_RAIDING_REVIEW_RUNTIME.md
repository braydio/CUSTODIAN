# Vault Storage Raiding Review Runtime

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-02
- Created: 2026-06-02
- Last updated: 2026-06-02

## Task

Review the active vault, resource storage, enemy stealing, and enemy behavior specs against the runtime, implement the feasible missing pieces, and create a permanent runtime home for vault construction/storage assets.

## Outcome

Vault storage has a stable runtime asset domain, visible storage state art, damage/vandalism support, and enemy behavior can choose between stealing and sabotaging storage according to profile weights. Missing production assets are tracked in root `REQUIRED_ASSETS.md`.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/enemy_objective/ENEMY_OBJECTIVE_SYSTEM.md`, `design/02_features/enemy_objective/GRUNT_COMBAT_PROFILE.md`, `design/02_features/_requests/RESOURCE_LOOP_AND_STORAGE_RAIDING.md`
- Active runtime/docs files: `custodian/game/actors/storage/`, `custodian/game/systems/core/systems/vault_manager.gd`, `custodian/game/actors/enemies/`, `custodian/content/sprites/environment/props/vault_storage/runtime/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/actors/storage/vault_storage.gd`
  - `custodian/game/actors/storage/vault_storage.tscn`
  - `custodian/game/systems/core/systems/vault_manager.gd`
  - `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`
  - `custodian/game/actors/enemies/components/enemy_behavior_profile.gd`
  - `custodian/game/actors/enemies/components/enemy_objective_sensor.gd`
  - `custodian/content/sprites/environment/props/vault_storage/runtime/`
  - `REQUIRED_ASSETS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Files or folders expected to be read but not changed:
  - `custodian/content/props/gothic/vault_storage/`
  - `custodian/tools/validation/enemy_behavior_vault_smoke.gd`
- Out-of-scope areas:
  - Full GOAP behavior rewrite.
  - Procgen-authored vault room solve.
  - New production art creation.

## Constraints

- Determinism concerns: objective scoring and sabotage timing must use profile exports and local state, not random behavior loops.
- Simulation/UI boundary concerns: storage/vault/enemy scripts own resource and damage state; terminal/minimap remain read-only.
- Asset requirements: use existing vault chest art as runtime-ready placeholders, and request missing per-resource storage prop states plus sabotage animations.
- Compatibility or migration concerns: existing theft, debug vault fallback, terminal snapshots, and minimap loot markers must keep working.
- Clarifying questions or assumptions: existing `content/props/gothic/vault_storage/` files are source/prop-domain art; runtime-facing scenes should use the new `content/sprites/environment/props/vault_storage/runtime/` home.

## Implementation Plan

1. Create the stable vault storage runtime asset folder and point `VaultStorage` at it.
2. Add storage integrity, damaged/destroyed/empty/stored visual state, and manager signals/events for sabotage damage.
3. Extend enemy objective scoring/state machine so sabotage-capable profiles can damage storage instead of only stealing.
4. Update required asset trackers and AI context docs.
5. Run targeted smoke validation plus Godot headless checks.

## Acceptance

- Runtime behavior: enemies can still steal resources, and sabotage-capable enemies can damage storage props through a timed objective action.
- Documentation: current state, file index, task packet, runtime asset README, and required asset trackers describe the new domain and remaining gaps.
- Path/reference validation: `vault_storage.tscn` references stable runtime sprites under `res://content/sprites/environment/props/vault_storage/runtime/`.
- Manual validation: deferred to in-editor raid readability pass.
- Automated/headless validation: targeted vault smoke script and Godot headless boot.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No; required asset tracker plus current state is sufficient for this implementation slice.

## Completion Notes

- Implemented: reviewed the active enemy objective, grunt profile, and resource raiding specs; created `res://content/sprites/environment/props/vault_storage/runtime/` as the permanent vault storage runtime sprite home; promoted current chest empty/stored/open/damaged sprites into that folder; replaced the placeholder `VaultStorage` ColorRect with runtime texture state; added storage integrity, damage/destruction state, visual-state switching, manager damage/destruction events, sabotage objective scoring, and a timed enemy sabotage state.
- Validated: imported new vault runtime PNGs; ran `godot --headless --path custodian --script res://tools/validation/enemy_behavior_vault_smoke.gd`; ran `godot --headless --path custodian --quit`; ran `python3 custodian/tools/validation/content_asset_audit.py --limit 20` and confirmed `root_loose_files=0`, `loose_sprites_or_tiles_files=0`, and `unregistered_files=0`.
- Deferred: production per-resource vault storage state sprites, enemy grunt sabotage animations, enemy grunt carry/loot/escape animations, vault raid audio cues, procgen-authored vault room placement, terminal/minimap sabotage-specific UI polish, and manual in-editor raid readability tuning.

## Next Steps

- Next action: perform an in-editor raid readability pass and wire production sabotage/carry animations when supplied.
- Best starting files: `custodian/game/actors/storage/vault_storage.gd`, `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`, `custodian/game/actors/enemies/components/enemy_objective_sensor.gd`.
- Required context: theft V1 already exists; this slice adds storage damage/sabotage and a stable asset home.
- Validation to run: `godot --headless --path custodian --script res://tools/validation/enemy_behavior_vault_smoke.gd`, `godot --headless --path custodian --quit`, plus manual enemy raid playtest.
- Blockers or open questions: production per-resource storage states, grunt sabotage/carry animation suites, and vault raid audio cues remain missing and are tracked in `REQUIRED_ASSETS.md`.
