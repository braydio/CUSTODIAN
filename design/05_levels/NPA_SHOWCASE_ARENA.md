# NPA Showcase Arena

**Level ID:** `npa_showcase_arena`
**Region:** `dev`
**Status:** playable five-zone development foundation; actor sockets intentionally empty

## Intent

Provide a safe, registered proving ground for later NPA showcase slices. The current foundation is a bounded five-room walkable blockout with no fabricated actors or duplicate gameplay authorities. Each room has a disabled scenario root and empty actor sockets for later reviewed integrations.

## Zones and Current Scope

| Zone | Purpose | Current content |
| --- | --- | --- |
| Arrival / Orientation | entry, control orientation, return | `Spawn_Main`, `Return_Main`, open route lane |
| Reaction / Parry | future real reaction and parry scenarios | empty Broken Warrant socket and disabled scenario root |
| Dash / Pounce | future real Marine and Savage ability scenarios | empty Marine and Savage sockets and disabled scenario root |
| Allegiance / Orders | future real wild/allegiance and order scenarios | empty Vaultwing and Escort Frame M-7 sockets and disabled scenario root |
| Death / Corpse / Loot | future real lifecycle and reward scenario | empty disabled scenario root; no simulated corpse or loot |

Rooms are joined by 224px open doorways in the authored collision rails. One outer boundary and those doorway-separated dividers are rebuilt through `AuthoredLevel2D`; floors and path lanes are visual-only. Scenario roots remain process-disabled until a later task adds a real owner and explicitly enables a scenario.

## Entry And Return

- Main entry: `Spawn_Main`
- Return anchor: `Return_Main`
- Ingress prompt: `ENTER NPA SHOWCASE ARENA`

## Authoring

- Production scene: `res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.tscn`
- Playtest scene: `res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena_playtest.tscn`
- Collision/POI mapper: `res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena_authoring.tscn`

## Runtime Ownership

The production scene contains only level geometry, marker/socket nodes and empty scenario roots. The standalone playtest scene supplies exactly one Operator, PlayerController and Camera2D, plus the regular Combat, NavigationSystem, EnemyDirector and WaveManager roots. The registered level ingress targets `Spawn_Main`; `return_world` requests the existing route manager's exit and returns the same persistent Operator. Lifecycle is `snapshot_and_unload` / `reset_on_entry`.


## Next Agent Slice

- **Workstream:** `npa-showcase-existing-enemy-hardening` (paired with `review-npa-showcase-existing-enemy-hardening`).
- **Goal:** Prove and improve Grunt, Marine and Savage as deterministic real combat fixtures before implementing the derivative Broken Warrant.
- **Files:** Existing `enemy_grunt`, `enemy_marine`, and `enemy_savage` scenes and their current ability/lifecycle owners; `custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd`; focused validation manifest entries.
- **Constraints:** Drive public semantic ability requests; do not mutate private timers, add duplicate combat authority, change factory/wave behavior, or populate the arena's production actor sockets in this slice.
- **Acceptance:** Reproducible Grunt melee/stagger/parry-critical/lethal-corpse flow, Marine Dash contact/recovery, Savage pounce/two-hit chain, and once-only corpse loot; any correction has a failing regression first and preserves authored tuning.
