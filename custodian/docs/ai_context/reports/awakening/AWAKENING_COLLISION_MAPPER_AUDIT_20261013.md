# AWAKENING COLLISION / ART AUTHORING AUDIT — 2026-10-13

**Baseline:** `17fd54aa9bf78887ff162f51af19176095284d8f`. Static code/scene/QA audit only; no Godot rendered inspection or fresh pixel sampling was possible in this session.

## Decision

**Use the existing interactive Awakening mapper after fixing its authoring bridge.** Do not ask Codex to hand-guess dozens of pixel vertices from a prose brief. The general mapper already supports click-to-add chains, snapping, editing, zone overlays and clipboard export, but cannot truthfully display or safely apply Awakening's real collision today. Treat it as preview-only until the new bridge receives independent review.

## Current authority and observed gaps

- `awakening_layout.gd` owns 10 zones, floors (rect/polygon), voids, blockers, traversal connector carve-outs, passage, Gate/Road and markers. `awakening_first_return.gd` builds collision dynamically as a 32px occupancy sweep, per-zone void polygons and rectangular set-piece blockers; Zone10 reuses Road colliders and individual props can own collision.
- `awakening_first_return_mapper.tscn` loads real production `awakening_first_return.tscn` and zone overlay, but the generic mapper edits `BOUNDARY_SEGMENTS` in the target controller, which doesn't expose those constants. `get_boundary_segments()` returns WORLD_BOUNDS only; generated real colliders are not the mapper's generic `PathBoundaryCollision` nodes. The zone overlay's collision drawing starts disabled and reflects planned Layout geometry, not the actually instantiated physics shapes. Generic snapshot misses draft vertices.
- Adapter advertises `COLLISION, MARKER, REGION`, but mode toggling checks `MARKERS`, and REGION has no implemented draft operation. This requires an honest UI fix or explicit mode disabling.
- Zones 04–05 use a shared registered composition; their individual underlays are hidden. The mapper must compare collision to *rendered production art*, not stale hidden source art.
- Existing tests validate route reachability and locked coordinates, but do not prove pixels under visible art are collision-aligned for every zone. This is an evidence gap, not proof every collider is wrong.

## Exact verified coordinate anchors (world pixels, not inferred opaque art extents)

| Feature | Exact current layout/collision | Implication |
| --- | --- | --- |
| Gate west pylon | Center `(-256,-4768)`, size `240×496`; AABB x `[-376,-136]`, y `[-5016,-4520]` | Existing 2026-09-20 alpha QA measured west canvas opaque bounds `(24,5)-(250,504)`; 240×496 collider already reviewed |
| Gate east pylon | Center `(256,-4768)`, size `240×496`; AABB x `[136,376]`, y `[-5016,-4520]` | East canvas opaque bounds `(17,15)-(239,495)`; central 272px walkable gap |
| Crèche console | Layout blocker `(112,144)`, size `56×40`; AABB x `[84,140]`, y `[124,164]` | Compare independently to separately scene-authored console visual at `(105,118)`; no assumption the whole visible cabinet should collide |
| P-9 locker footprint | Layout blocker `(920,-1888)`, size `112×32`; AABB x `[864,976]`, y `[-1904,-1872]` | Visual/interaction anchor `(832,-1952)` is intentionally different; do not overwrite it with a collider center |
| Mandatory lower→upper passage | `Rect2(-64,-3840,128,96)` | Cannot cover with user-authored solid/void |
| 04→05 traversal dogleg | `Rect2(640,-2432,128,160)`, `Rect2(0,-2560,704,128)`, `Rect2(-64,-2656,128,96)` | Preserve transition width and connectivity; art coverage mismatch is not an automatic collider justification |
| Road south entry | `(0,-6144)`; Road offset `(6,-6626)` | Separate Road prototype owns its own collision |
| Wake | `(0,160)`; Operator radius `11` | Must retain spawn clearance |

## Known presentation/collision discrepancy

The 2026-09-20 Gate QA confirms the sealed central body visually covers part of the **mandatory traversable opening**. Making that whole opaque region solid would seal the route. Fix Gate aperture art/animation/state separately or flag mismatch; do not 'repair' it with wider collision.

The 2026-09-20 visual walkthrough also lists uncovered connector art rectangles: `04_05_A Rect2(640,-2432,128,96)`, `04_05_B Rect2(0,-2560,704,128)`, `04_05_C Rect2(-64,-2592,128,32)`. These are **art coverage holes**, not evidence the corridor should be blocked. Later accepted 04→05 registered art cutover supersedes historical plate placement, so recapture exact current ROI before any edit.

Dust Lung V2 is a **separate pre-production spatial lock** with a western lift route. Do not author the old Zone05 colliders as final for that future composition; treat V2 cutover as separately authorized.

## Production criteria

A trustworthy mapper shows actual node collision, named ownership, real artwork and mandatory route overlays; exports each exact vertex in world pixels with source transforms; provides safe undo and reliable reopen; protects existing scene/compiled source; and fails closed on stale collision authority or route obstruction. User-authored geometry must be promoted into one canonical Layout source and pass physical route traversal before gameplay changes land.

## Documentation drift

`design/04_architecture/AWAKENING_FIRST_RETURN.md` correctly names Layout the canonical spatial authority, but its claim that 'mapper' queries the Layout under-describes the broken editor write seam and absence of true instantiated collision overlay. Correct the mapper capability statement after the bridge is implemented; do not imply interactive edits work before then.
