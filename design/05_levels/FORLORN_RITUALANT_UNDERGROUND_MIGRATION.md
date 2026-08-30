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
- Procgen does not insert, reserve, clear, or own the `40x30` Ritualant chapel.
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
- The `40x30` / `1280x960` chapel is instanced at `(0,-1120)`, yielding
  `Rect2(-640,-1600,1280,960)` and meeting the connector at `y=-640`.
- Entry spawn: `(0,1670)`, on the lower lift walk-off position.
- World-return interaction: `(0,1696)`, on the shared lower lift assembly.
- Surface visible descent is `176 px`, owned by `AshBellLiftIngressPresentation`.
- Underground arrival/departure travels `256 px` between `y=1440` and `y=1696`.
- Underground arrival holds full black for `0.20 sec`, reveals the shaft over
  `0.50 sec`, holds the established composition for `0.15 sec`, travels the
  visible `256 px` over `1.35 sec`, then settles/fades the shaft over `0.30 sec`.
- Underground departure holds for `0.20 sec`, travels the first `128 px` over
  `0.70 sec` fully visible, travels the final `128 px` over `0.75 sec` while
  black takes authority, then holds full black for `0.25 sec` before handoff.
- `Exit_ReturnWorld` uses a `64 px` interaction distance and `56 px`
  arrival-release guard. Local lower-lift boarding containment mirrors the
  surface `223x16` backstop and paired `48x18` front wings without moving
  collision authority into the shared assembly.
- A closed polygon loop defines the cavern, landing shelf, and chapel connector; debug centerline data is presentation-only.
- The Ritualant scene is instanced at `(0,-1120)`; the old internal exit
  trigger is retired because the authored wrapper owns travel.

## Room Mapper

Open `res://scenes/debug/forlorn_ritualant_underground_mapper.tscn` for the
canonical visual diagnostic of gameplay, collision, camera, transition, and
art alignment. The existing rail/marker authoring workflow remains available:
press `M` to switch modes, use `1`–`3` or Page Up/Page Down to select
`descent_landing`, `return_world`, or `encounter_origin`, left-click to place
it, and press Enter or `U` to write the matching authority.

Enter/`U` also applies the new rails or markers to the running mapper preview
immediately. Marker positions are written into
`forlorn_ritualant_underground.tscn` as well as the script authority, so the
authored scene and runtime constants do not present conflicting coordinates.
Collision rails remain generated from the authoritative boundary loop; the mapper writes
that production authority rather than baking duplicate collision children into
the scene.

The return record directly positions `Exit_ReturnWorld`; there is intentionally no second `Return_CaveMouth` marker. The landing directly positions `Spawn_DescentLanding`, and the encounter origin directly positions the instanced `ForlornRitualantSite`.

The mapper also renders runtime-derived semantic geometry. Keys `1`–`8` in
collision mode filter boundary, encounter, hazard, interaction, camera,
transition, art, and traversal groups; `0` toggles all, `L` toggles labels,
and `G` toggles the 32 px grid. The HUD lists every semantic volume under the
cursor with its runtime details. Art bounds come from live textures and global
transforms; collision bounds come from live shapes; parallax records are
explicitly labelled presentation-only. No debug overlay is a second geometry
authority.

`F1` selects gameplay (boundary, encounter, hazard, interaction), `F2`
selects art alignment (boundary, art, traversal), `F3` selects presentation
(camera, transition, art), and `F4` hides semantic overlays. With three or
more groups visible, bulk labels are suppressed while `UNDER CURSOR` remains.

Press `P` to export `reports/level_maps/forlorn_ritualant_underground/full_map.png`
and `full_map.json`. Both use the same semantic records being rendered. The
mapper-backed arena is `1280x960` with `1152x800` combat bounds, native-scale
extended floor/perimeter art, and a correspondingly widened connected
playable loop. A dedicated `320x192` bridge at `(0,1376)` covers the landing
connector without moving `LandingShelfApron`.

## Dialogue and Hostility Safety

Dialogue ownership, encounter-resolution choreography, and terminal resolution
all suppress White Thread and fountain hazard mutation. White Thread resets its
tick interval while suppressed, so stored time cannot fire immediately when
dialogue closes. Same-frame firearm or melee feedback is also ignored while
dialogue owns Operator input.

