# Sundered Keep Mapper Consolidation

- Status: `complete`
- Authority: `design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md`
- Goal: make one mapper own the actual production Sundered Keep level and
  remove competing geometry, placement, collision, and generator authority.
- Completed: consolidated approach-rail, underlay-rail, marker, palette,
  underlay-stamp, drag-paint, undo/redo, feature relocation, and siege
  placement tools into `sundered_keep_mapper.tscn`; changed its preview to the
  actual `SunderedKeepMap`; moved mapper placements and siege configuration
  into the production level JSON; removed the three prior Keep-specific mapper
  scenes, separate placement/siege documents, relayout generator, and runtime
  procedural fallback.
- Collision: 127 mapped rails own permanent collision. Permanent wall and prop
  colliders are suppressed. Stateful Main Gate and Great Hall blockers remain
  dynamic, but their rectangles are mapper-authored level records.
- Placement: traversal sprites, sidearm presentation/interaction, routekeeper
  anchors, marine spawn, gate prefab, interactables, spatial regions, and siege
  anchors are mapper-visible records. Runtime code now attaches behavior to
  these records rather than supplying fallback placement.
- Validation: `sundered_keep_mapper_smoke.gd`, large-layout smoke, Keep
  interaction/state smokes, and the route pipeline suite.
- Deferred: human visual editing inside the unified mapper; no second
  Sundered Keep mapper should be introduced.
