# Forlorn Ritualant — Underground Authored-Route Migration

**Status:** route migration complete; authored cavern journey V3 implemented
**Decision date:** 2026-07-30

## Decision

The Forlorn-Ritualant encounter is no longer a procgen special room. It is a fixed authored subterranean destination entered through a world cave ingress and loaded through the authored-level route pipeline.

The existing encounter scene remains the encounter-content authority:

`res://game/world/events/ash_bell/forlorn_ritualant_site.tscn`

The new authored Underground wrapper owns level lifecycle, named spawn, camera bounds, boundary rails, and route exfil:

`res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn`

## Authority Boundary

- Procgen may place only the exterior cave ingress marker.
- Procgen does not insert, reserve, clear, or own the `35x27` Ritualant chapel.
- `SpecialRoomRuntimeInserter` must not discover an Ash-Bell Ritualant definition.
- `RouteTraversalManager` and `LevelLoader` own entry, isolation, return, and re-entry.
- The authored Underground scene owns the `112x128` / `3584x4096` cavern, the translated chapel footprint, and the closed playable boundary loop.
- The existing Ash-Bell event scripts continue to own encounter state and presentation.

## Runtime Flow

```text
Generated world
  -> isolated north-edge lift pocket
  -> White Thread Knot acquisition latches a pending surface causeway
  -> player approaches and witnesses the permanent Threadway resolve
  -> cave ingress: DESCEND BELOW
  -> route: forlorn_ritualant_underground
  -> node: ritual_cavern
  -> spawn: Spawn_DescentLanding on the lower terminus of the same lift
  -> authored Underground wrapper
  -> instanced ForlornRitualantSite
  -> board lower lift + E: Exit_ReturnWorld
  -> world origin
```

This surface gate changes access to the exterior ingress only. Procgen owns the
isolated pocket and resolved walkable connector; it never owns or restores the
Ritualant chamber. Any canonical `white_thread_knot` acquisition latches the
run-level causeway milestone without consuming the item. The Underground's own
thread interaction remains encounter content and is not the sole prerequisite
for reaching itself.

## Runtime Files

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

## Retired Procgen Definition

Delete:

`custodian/content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json`

The generic special-room system remains live for other encounters. Its documentation must describe the Ritualant definition as retired rather than current.

## Authored Spatial Contract

- Full Underground: `112x128` authored cells at `32 px` (`3584x4096`), with camera bounds `Rect2(-1792,-2048,3584,4096)`.
- Player-controlled cavern depth is up-screen (`Vector2.UP`); the projected lift still descends down-screen and returns up-screen.
- The existing `35x27` / `1120x864` chapel is instanced at `(0,-1120)`.
- Entry spawn: `(0,1670)`, on the lower lift walk-off position.
- World-return interaction: `(0,1696)`, on the shared lower lift assembly.
- Arrival lift starts at `(0,1440)` and travels down-screen to the dock over `256 px` / `1.10 sec` under the black handoff.
- A closed polygon loop defines the cavern, landing shelf, and chapel connector; debug centerline data is presentation-only.
- The Ritualant scene is instanced at `(0,-1120)`; the old internal exit
  trigger is retired because the authored wrapper owns travel.

## Room Mapper

Open `res://scenes/debug/forlorn_ritualant_underground_mapper.tscn` to edit the chamber rails and its three authoritative spatial records: `descent_landing`, `return_world`, and `encounter_origin`. Press `M` to switch between collision and marker modes, use `1`–`3` or Page Up/Page Down to select a record, left-click to place it, and press Enter or `U` to write the matching constants in the authored-level script.

Enter/`U` also applies the new rails or markers to the running mapper preview
immediately. Marker positions are written into
`forlorn_ritualant_underground.tscn` as well as the script authority, so the
authored scene and runtime constants do not present conflicting coordinates.
Collision rails remain generated from the authoritative boundary loop; the mapper writes
that production authority rather than baking duplicate collision children into
the scene.

The return record directly positions `Exit_ReturnWorld`; there is intentionally no second `Return_CaveMouth` marker. The landing directly positions `Spawn_DescentLanding`, and the encounter origin directly positions the instanced `ForlornRitualantSite`.

## Presentation Scope

The surface and underground levels now share one lift-platform assembly. The
lower terminus provides a short south-to-north landing approach; departure
requires boarding plus E, raises the platform into full black, plays the
resolution-appropriate epilogue, and hands the route off while black so the
existing surface ascent reads as the continuation of one journey. Additional
cavern dressing remains art polish, never a reason to restore special-room
insertion.

The lift captures the Operator into the shared presentation rig, suspends the
live actor, and carries the rider through the authored `176 px` ascent. A
rejected route request rolls the lift, black overlay, presentation, and actor
processing back to their pre-departure state.

The wrapper owns session snapshot delegation for the encounter. Event pressure,
thread/fountain/resolution state, knowledge/dialogue flags, one-shots, resolved
anchors, and local completion state survive snapshot-and-unload re-entry.

## Production presentation assets

Asset V2 family `ritualant_underground_environment` owns 32 canonical states under `custodian/content/tiles/encounters/ritualant_set/underground/`. The runtime stack comprises the repeating far void; three feathered parallax depth panels; mineral and chapel haze; an exact polygon-clipped repeating ground; three cavern rims and the balanced landing apron; chapel connector/outer-blend overlays; fixed wet/fracture details; a non-repeating surface shaft and paired underground arrival shaft; a one-shot distant-chapel proxy; five collisionless foreground occluders; and seven collisionless prop types.

Authored camera zones progress through landing, upper descent, deep cavern, chapel approach, and gameplay release. These presentation systems do not alter `PLAYABLE_BOUNDARY_LOOP`, lift/route authority, navigation, collision, or Ritualant encounter state.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
godot --headless --path . --script res://tools/validation/route_registry_contract_smoke.gd
godot --headless --path . --script res://tools/validation/special_room_insertion_smoke.gd
```

The Ritualant smoke must prove that the authored level and route load, the named spawn resolves, the encounter scene is instanced, a `return_world` exit exists, and the retired special-room JSON is absent.