First-time production dialogue is marked seen only after `sequence_finished`;
cancellation leaves it replayable. First contact exposes one shallow Bell /
Thread / Orra menu. Each topic owns its former follow-up material, closes to
gameplay when complete, and uses a short recap thereafter. Completed first
contact plus all three core topics unlocks the Stilling Pin. Taking it retires
basin inspection; `SET STILLING PIN` requires the upstream White Thread Knot,
runs apparition/procession stagecraft, and commits stabilization without a
timed fountain stand. Exhausted core dialogue resolves to a state-aware
synopsis, and departure epilogue speech requires completed first contact.

`AshBellEventState` requests hostility but does not directly declare it.
`ForlornRitualantSite` is the sole hostility-transition authority: it records
the reason, defers a request received during dialogue, then performs dialogue
shutdown and NPC/presentation choreography after control is released. The
mapper exposes the last cause, including `thread_snap`, `player_melee`,
`player_firearm`, or a pressure-threshold reason.

## Presentation Scope

The surface and underground levels now share one lift-platform assembly. The
lower terminus provides a short south-to-north landing approach; departure
requires boarding plus E, raises the platform into full black, plays the
resolution-appropriate epilogue, and hands the route off while black so the
existing surface ascent reads as the continuation of one journey. Additional
cavern dressing remains art polish, never a reason to restore special-room
insertion.

The surface lift captures the Operator into the shared presentation rig and
carries the rider through its authored `176 px` visible surface ascent. The
Underground wrapper independently owns the `256 px` lower arrival/departure
travel described above. Both suspend the live actor. A
rejected route request rolls the lift, black overlay, presentation, and actor
processing back to their pre-departure state.

The surface presentation no longer draws the flat `ThresholdSurface` polygon;
`DarkMouth` remains only as the deep aperture and disabled travel-occlusion
polygons remain disabled. Underground arrival retains its authored timing and
arrival panels, while ascent uses the existing narrow `256x1536` shaft-scroll
texture as its moving central shaft. The `768 px` arrival back/foreground
panels are not shown during ascent.

The Underground uses camera-profile change notification for the distant chapel
proxy and generic `AuthoredThresholdBlend2D` instances for the reversible
cosmic-underlay and temporal-haze transition beneath the existing chapel
overhang. The proxy is composited above the south cavern rim and initialized
from the active camera profile. Dialogue is screen-space with separate manual
and menu heights. Terminal resolution invalidates environmental as well as
direct Ritualant speech, pauses fountain pressure while actor input is
captured, and hard-gates delayed attacks. The hostile route is an ordered
WEST/NORTH/EAST ritual duel: each anchor requires a fresh Ritualant attack
exchange, and only the currently valid anchor is emphasized. Stabilization
interrupts combat, tightens the thread presentation, drops the Ritualant out
of hostility, reverses the ash pressure, and lets dialogue data own the final
three-beat cadence before dissolution. The shared lift accepts the visible
deck (`72 px` half-width), and `InteractableLevelExit2D` delegates prompt truth
to the same controller predicate used by departure acceptance.

`RouteTraversalManager.is_transition_input_locked()` exposes the read-only
phase/visual-transition gate consumed by pause UI. Pause cannot open during a
handoff, an already-open pause is cleared, and pause must be released once
after transition before another press can be accepted.

`AshBellLiftIngressPresentation` and the Underground wrapper still duplicate
transit orchestration. A future
`game/world/levels/presentation/lift_transit_presenter_2d.gd` should own actor
capture/suspension, rider presentation, travel reversal, cancellation, and
rollback while leaving art composition and travel profiles caller-owned. That
extraction is deliberately deferred until both transit sequences are stable.

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
godot --headless --path . --script res://tools/validation/forlorn_ritualant_completion_smoke.gd
godot --headless --path . --script res://tools/validation/route_registry_contract_smoke.gd
godot --headless --path . --script res://tools/validation/special_room_insertion_smoke.gd
```

The level smoke proves authored route/load/spawn/exit authority and retirement
of the procgen definition. The completion smoke additionally proves one-time
dialogue/recaps, the Pin-to-basin peaceful journey, unseen departure silence,
lower-lift containment and ascent art, reduced guard distance, and route-aware
pause suppression.
