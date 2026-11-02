# Task Packet: LAST_ROUTEKEEPER_EVENT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Claude (big-pickle) / 2026-06-12
- Created: 2026-06-12
- Implemented: 2026-06-12
- Last updated: 2026-06-12

## Task

Design and implement The Last Routekeeper — a rare, one-time authored random event inside Sundered Keep where the player recovers the field-survey trace of B. Chaffee, an auxiliary routekeeper who marked a safe return path through the ruined causeway.

## Outcome

- Design doc (`design/02_features/events/LAST_ROUTEKEEPER_EVENT.md`) complete and reviewed.
- Code roadmap (`design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md`) complete with drop-in GDScript, Map patches, autoload config, and REQUIRED_ASSETS.md entries.
- Task packet created.

## Authority

- Root routing: `../design/`
- Local routing: `custodian/docs/ai_context/task_packets/`
- Active design/spec docs: `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md`, `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md`
- Active runtime/docs files: `game/world/sundered_keep/sundered_keep_map.gd`, `game/world/events/ash_bell/` (precedent), `REQUIRED_ASSETS.md`
- Historical reference only: `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md` (for event pattern precedent, not content)

## Work Surface

- Files or folders expected to change:
  - `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md` — design spec (created)
  - `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md` — code roadmap (created)
  - `custodian/docs/ai_context/task_packets/LAST_ROUTEKEEPER_EVENT.md` — this packet
  - `custodian/docs/ai_context/CURRENT_STATE.md` — update to mention new design docs
  - `custodian/docs/ai_context/FILE_INDEX.md` — update references
  - `game/systems/core/state/world_event_memory.gd` — autoload singleton (future implementation)
  - `game/world/events/last_routekeeper/last_routekeeper_event_state.gd` — event state resource (future)
  - `game/world/events/last_routekeeper/last_routekeeper_event.gd` — event controller (future)
  - `game/world/sundered_keep/sundered_keep_map.gd` — event patches (future)
  - `project.godot` — autoload entry (future)
  - `REQUIRED_ASSETS.md` — production art tracking (future)

- Files or folders expected to be read but not changed: Ash-Bell event pattern files, existing Sundered Keep runtime

- Out-of-scope areas: Implementation of runtime code; production art creation; procgen special-room integration (deferred to V2)

## Constraints

- Determinism concerns: Event uses deterministic seeded RNG via `WorldEventMemory.get_event_seed()` with salt, not raw `randf()`. Must be reproducible from same run seed.
- Simulation/UI boundary concerns: Non-combat event. No simulation state changes beyond world memory tracking. Player-facing text is logged, not NPC dialogue.
- Asset requirements: Placeholder Polygon2D visuals when production sprites absent. Production art tracked in `REQUIRED_ASSETS.md`.
- Compatibility or migration concerns: Must not break existing Sundered Keep runtime. Event is opt-in hook after main gate opens. Zero interaction with siege loop, combat, or key/gate progression.
- Clarifying questions or assumptions: B. Chaffee is not an NPC, companion, or quest-giver — this is a residual trace, not a living character.

## Implementation Plan

### Phase A — Design (complete)

1. Write `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md` with event summary, design goals, runtime anchors, trigger conditions, event sequence, player-facing text, runtime architecture, production assets, and validation checklist.
2. Write `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md` with drop-in GDScript files, map patches, autoload config, bridge methods, and REQUIRED_ASSETS.md entries.
3. Create this task packet.

### Phase B — Context Pack Update (current)

4. Update `custodian/docs/ai_context/CURRENT_STATE.md` to reference the new design docs.
5. Update `custodian/docs/ai_context/FILE_INDEX.md` to index the new design docs.

### Phase C — Implementation (deferred)

6. Create `game/systems/core/state/world_event_memory.gd` — autoload singleton.
7. Create `game/world/events/last_routekeeper/last_routekeeper_event_state.gd`.
8. Create `game/world/events/last_routekeeper/last_routekeeper_event.gd`.
9. Patch `game/world/sundered_keep/sundered_keep_map.gd` with event constants, exports, state vars, spawn/roll methods, hint reveal, interaction routing, HUD prompt, and bridge methods.
10. Patch `project.godot` with WorldEventMemory autoload.
11. Update `REQUIRED_ASSETS.md` with routekeeper production art entries.

## Acceptance

- Runtime behavior: Event does not spawn before Main Gate opens (unless forced). Deterministic roll uses seeded hash. Interaction shows ROUTEKEEPER TRACE prompt. Recovery prints route notes. Hint marker appears at `routekeeper_hint_tile`. Event marks complete permanently. No respawn on revisit.
- Documentation: Design spec, code roadmap, task packet, CURRENT_STATE.md, FILE_INDEX.md all reference the new event.
- Path/reference validation: All script paths in design are valid `res://` paths.
- Manual validation: See Section 9 of design spec (10-point checklist).
- Automated/headless validation: `godot --headless --check-only --quit` must pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes — add reference to design/02_features/events/LAST_ROUTEKEEPER_EVENT.md
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No — the event fits existing lore/runtime patterns
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes — add index entry for the two new design docs
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? No — both design docs are complete

## Completion Notes

- Implemented: Design spec, code roadmap, task packet, autoload, event state resource, event controller, all sundered_keep_map.gd patches, project.godot autoload, REQUIRED_ASSETS.md entries.
- Validated: `godot --headless --check-only --quit` passes (no script errors; only pre-existing resource leak warnings).
- Deferred: Production art (3 residual projection animations, 4 routekeeper props/decals). Procgen special-room insertion (V2).

## Next Steps

- Next action: Implement Phase C — create the autoload, event scripts, map patches, and REQUIRED_ASSETS.md updates.
- Best starting files: `game/systems/core/state/world_event_memory.gd`, then `game/world/events/last_routekeeper/last_routekeeper_event_state.gd`, then `game/world/events/last_routekeeper/last_routekeeper_event.gd`, then `sundered_keep_map.gd`, then `project.godot`, then `REQUIRED_ASSETS.md`.
- Required context: `design/02_features/events/LAST_ROUTEKEEPER_EVENT.md`, `design/02_features/events/LAST_ROUTEKEEPER_EVENT_CODE.md`, `game/world/events/ash_bell/` for pattern reference, `game/world/sundered_keep/sundered_keep_map.gd` to understand existing map interaction flow.
- Validation to run: `godot --headless --check-only --quit` after each implementation step.
- Blockers or open questions: None for design phase.
