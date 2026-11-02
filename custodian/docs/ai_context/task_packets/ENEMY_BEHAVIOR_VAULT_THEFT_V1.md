# Enemy Behavior Vault Theft V1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-25
- Created: 2026-05-25
- Last updated: 2026-05-25

## Task

Add a first-pass behavior-variable enemy system with Operator detection, vault storage theft, escape-with-loot behavior, recoverable stolen resources, debug hooks, and terminal/minimap telemetry.

## Outcome

Human-style enemies can choose storage objectives, open/steal resources, carry loot to exits, drop loot on death, investigate Operator noise, and expose behavior state for debugging without breaking existing wave/combat flows.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/enemy_objective/ENEMY_OBJECTIVE_SYSTEM.md`, `design/02_features/enemy_director/implementation.md`, `design/02_features/_requests/RESOURCE_LOOP_AND_STORAGE_RAIDING.md`
- Active runtime/docs files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, `custodian/game/ui/terminal/terminal_snapshot.gd`, `custodian/game/ui/minimap/`
- Historical reference only: legacy Python-era simulation docs

## Work Surface

- Files or folders expected to change: enemy behavior components/states, vault/storage/pickup scripts/scenes, wave/director debug hooks, operator stealth snapshot, minimap/terminal readouts, current-state/file-index docs
- Files or folders expected to be read but not changed: fabrication/resource definitions, existing resource nodes, existing enemy animation libraries
- Out-of-scope areas: full GOAP, authored vault procgen solve, enemy pathfinding replacement, stealth HUD, fabrication economy redesign

## Constraints

- Determinism concerns: use explicit profile values and stable scoring; no unbounded random decision loops.
- Simulation/UI boundary concerns: vault/enemy systems own resource and behavior state; minimap/terminal are read-only telemetry.
- Asset requirements: use placeholder storage/pickup visuals only.
- Compatibility or migration concerns: existing debug spawn, wave spawning, combat damage/death, inventory, and fabrication must keep loading.
- Clarifying questions or assumptions: active design docs are under `design/02_features/`, not `design/20_features/in_progress/`.

## Implementation Plan

1. Add design authority updates and this packet.
2. Add vault/storage/pickup runtime.
3. Add enemy profile, blackboard, perception, objective sensor, loot carrier, and behavior state machine.
4. Wire grunts/looters into behavior while preserving existing enemy fallback AI.
5. Add Operator stealth/noise snapshot.
6. Add debug commands and terminal/minimap telemetry.
7. Run Godot parse/boot validation.

## Acceptance

- Runtime behavior: looter can steal vault resources, escape with permanent loss, or drop recoverable loot on death.
- Documentation: design docs and AI context reflect the runtime slice.
- Path/reference validation: new scripts/scenes load from `res://`.
- Manual validation: devconsole commands can drive vault and looter checks.
- Automated/headless validation: targeted script checks and `godot --headless --path custodian --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No unless implementation changes system boundaries.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, completed first.

## Completion Notes

- Implemented: VaultManager autoload, VaultStorage, StolenResourcePickup, enemy behavior profile/blackboard/perception/objective/loot carrier components, behavior state machine, grunt scene wiring, behavior-profile wave/debug spawn support, Operator stealth/noise snapshot, minimap loot-carrier marker, terminal vault/threat readouts, and DevConsole commands.
- Validated: targeted Godot check-only runs for touched scripts, `enemy_behavior_vault_smoke.gd`, and full headless boot.
- Deferred: authored vault placement/procgen solve, stealth HUD, richer faction strategy, real looting/search animations, combat-height modifiers, and manual in-game balance/readability pass.

## Next Steps

- Next action: implement runtime v1.
- Best starting files: `custodian/game/actors/enemies/enemy.gd`, `custodian/game/systems/core/systems/wave_manager.gd`, `custodian/game/ui/hud/ui.gd`
- Required context: current enemy pathing/damage and resource ledger/inventory behavior.
- Validation to run: Godot check-only for new scripts plus headless boot.
- Blockers or open questions: none.
