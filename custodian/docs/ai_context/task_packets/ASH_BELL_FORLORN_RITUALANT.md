# Ash-Bell Forlorn-Ritualant Authored Encounter

## Packet Status

- Status: route migration complete; encounter completion V2 implemented and under visual polish
- Completion scope: authored route plus witnessed Threadway access, shared lift termini, explicit travel, data dialogue, and four-action Ritualant encounter
- Owner: agent
- Agent/session: ChatGPT-2026-07-30-underground-migration
- Created: 2026-06-12
- Last updated: 2026-07-30

## Task

Remove the Forlorn-Ritualant encounter from procgen room insertion and make it a fixed authored Underground destination immediately, while preserving the existing encounter scene as its gameplay/presentation authority.

## Outcome

The old `35x27` special-room JSON was deleted. A registered authored level now instances the existing `ForlornRitualantSite`, and a registered one-node route enters it through a deterministic exterior cave ingress and returns to world origin through a scene-owned `return_world` exit.

Procgen retains only exterior ingress placement. It no longer inserts, clears, reserves, or reports the Ritualant chamber in `special_room_sites`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Migration decision: `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md`
- Staged-descent expansion: `design/05_levels/FORLORN_RITUALANT_APPROACH.md`
- Authored-level architecture: `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`
- Existing encounter authority: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`

## Runtime Surface

```text
custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/
  forlorn_ritualant_underground.gd
  forlorn_ritualant_underground.tscn

custodian/content/levels/ash_bell/
  forlorn_ritualant_underground.json

custodian/content/routes/ash_bell/
  forlorn_ritualant_underground_route.json

custodian/tools/validation/levels/
  forlorn_ritualant_underground_smoke.gd
```

Registry changes:

- `custodian/content/levels/levels.json`
- `custodian/content/routes/routes.json`

Retired:

- `custodian/content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json`

## Runtime Contract

- Route ID: `forlorn_ritualant_underground`
- Route node: `ritual_cavern`
- Named spawn: `Spawn_DescentLanding`
- Spawn position: `(0, 332)`, on the authored lower-lift walk-off position
- Route exit: `return_world`
- Chamber/camera footprint: `1120x864 px` (`35x27` at `32 px`)
- Procgen placement role: exterior `north_edge_overlook` ingress only
- Lifecycle: `snapshot_and_unload` / `session`

## Constraints

- The persistent Operator remains owned by the main world and is transferred through `LevelLoader` / `RouteTraversalManager`.
- The production Underground scene contains no Operator, gameplay camera, HUD, or global director.
- The existing Ash-Bell event scripts and scene remain untouched as encounter-content authority.
- No production art is invented for V1.
- The later cave antechamber, lift descent, lower landing, and pre-arena reveal must extend this authored route rather than reintroduce special-room insertion.

## Validation

Added:

`custodian/tools/validation/levels/forlorn_ritualant_underground_smoke.gd`

It checks:

- retired procgen JSON is absent
- production scene extends `AuthoredLevel2D`
- named spawn resolves at the safe landing
- camera bounds remain `1120x864`
- existing Ritualant site is instanced
- scene-owned `return_world` exit exists
- level and route registries resolve the destination and `ritual_cavern` node

Also updated `special_room_insertion_smoke.gd` so an empty definition set is valid and any future Ritualant procgen insertion fails loudly.

Run locally:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
godot --headless --path . --script res://tools/validation/route_registry_contract_smoke.gd
godot --headless --path . --script res://tools/validation/special_room_insertion_smoke.gd
```

These commands were not executed through the GitHub connector because it does not provide a repository checkout or Godot runtime.

## Drift Review

- `design/02_features/procgen/SPECIAL_ROOM_INSERTION.md`: corrected; Ritualant is now documented as retired from procgen.
- `custodian/docs/ai_context/CURRENT_STATE.md`: requires an updated Ritualant runtime-status paragraph.
- `custodian/docs/ai_context/FILE_INDEX.md`: should index the new level, route, migration doc, and smoke.
- `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`: its procgen placement language is superseded by the migration decision and should be marked as historical placement guidance.
- `custodian/docs/ai_context/CONTEXT.md`: no architecture change beyond the already-live authored-level/route pipeline; no update required.

## Next Production Slice

Replace the named temporary animation fallbacks for Ninth Answer, Orra Comes
Late, dissolve, and violent death; replace the procession band with authored
silhouettes; then tune the lower-landing environmental composition in Moment
Forge. The route and interaction authority are no longer deferred.

## Completion V2 Contract

- Knot acquisition records `ash_bell_threadway_unlocked`; it does not mutate
  terrain off-screen.
- A nearby audience witnesses the Threadway, whose completed VFX latches the
  separate `ash_bell_threadway_resolved` milestone and commits terrain once.
- Surface and underground instance one `ash_bell_lift_platform_assembly.tscn`.
- Both termini require boarding plus E; lower body entry never travels.
- Lower departure rises into black, plays state-aware epilogue, then hands off
  to the existing surface ascent.
- Dialogue comes from `forlorn_ritualant_dialogue.json`: ambient captions,
  grouped two-beat manual interaction, and optional BELL / THREAD / ORRA
  topic menus. The local encounter owns these interactions; optional lore is
  not required to leave.
- The broken chapel bell and wrong basin are intentional physical evidence.
- Chamber thread changes ritual state and never grants another Knot.
- Pin Strike, Thread Pull, Ninth Answer, Orra Comes Late, survival, and three
  anchors have reachable runtime contracts.
- The canonical legacy spawn remains `(0,332)` in the authored chapel scene;
  the migrated underground landing spawn is `(0,1670)`. Lower-lift departure
  shows a visible ascent before blackout, and the encounter root uses neutral
  z inheritance so its floor cannot occlude the Operator.
