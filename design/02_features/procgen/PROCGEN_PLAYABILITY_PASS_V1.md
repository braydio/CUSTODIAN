# Procgen Playability Pass V1

**Status:** implemented-v1  
**Feature type:** procgen route authority, presentation, and validation  
**Parent specification:** `design/02_features/procgen/PROCGEN_INTENT_GRAPH_ASCENT_V1.md`

## Summary

The ascent intent graph remains upstream authority. `AscentFieldBuilder` emits
the primary route footprint and a deterministic centerline, then
`RoutePlayabilityField` derives clearance and dressing bands before terrain,
foliage, props, actors, or ambient anchors consume the map.

This pass turns route intent into visible and mechanical downstream policy. It
does not replace the intent graph, terrain builder, authored reservations, or
navigation authority.

## Generation Order

1. Intent graph
2. Ascent field
3. Region reservations
4. Playability field and constrained exterior cleanup
5. Terrain and elevation
6. Floor presentation and road stamping
7. Story/faction geometry
8. Props and foliage
9. Actors and encounter anchors
10. Final blocker-aware playability audit

## Runtime Ownership

- `AscentFieldBuilder` owns route footprint, centerline, critical terrace
  dimensions, and raw exterior floor.
- `RouteDistanceField` owns deterministic floor-constrained distance queries.
- `PlayablePocketClassifier` translates reserved intent kinds into arrival,
  exit, safe, combat, resource, vista, story, branch, and travel roles.
- `RoutePlayabilityField` owns clearance bands, constrained floor cleanup, and
  post-decoration audit data.
- `ProcGenTilemap` integrates those results with existing road, terrain,
  foliage, prop, level-data, and validation paths.
- Foliage and prop systems remain subordinate consumers. They do not alter
  route intent.

## Route Bands

| Route distance | Runtime meaning | Foliage ceiling |
| ---: | --- | ---: |
| `0–2` | hard traversal clearance | `0.00` |
| `3–5` | route shoulder | `0.03` |
| `6–9` | sparse dressing | `0.10` |
| `10+` | deep dressing | `0.42` |

The active planet foliage density remains an upper bound. The band policy can
reduce density but cannot silently exceed the selected biome profile.

Large trees additionally require:

- at least five floor steps from the primary centerline;
- at least four tiles from another placed large tree;
- no placement inside critical pads or encounter clear interiors.

The hard-clearance mask rejects foliage, tree trunks, ruin props, and other
registered solid dressing. Terrain blocked/ledge/drop cells inside the mask are
restored to walkable floor before final road presentation.

## Route Presentation

The center five tiles use the existing road material/decal system. The next
two tiles receive the existing degraded path treatment. Existing deterministic
road-piece breakup prevents a perfectly uniform stripe.

Authored-scene, story, faction, interior, stair, and ramp visuals remain
authoritative where they cross the route. These role transitions count as
legible route destinations and are not repainted with ordinary road floor.

## Critical Pads and Pockets

Minimum generated critical dimensions:

- spawn: `20×16`
- exit: `22×16`
- safe pocket: `18×14`
- ascent/faction combat pocket: at least `18×14`

Clearance radii:

- spawn: seven tiles
- exit: six tiles
- safe pocket: six tiles
- resource/story insertion: four tiles

Combat pockets reserve a central rectangle covering at least 70% of the
pocket. Candidate encounter anchors are emitted at the pocket edges rather
than ordinary travel-lane centers.

## Constrained Floor Cleanup

The cleanup pass is deterministic and preserves the primary route plus every
reserved region:

- non-protected floor cells with fewer than three of eight floor neighbors are
  removed;
- holes with at least six floor neighbors are filled;
- border cells are not filled;
- no unconstrained cellular smoothing is used.

## Final Audit

The post-decoration audit combines generated wall authority and registered
runtime prop blockers. It asserts:

- spawn reaches all required and combat-pocket centers;
- no blocker occupies the primary route footprint;
- the primary route retains at least seven navigable tiles at every sampled
  centerline cell;
- audit results are exported in level data as `route_playability_audit`.

The audit is rerun after deferred foliage completes. Failures emit
Developer Observatory diagnostics and never become generation inputs.
The paired portal's own authored collision is excluded from generic dressing
blocker checks; its surrounding pad still rejects unrelated blockers.

## Deferred Presentation Work

This V1 does not add camera bounds or a biome underlay. The exported masks and
pocket roles are the authority those later presentation passes must consume.
Encounter cadence and player-facing arena art remain later content work; this
pass only establishes safe, reachable pocket geometry and edge anchors.

## Validation

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/procgen_playability_smoke.gd
godot --headless --path . \
  --script res://tools/validation/procgen_route_clearance_smoke.gd
bash tools/validation/run_procgen_validation_suite.sh
```

## Next Agent Slice

Goal: use pocket roles for authored encounter cadence and add a presentation-
only biome underlay derived from generated floor bounds.

Constraints:

- keep the playability result read-only downstream authority;
- do not spawn ordinary encounters in hard-clearance travel cells;
- keep camera/underlay presentation separate from walkable authority;
- retain blocker-aware validation after all dressing.

Acceptance:

- minor and major encounter cadence consumes classified combat pockets;
- safe pockets separate major encounters;
- the camera never exposes flat gray void inside its valid generated bounds;
- no underlay node participates in collision or navigation.
