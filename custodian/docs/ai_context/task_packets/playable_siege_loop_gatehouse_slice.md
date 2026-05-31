# Playable Siege Loop + Gatehouse Objective Slice

## Packet Status

- Status: in_progress
- Owner: Codex
- Agent/session: Codex 2026-05-31
- Created: 2026-05-31
- Last updated: 2026-05-31

## Status

in_progress

## Owner

Codex

## Runtime Scope

Active runtime:

- `custodian/`

Active design authority:

- `design/20_features/in_progress/`
- `python-sim/design/MASTER_DESIGN_DOCTRINE.md` as locked master doctrine/reference
- `custodian/docs/ai_context/` for active AI context tracking

Legacy reference only:

- `python-sim/game/`
- `python-sim/custodian-terminal/`
- `python-sim/ai/`

Do not treat legacy Python runtime as active gameplay authority.

## Objective

Connect the existing in-progress Godot systems into one playable, deterministic vertical slice:

- wave spawning
- enemy objective routing
- enemy behavior director
- sector/objective damage
- repair gameplay
- turret or defensive helper behavior
- combat-feel/debug feedback
- a Sundered Keep / gatehouse objective flow

The target result is a playable test slice where the player can approach a locked gate, satisfy an unlock condition, open the gate, trigger enemy pressure, observe sector/objective damage, repair damage, and see turret/defense behavior participate.

This is a convergence pass, not a new-art pass.

## Non-Goals

Do not create production art.

Do not invent missing animation assets.

Do not bind large master sheets directly into runtime animation resources.

Do not rewrite the whole player, enemy, map, inventory, or procgen architecture unless discovery proves there is no usable existing structure.

Do not move active runtime authority back into `python-sim/`.

Do not silently ignore documentation drift.

Do not mark any design doc complete unless the acceptance checks for that system are actually met.

## Assumptions

- Existing art/assets are preferred over new assets.
- Placeholder nodes/resources are acceptable if clearly named and documented.
- The gate objective should be item-gated if an inventory/item/key system already exists.
- If no inventory/key system exists, implement the smallest deterministic gate-token/objective-flag mechanism and document it as temporary.
- If full combat damage is incomplete, implement a minimal deterministic damage event bridge without pretending it is final.
- The first implementation should favor clarity and inspectability over cleverness.
- Simulation state owns truth; UI/debug display only reads state.
- Fixed-step simulation should remain deterministic.
- Rendering and UI must not own simulation authority.

## Primary Player Flow

1. Player starts outside or near a Sundered Keep / gatehouse approach.
2. Main gate starts closed, locked, and blocking.
3. Player approaches the gate and sees a legible interaction/debug prompt.
4. Player discovers or activates the unlock condition.
5. Player returns to the gate and opens it.
6. Gate changes from closed/blocking to open/passable.
7. Enemy wave pressure begins or escalates.
8. Enemies receive objectives through the objective/director system.
9. Enemy pressure damages a sector, gate, mooring, or objective state.
10. Player can repair or mitigate the damage.
11. A turret or defensive helper participates.
12. Debug/objective feedback shows the current state clearly.

## Candidate Feature Specs To Inspect In Phase 2

Read these before implementation:

```text
design/20_features/in_progress/WAVE_SPAWNING_SYSTEM.md
design/20_features/in_progress/ENEMY_OBJECTIVE_SYSTEM.md
design/20_features/in_progress/ENEMY_BEHAVIOR_DIRECTOR.md
design/20_features/in_progress/TURRET_SYSTEM.md
design/20_features/in_progress/SECTOR_DAMAGE_SYSTEM.md
design/20_features/in_progress/COMBAT_FEEL_SYSTEM.md
design/20_features/in_progress/REPAIR_GAMEPLAY_SYSTEM.md
```

If any are missing, record that in the drift report and continue with the closest existing active design source.

## Candidate Runtime Areas To Inspect In Phase 2

Search for existing systems before creating anything new:

```text
custodian/game/
custodian/content/
custodian/docs/ai_context/
custodian/project.godot
```

Search terms:

```text
wave
spawn
spawner
objective
director
turret
repair
sector
damage
gate
door
interact
InputMap
collision
TileMap
TileMapLayer
Navigation
nav
enemy
player
```

## Expected Architecture Direction

Prefer existing files if equivalent systems already exist.

If no equivalent structure exists, use this kind of organization:

