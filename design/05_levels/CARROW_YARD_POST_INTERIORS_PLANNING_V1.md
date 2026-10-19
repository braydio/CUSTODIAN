# CARROW YARD — POST-INTERIORS PLANNING REFRESH V1

**Status:** Historical post-interiors planning baseline; **size-selection gate resolved by user** on 2026-10-17. See [Carrow Yard Interior Scale and Layout V2](CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md) for current size policy, remaining spatial-layout approval, and hybrid presentation decision.
**Baseline:** `braydio/CUSTODIAN main@e4e50dfc370ae0476e01237159672353cf8bbe31`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f
**World canon:** `design/03_world/locations/CARROW_YARD.md`
**Historical proposed layouts:** `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md`
**Review evidence:** `REVIEW_CARROW_OPERATIONS_HOUSE_INTERIOR_V1_CLAUDE_SUMMARY.md`; archived implementation and review packets

## Verified runtime truth, not human scale approval

| Area | Live exact dimensions | Contract/evidence |
| --- | --- | --- |
| East Machine House | 14×10 tiles, 448×320 px, 140 floor cells | Original working interior; 13 art sprites and 3 resource stores |
| West Draft House | 12×10 tiles, 384×320 px, 120 floor cells | Implemented, accepted paired review; generator site `west_draft_house` |
| Operations House | 20×14 tiles, 640×448 px, 280 floor cells | Implementation `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1`; accepted review `8edc7252b` |
| South Gate | 5-tile nominal passage (160 px at 32 px/cell) | Generator-owned gate and approach-path reservation |
| Gatehouse annex | **No separate named generator site or authored interior** | Proposed only; design predecessor 10×8 is NOT approved |
| Alarm Gantry | 4×6-tile exterior asset footprint, `alarm_gantry` generator site | Industrial signal mast, no adopted alarm gameplay |
| Service Court | Generated court and approach road | Keep north-south loading/service route traversable |

The archived independent Operations review records 41/41 changed-file checks passing, 107 actual cell-collider shapes, open three-cell entrance, a native-scale capture and unchanged same-Operator/interior-return behavior. That proves the packet's deterministic acceptance; **it does not decide whether the interior is large enough or pleasing to navigate.** Reviewer evidence under `.git/custodian-review-runs/` may be local-only and is not re-certified by this planning note.

The `gothic_compound_map.gd` named-interior authority now owns `INTERIOR_ROOM_DEFINITIONS`, `active_interior_id`, region queries, camera bounds, door/return and rendered floor/wall/storage/lighting. Do not build a second room router. Its 14×10 East layout has a legacy short-row exception; the debug calibration should reject malformed rows in its *new* variants rather than changing production.

## Immediate decision: measure room scale with fixed debug variants

The user expressly rejected allowing Codex to decide whether a layout feels 'playable' or 'modern'. Instead, implement **three exact debug scene variants** with no subjective scorer, no recommendation, and no changes to production interiors:

| ID | Cells | Pixel footprint | Tile cells |
| --- | --- | --- | --- |
| `24x18` | 24×18 | 768×576 | 432 |
| `30x22` | 30×22 | 960×704 | 660 |
| `36x26` | 36×26 | 1152×832 | 936 |

All share a 32px unit, actual Operator/camera controls, the same 13 East art resources and three resource interactions, and a **fixed mechanical layout grammar** specified in `CARROW_MACHINE_HOUSE_SCALE_CALIBRATION_V1.md`. Their layouts are intentionally comparable rather than claimed to represent ideal working architecture.

Expected separately launchable Godot scenes, relative to `custodian/`:
```text
res://scenes/debug/carrow_machine_house_scale_24x18.tscn
res://scenes/debug/carrow_machine_house_scale_30x22.tscn
res://scenes/debug/carrow_machine_house_scale_36x26.tscn
```

**Human gate:** User selects a size, asks for new fixed alternatives, or declines all candidates after actual hands-on testing. Neither Codex nor the independent technical reviewer scores game feel or promotes a winning dimension. After that choice, a separately authorized production-resize packet can migrate East and, if desired, West and Operations with canonical room metadata, geometry, and camera/asset tests.

## Next structures: design disposition

### South Gatehouse (future G0 and G1)

**Problem:** The generator currently defines gate-cell/route topology and a gate cluster, **not** an independently placed `gatehouse` structure site. Adding a 10×8 or 18×14 interior now would turn a deliberately unapproved size into production canon.

**G0: deterministic exterior site proof, no new interior.** Once the user chooses whether to pursue a side annex, create a named `south_gatehouse_annex` candidate anchored to the generated gate with a fixed footprint/side rule specified before implementation. Test across the default seed and alternate deterministic seed(s): no occupancy in the five-tile south opening, `required_walkable` gate and entry road unchanged, no footprint overlaps, return/door point does not occupy a solid, and no double passage authority. Codex reports exact tile cells and 32px-derived pixel rectangles, not 'good' placement. Keep any size/side choice a separate user selection before task claim.

**G1: interior only after G0 accepted and size approved.** Reuse named-room metadata/camera/environment and local doorway ownership. Functional program: observation slit, gate actuator, entry/shift records. Passive inspection only, no enemy alarms, sentries, new route owner, or unlock logic. New asset pipeline family may be authorized after concrete source/variant gaps are measured.

### Alarm Gantry (future A0, presentation-only)

Site `alarm_gantry` and exterior 4×6 footprint exist. Preserve its meaning as municipal industrial signaling, not religious bell and not a faction installation. A bounded **A0** may instrument current site placement, actual collider bounds, path safety and existing presentation layers, then present a static/disabled condition without changing awareness or alarms. Any powered/armed/firing signal states need an approved `STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md` consumer contract. Do not create a one-off global alert broadcaster or alter actor perception in this slice.

### Service Court (later)

No new structure density until G0 collision/path evidence. The road from South Gate to Operations, side routes to West/East, resource nodes, spawn clearance and service loading lane are reserved. Decorative yard props must not claim route semantics from painted alpha. Only register new art with Asset Pipeline V2, with explicit target pixels, one-frame alpha and unique family states after approved art review.

## Preserved authorities and documentation drift

- **Canonical lore**: site remains civilian district utility yard; present-day faction ownership intentionally unresolved.
- **Technical namespace**: `gothic_compound` remains until its own migration.
- **World traversal**: `CARROW_YARD_ROUTE_AUTHORITY_MIGRATION.md` is a separate dependency-gated workstream using `carrow-yard-route`; do not implement world ingress/LevelRegistry/LevelExit in scale debug scenes or G0/A0.
- **Historical expansion V1** previously asserted West and Operations unimplemented. Its documented grids remain the layouts *that were implemented*, not the new scale target.
- **Canonical lore** previously claimed East was the only live interior; corrected in the same doc update.
- **Dirty root checkout**: the user's unrelated `PROCGEN_AMBIENT_REAL_WORLD_SPAWN_RECOVERY_V1_CLAUDE_SUMMARY.md` and `custodian/docs/ai_context/task_packets/PROCGEN_AMBIENT_REAL_WORLD_SPAWN_RECOVERY_V1.md` are not to be touched, stashed, reset, overwritten or included in Carrow work. GitHub API main-doc commits do not touch local checkout state.

## Acceptance and follow-up

This planning note authorizes only authoring of an objective, fixed-size **debug calibration** pair. No production room resizing, Gatehouse annex collider, Alarm Gantry network behavior, art generation or source asset ingest is authorized. The next user review is of actual three-scene tests, not an agent's recommendation. After selecting a scale, refresh G0 footprint parameters and determine whether Gatehouse or inert Gantry presentation should be the next discrete implementation slice.
