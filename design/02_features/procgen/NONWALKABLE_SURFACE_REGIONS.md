# Procgen Non-Walkable Surface Regions

- **Status:** review
- **Owner:** procgen semantic classification and non-walkable surface presentation
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-09

## Purpose

Every in-map cell has one deterministic surface identity after final generated
floor remediation. Existing authoritative floor is `GROUND`. Every remaining
cell is exactly one of `CHASM` or `OCEAN`. Wall cells remain blocker/occupancy
geometry and are not a surface kind.

```text
final authoritative floor
        ↓
non-walkable surface classification
        ↓
presentation-only surface TileMaps
        ↓
existing RuntimeWalkableBoundary collision
        ↓
final playability audit
```

Required exclusivity:

```text
floor ∩ chasm = ∅
floor ∩ ocean = ∅
chasm ∩ ocean = ∅
```

For each in-map cell, floor wins; otherwise the cell is exactly one of chasm or
ocean. Walls may occupy a chasm or ocean cell and never stop claim flooding.

## Surface Claim Contract

Non-floor cells default to `chasm`. Explicit deterministic claims may replace
chasm with another supported non-walkable kind. V1 supports only bounded ocean
claims with stable `id`, `kind`, `profile`, `seed_edge`, and `bounds` fields.
Claims apply in stable array order, clamp to the map, flood cardinally from the
declared edge, and stop only at authoritative floor or claim bounds. Claims may
not contain traversal, navigation, collision, body, or floor authority.

The Sundered Keep frontage emits one north-seeded bounded claim:

- `id`: `sundered_keep_frontage_ocean`
- `kind`: `ocean`
- `profile`: `sundered_keep_cosmic_ocean`
- `seed_edge`: `north`
- bounds derived from generated near-Keep camera/gate semantics

The frontage builder owns only this geographic claim. `ProcGenTilemap`
classifies it after final floor mutations and stores the resolved local ocean
cells back into frontage level data.

## Ownership

### Collision

`RuntimeWalkableBoundary` remains the only physical perimeter between generated
floor and non-floor space. Ocean/chasm TileMaps own no collision, health,
destruction, blocker, or traversal state.

### Navigation And Placement

Existing final floor remains ground-navigation, ordinary actor, foliage, prop,
pickup, and resource-placement authority. Chasm/ocean sets provide explicit
semantics and defense-in-depth diagnostics; they do not replace floor checks.

### Visuals

Two absolute-depth TileMap layers present non-walkable surfaces. Sundered Keep
ocean uses a static 32×32 dark-water fill. Its
`SunderedKeepShorelineCompositor` consumes the authoritative floor/ocean
frontier once, then plans topology-aware foam, ordered shoreline runs, the
presentation-only glue ribbon, cardinal cliff art, and coastal floor skin from
that shared boundary. All registered TileSet sources and compositor nodes are
visual-only.

Near-field generated ocean connects the walkable coastline to the existing
large Sundered Keep vista ocean/storm plate. The vista may use resolved ocean
bounds for geographic clip coverage but remains collision/navigation-free and
strictly disjoint from playable floor.

Explicit complete chasm semantics feed the seam-safe, camera-following
`ProcgenDepthBackdrop.configure_from_chasm_cells()` presentation and the
presentation-only `VoidCliffFace`. The face paints only authoritative chasm
cells in a deterministic three-to-eight-cell band from floor frontiers; ocean
and floor stop propagation. `RuntimeWalkableBoundary` remains the sole physical
authority, and neither visual layer participates in collision or navigation.

## Candidate And Streaming Contract

Surface sets are structural candidate state. They are classified from the
accepted candidate's final floor and survive candidate promotion byte-for-byte;
promotion does not reroll or rebuild geography. Ocean TileMap presentation may
be rebuilt from preserved semantic cells. Surface semantics remain complete
regardless of streaming visibility; the visual surface layers remain global in
V1, matching the global depth backdrop and collision frontier.

## Validation Matrix

- Classifier smoke: exclusivity, completeness, bounds, edge seed, deterministic
  fingerprint, wall independence, and claim-cell identity.
- Walkable-boundary smoke: real `CharacterBody2D` cannot leave floor.
- Candidate-promotion smoke: floor, wall, ocean, and chasm fingerprints survive.
- Frontage seeds: one valid deterministic claim, resolved ocean/chasm, protected
  floor disjointness, spawn/foliage safety, and existing no-bypass topology.
- Vista layering: ocean bounds drive exterior geography without overlapping
  playable floor or adding collision/navigation.
- Tile asset smoke: five 32×32 one-tile sources, no physics/navigation layers.
- Moment Forge full capture: coastline grounding, vista continuation, camera,
  moonlight, and terminal approach require human review.

## Non-Goals

Swimming, drowning, currents, wave physics, aquatic navigation, boats,
procedural ocean on every planet, additional surface profiles, animated shore
tiles, new art, minimap redesign, collision replacement, camera/route rewrite,
and connected finite chasm-region forest stacks are excluded.

## Next Agent Slice

Pass 2 may refine fascia edges, corners, drops, bottom breakup, roots,
variation, and contact shadows without changing collision or navigation
ownership.
