# Awakening / The First Return, Sections 01-10 (2026-09-06)

Replaces the one-image Home beginning with the ten-section authored dungeon locked
in `design/04_architecture/AWAKENING_FIRST_RETURN.md`. Delivered as three patches.

## Patch A — geometry spine

Migrated `home_custodian_begin` to `awakening_first_return` with `git mv`, made it
the project main scene, and created `game/world/awakening/awakening_layout.gd` as
the single spatial authority. Built sections 01-10 from that authority alone; the
`.tscn` holds the node skeleton and the Road/locker instances, no coordinates.

Made `RoadOfWitnessesPrototype` translation-safe: `apply_camera_bounds` export,
occlusion thresholds compared in local space, and a `south_gate_gap_width` that
opens its southern boundary wall so the Approach joins it as continuous walkable
space. Instanced at `(6, -6626)`.

Removed `FieldTerminal`, `SignalNeedle`, and the nested `ReturnCausewayApproach`
from the boot scene; `field_terminal_interactable.gd` stays in the repository.
Removed contract prewarming and the `game.tscn` handoff from the prologue.

Added `set_authored_map_bounds` to the camera: its deferred procgen rebuild was
clearing the authored world clamp half a second after the level set it.

## Patch B — functional pass

Zone volumes with deterministic resolution (section envelopes overlap where one
space opens into the next, so the furthest-along occupied section wins, with stale
regions pruned by containment so debug teleports behave). HUD location/phase per
section. Crèche console progression and the persistent RETURN TO POST objective.
The existing `SidearmLocker` as the P-9 recovery. `AwakeningTransitLift` for the
Dust Lung, reusing the Operator's existing `set_portal_transition_locked` rather
than adding a second input-lock. Undergate port readout. Three one-shot authored
camera reveals through the camera's existing presentation seam, with input never
taken away. Completion trigger at `(0, -6464)`.

Encounter slots placed and disabled; `World/Enemies` stays empty.

## Patch C — authoring hardening

Mapper renamed and reframed on the whole spine (`(0, -3200)`, zoom `0.18`) with a
zone/route/landmark overlay read from the layout authority. Dev-only debug tour
scene with zone selector, teleport-to-entry, overlay toggles, and progression
reset; no global hotkeys. Docs reconciled.

## Notable finding

The geometry validator rejected the first Locker Reliquary set-piece pass: the
central basin and the wall lockers left a 16px circulation band, far below the
128px critical-route minimum. Lockers were reworked as wall relief and the basin
kept as the single floor obstruction. This is exactly the class of defect a
scene-loads test cannot see.
