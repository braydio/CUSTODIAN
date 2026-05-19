# Ash-Bell Forlorn-Ritualant Encounter Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14 Ash-Bell implementation
- Created: 2026-05-14
- Last updated: 2026-05-16

## Task

Implement the feasible runtime slice from the Forlorn-Ritualant / Ash-Wrapped Penitent design documents under `design/`, centered on a minimum shippable authored Ash-Bell encounter.

## Outcome

The project has a loadable Ash-Bell event module with event state, placeholder authored site scene, Forlorn-Ritualant NPC behavior hooks, white-thread hazard, interaction routing, dialogue/item data, and a special-room definition for later procgen insertion.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/FORLORN_RITUALANT_ENCOUNTER.md`, `design/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`, `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`
- Active runtime/docs files: `custodian/game/world/events/ash_bell/`, `custodian/content/dialogue/ash_bell/`, `custodian/content/items/lore/`, `custodian/content/procgen/special_rooms/`, `REQUIRED_ASSETS.md`
- Historical reference only: legacy Python runtime/docs

## Work Surface

- Files or folders expected to change: Ash-Bell event scripts/scene/data, AI context docs, required asset trackers
- Files or folders expected to be read but not changed: enemy actor/factory/wave systems, interaction patterns, validation recipes
- Out-of-scope areas: full boss art, final audio, rare-room procgen insertion, inventory/knowledge persistence integration

## Constraints

- Determinism concerns: encounter state is local and data-driven; no non-deterministic spawn or wave mutation in this slice.
- Simulation/UI boundary concerns: the scene emits item/knowledge/dialogue signals and prints/fallback-labels locally; persistent inventory/archive UI integration remains deferred.
- Asset requirements: production Ash-Bell props, NPC animation, apparition/procession art, and audio are missing and must be tracked.
- Compatibility or migration concerns: special-room JSON points to the new scene but no generic special-room inserter exists yet.
- Clarifying questions or assumptions: use placeholder ColorRect geometry and signals until production art/content systems are available.

## Implementation Plan

1. Add Ash-Bell event state and site/NPC/hazard/interactable trigger scripts.
2. Add a loadable placeholder authored site scene and data files for dialogue, lore items, and special-room metadata.
3. Update required asset trackers and AI context docs.
4. Run targeted Godot script/scene validation and diff checks.

## Acceptance

- Runtime behavior: scene loads, proximity trigger can start dialogue, interactions update state, fountain apparition changes visibility, thread hazard increments tension, clapper/thread interactions emit reward hooks.
- Documentation: task packet and AI context mention the new event module and deferred integration.
- Path/reference validation: new scene/data paths match the design paths or documented current paths.
- Manual validation: deferred; requires opening scene in editor/play and exercising triggers with an operator.
- Automated/headless validation: run Godot check/load commands for new scripts and scene.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, new implemented slice.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, new event/data ownership.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No; implementation follows existing docs and tracks deferred assets.

## Completion Notes

- Implemented: Ash-Bell event state, site controller, placeholder authored scene, Forlorn-Ritualant NPC, white-thread hazard, interaction/trigger routing, dialogue JSON, lore-item JSON, special-room metadata, temporary live-review spawner in `scenes/game.tscn`, validation smoke script, required asset tracker entries, AI context index/current-state updates, and a follow-up dev-placement fix that moves the temporary room north of the operator with a south doorway approach.
- Validated: `godot --headless --path custodian --check-only --script` for all new event scripts; `godot --headless --path custodian --script res://tools/validation/ash_bell_scene_smoke.gd`; JSON syntax checks for dialogue, item, and special-room data; `cmp -s REQUIRED_ASSETS.md design/00_meta/REQUIRED_ASSETS.md`; `git diff --check`; full `godot --headless --path custodian --quit` boot with only the existing object/resource leak warnings.
- Deferred: production art/audio, full inventory/archive persistence, full boss attack set, and proper rare-room insertion into procgen. The current in-game path is explicitly temporary via `AshBellDevSpawner`. Direct headless scene launch with a scene path crashed inside Godot log setup, so scene validation uses the checked-in ResourceLoader smoke script instead.

## Next Steps

- Next action: wire production Ash-Bell art/audio when supplied, then add special-room insertion support to procgen.
- Best starting files: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`, `custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd`
- Required context: `design/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`
- Validation to run: `godot --headless --path custodian --script res://tools/validation/ash_bell_scene_smoke.gd`, then `godot --headless --path custodian --quit`
- Blockers or open questions: production assets and persistent reward systems are not yet available.