```text
custodian/game/world/objectives/
  objective_state.gd
  objective_controller.gd
  gatehouse_objective.gd

custodian/game/world/interactions/
  interactable.gd
  interaction_prompt.gd
  gate_interactable.gd
  repair_interactable.gd

custodian/game/world/siege/
  wave_spawn_controller.gd
  enemy_objective_router.gd
  sector_damage_controller.gd
  turret_controller.gd

custodian/content/world/objectives/
  gatehouse_objective_config.json

custodian/content/world/waves/
  gatehouse_wave_config.json
```

Do not duplicate equivalent systems. Extend or bridge the existing runtime instead.

## Required Drift Checks During The Full Task

During the later implementation phases, check for documentation/runtime drift and record findings.

Minimum drift categories:

1. Docs that reference missing files.
2. Runtime files that appear authoritative but are missing from `custodian/docs/ai_context/FILE_INDEX.md`.
3. Design docs that name systems/files that no longer exist.
4. Runtime systems that exist but have no design/status mention.
5. Input actions referenced in code but missing from `custodian/project.godot`.
6. Scenes/resources referenced by `.tscn`, `.tres`, `.gd`, or content manifests that do not exist.
7. JSON parse errors under `custodian/content`.
8. PNG/runtime assets with suspicious dimensions, huge transparent margins, or invalid tile canvases.

Do not over-fix unrelated asset issues during the gameplay implementation. Fix blockers. Record the rest.

## Acceptance Checks For Final Implementation

The full task is not complete until these are true or explicitly documented as blocked:

* Player can load the test/prototype scene.
* Player can approach a locked gate or gatehouse objective.
* Gate starts closed/blocking.
* Player can obtain or trigger the required gate unlock condition.
* Gate state changes from locked/closed to open/passable.
* At least one enemy wave can spawn from data/config.
* Enemies receive an objective from the objective/director system.
* Sector/objective damage is represented in runtime state.
* Repair interaction can restore or mitigate damaged state.
* Turret or defensive helper has visible/inspectable gameplay participation.
* Debug/UI feedback makes current objective state legible.
* Required input actions exist in `project.godot`.
* Godot validation has been attempted.
* Runtime drift check has been attempted.
* Relevant design docs are updated.
* `custodian/docs/ai_context/CURRENT_STATE.md` is updated.
* `custodian/docs/ai_context/FILE_INDEX.md` is updated if new files or ownership paths are added.
* Manual test steps are written.

## Validation Commands To Determine Later

During implementation, inspect `custodian/docs/ai_context/VALIDATION_RECIPES.md` if present.

Likely validation commands:

```bash
cd custodian
godot --headless --check-only project.godot
```

If that command is unsupported by the local Godot version, record the actual failure and use the repo's documented validation command instead.

If a Python drift script is added later:

```bash
python -m py_compile custodian/tools/validation/check_runtime_drift.py
python custodian/tools/validation/check_runtime_drift.py
```

Do not claim runtime validation passed unless the command was actually run.

## Required Final Response Format For The Full Task

When the full task is later implemented, respond with:

```markdown
## Implemented

- ...

## Files Changed

- ...

## How To Test

1. ...
2. ...

## Validation Run

- Command:
- Result:

## Documentation Drift Found

- Fixed:
- Still open:

## Asset Requests

- Path:
- Animation / asset needed:
- Gameplay purpose:

## Recommended Next Codex Task

...
```

## Phase 1 Notes

- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` exists and requires packet metadata; this packet includes `Packet Status` fields for status, owner, session, created date, and last updated date.
- `custodian/docs/ai_context/task_packets/` already exists or was created for this packet.
- Phase 1 did not inspect runtime gameplay systems beyond the requested guidance/context commands.
- Initial `git status --short` showed pre-existing modified/deleted/untracked files outside this packet; they were not changed by this phase.

## Phase 1 Exit Criteria

This Phase 1 is complete when:

* `custodian/docs/ai_context/task_packets/playable_siege_loop_gatehouse_slice.md` exists.
* The packet includes objective, assumptions, non-goals, acceptance checks, drift checks, validation expectations, and final response format.
* No runtime gameplay code has been changed.
* `git diff -- custodian/docs/ai_context/task_packets/playable_siege_loop_gatehouse_slice.md` shows the created packet.
* Any missing expected template/context file is noted in the command output or appended under the packet section `Phase 1 Notes`.
