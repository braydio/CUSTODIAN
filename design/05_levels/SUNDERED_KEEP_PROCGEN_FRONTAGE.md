# Sundered Keep Procgen Frontage

- **Status:** active production authority; layering review required
- **Owner:** generated Sundered Keep frontage and distant reveal
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-15

## Production Boundary

The generated frontage, its collision-safe terrain authority, and its distant
reveal presentation are production content. The presentation is subordinate to
generated gameplay geometry and may never cover the playable frontage.

Production traversal is:

```text
generated campaign terrain
-> generated playable Sundered Keep frontage and distant reveal
-> terminal ingress at the generated gate anchor
-> ordinary fade
-> authored Sundered Keep Vista Approach
-> ordinary fade
-> Sundered Keep Front Gate
```

## Production Procgen Ownership

Procgen owns:

- playable generated frontage floor, cliff/blocker, navigation, prop, and enemy
  placement authority;
- the generated shore/cliff boundary;
- the distant ocean/storm/fortress reveal presentation;
- registered terminal ingress placement at `sundered_keep_frontage.gate_anchor`.

Generated floor cells are the single traversal source. `ProcGenTilemap` derives
a merged, non-destructible cardinal-edge collision frontier from the final
authoritative floor set after playability remediation. Navigation consumes that
same floor set. Stochastic cliff/wall tiles remain visual/destructible dressing
and are never the security perimeter between walkable terrain and void/ocean.

The frontage grammar emits `vista_commit_cells`,
`mandatory_separator_cells`, and `terminal_apron_cells`. All generated paths
may vary below the commit line, but removing the intended commit passage must
disconnect the world-side frontage entry from `gate_anchor`. The terminal apron
must contain the gate anchor.

It also emits one bounded north-facing `sundered_keep_frontage_ocean` surface
claim using the `sundered_keep_cosmic_ocean` profile. The claim derives its
lateral and inward extent from generated camera/gate semantics and owns no
floor, collision, navigation, or wall state. After final floor remediation,
central procgen classification resolves the claim into `ocean_cells`; all other
non-floor cells remain chasm. Near-field 32×32 water and topology-aware foam
are visual-only and bridge generated coastline into the large vista ocean/storm
presentation. Straight edges, convex and concave corners, endcaps, and T
junctions resolve from authoritative floor/ocean neighborhoods without random
skipping, rotation, scaling, or terrain mutation.

The shared depth backdrop consumes the resulting explicit `chasm_cells` through
connected chasm-region presentation. The camera-following generated-floor
compatibility stack is reserved for generation modes that genuinely lack
explicit chasm semantics; ocean and floor never enter the chasm backdrop.

The ingress uses `procgen_landmark_terminal` with the
`sundered_keep_frontage` landmark data key.
It starts the `sundered_keep` route with the `production` profile. Production
continues to enter `sundered_keep_vista_approach`; it must not bypass that
authored level by selecting the direct-keep debug edge.

The procgen vista owns presentation only. `VistaPresentationRoot` has absolute
negative depth, contains no collision or navigation descendants, and clips its
ocean/storm/fortress imagery to the exterior side of the generated gate
boundary. It must not cover generated playable-floor bounds. Gameplay remains
owned by generated floor/collision/navigation and ordinary actor systems.

The world-side camera uses one route-arc-distance contract shared by generation,
camera projection, presentation, and validation. Influence starts 52 cells
before the gate (`S=0`), Keep discovery begins visually at `S=8`, and one fixed
ruins/Keep composition reaches its apex 36 cells before the gate (`S=16`). The
apex remains spatially stable through `S=24`; moonlight fires once at `S=20`
without moving the camera. Framing is fully released at `S=36`, leaving 16
route-arc cells of ordinary play before the gate at `S=52`. There is no timed
hold or second fortress camera subject. Traversal remains unlocked. The
existing 18-cell focus-displacement cap remains the coarse request guard.
During camera ownership, `CameraController` also keeps the Operator inside the
final rendered normalized safe frame `x=0.04..0.96`, `y=0.06..0.92`. This
subject constraint runs after presentation smoothing and bounds clamping,
overrides presentation-bound purity when necessary, clears on release, and
does not bias the Operator toward center.

The active layering pass keeps the base storm horizon and moonlight punctuation.
Inside generated gameplay bounds, StormHorizon is nearest-sampled through an
authoritative ocean-cell mask and is transparent beneath generated land. The
drowned arch/causeway and Keep coexist in one fixed composition. The ruins
anchor targets authoritative ocean ten cells composition-left and nine cells
outward from the vista apex, with at least six cells of floor separation. The
final OuterWall and CentralCitadel are the sole Keep representation. The reveal
veil stays out of runtime use, and the persistent
horizon-seam fog becomes the architectural bridge. The outer wall and central
citadel use the established distant blue-gray palette at uniform `0.22` and
`0.205` scale. The drowned arch and causeway use `0.33` and `0.285`. Ruins,
Keep, and seam fog continue sinking atmospherically from `S36` through `S52`
while camera authority remains fully released. The
approach gate-shadow veil is not part of this procgen vista;
the ordinary route fade owns the generated-frontage-to-authored-approach handoff.
The existing Descending Ward remains an optional review follow-up rather than an
automatically stacked layer.
The fortress presentation root is positioned once from
`fortress_front_anchor`; the outer wall and citadel retain their reviewed
scene-local offsets and are not pulled apart by gameplay-scale wall/tower
anchors. Generated frontage floor keeps its irregular authoritative footprint
but uses semantic presentation zones rather than broad Euclidean gate radii.
The first two Manhattan-distance floor bands from authoritative ocean use a
deterministically hashed wet-rock skin: distance one is `70/30` rock/cracked;
distance two is `45/35/20` rock/cracked/wet flagstone. Beyond that band,
terminal-apron threshold stone and the existing frontage selection remain
authoritative. `SunderedKeepShorelineCompositor` is the single presentation
planner for both production procgen and the editor visual lab. It extracts
directed floor/ocean boundary segments, orders them into runs with cumulative
world-space arc distance, and derives the coastal floor band, foam topology,
glue ribbon, and cliff placements from that shared frontier. Topology-aware
ocean foam sources are transparent overlays rather than opaque water tiles.
The compositor uses a metadata-backed presentation catalog containing the four
64x96 cardinal edges, three face slices, four inner corners, and four outer
corners. Boundary-vertex occupancy determines convex/concave kind and the
NE/NW/SE/SW asset orientation. Corners are first-class plan entries and exclude
straight samples for `0.75 * cliff_spacing_px` on both adjoining legs. N/S
horizontal runs deterministically mix canonical edges and the unrotated face
slices at baseline 45/30/15/10 weights; E/W runs retain their directional edge
assets because no authored directional slice exists. Authored canvas and pivot
metadata control placement, and no pixel art is rotated. A presentation-only,
non-antialiased 40px dark ribbon sits beneath
the detailed cliff art so transparent gaps cannot expose ocean or foam.
Explicit per-direction offsets keep the lip on land and face over ocean. Cliff
sprites use the cooled baseline
`Color(0.72, 0.77, 0.84, 0.96)` and render above foam; foam is held to 22% layer
alpha beneath the cliff band. These sprites add no collision, navigation, or
terrain authority.

The passive storm, offshore ruins, fortress, fog, and foreground-lip subtree
lives in `sundered_keep_vista_art_bundle.tscn`, instanced by production and the
visual lab. The shared ocean-mask builder derives its mask only from
authoritative floor/ocean cells. Lab production context is strictly a view
option: toggling it cannot alter shoreline plan fingerprints or placement.

The historical 2048×512 World Vista cliff lip is reused only as a low-alpha
cinematic foreground plane. It grows from zero at `S0`, peaks at `0.42` at
`S20`, and clears by `S36`; it owns no terrain, collision, or camera authority.

Renderer approval remains required for this ocean-mask, shoreline-topology,
boundary-offset, and drowned-ruins pass. Headless validation does not close the
visual layering review by itself.

Routine shoreline tuning uses
`res://tools/visual_labs/sundered_keep_shoreline_lab.tscn`. Opening the `@tool`
scene renders the shared compositor directly in Godot's 2D editor; Inspector
controls cover synthetic shapes, the controlled cliff-vocabulary preset,
captured production fixtures, seed, spacing, foam, shore width, modulation,
visibility, per-kind false color, topology overlays, masked ocean/full vista
context, reset, fixture save, and PNG capture. F6 runs only the lab scene with pan/zoom. Full-game boot
and shell commands are not part of the normal art loop; Moment Forge remains
the final production regression/evidence gate.

The cinematic dressing-clearance envelope follows the centerline through
gameplay return, with wider discs at the single apex plateau. Foliage, ruin props,
interactables using normal spawn eligibility, and corridor encounter selection
consume the same protected frontage query; encounter content remains available
in unprotected side pockets. While the vista owns the camera, ordinary procgen
foliage, ruin-prop, and world-progress presentation layers plus the generated
ingress marker are hidden without disabling collision, interaction, navigation,
or spawned runtime state; all are restored when gameplay framing returns.
The storm underlay fit covers the fixed vista focus at apex zoom plus the
viewport safety margin; exposing a finite
plate edge during the camera handoff is a visual failure.

## Authored approach boundary

After the terminal ingress, the authored Vista Approach owns Shore Parish,
the near-Keep route, outer-wall checkpoint, east traverse, local collision and
dressing, and the Front Gate handoff. It does not replace the generated world
frontage or distant reveal.

## Lifecycle

`WorldIngressSite` remains the transition authority. It captures and isolates
all `world_origin_branch` nodes, including `ProcGenRuntime`, starts the
registered route, and restores world visibility, processing, Operator state,
camera follow, and presentation bounds on return or entry failure.

## Validation

Run from the repository root:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_procgen_vista_layering_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/camera_presentation_subject_constraint_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_shoreline_compositor_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/procgen_walkable_boundary_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/procgen_nonwalkable_surface_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/procgen_ocean_tileset_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_frontage_bypass_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd
```

Acceptance requires generated playable frontage, a terminal ingress on its gate
anchor, collision/navigation-free vista presentation below gameplay, an
exterior clip disjoint from playable floor bounds, authored-approach activation,
and exact world/camera restoration on exit or failure.

## Next Agent Slice

Review exact `S=0/4/8/12/16/20/24/28/32/36/52` frames across production
seeds and viewport sizes.
Tune presentation-only local offsets or floor-source weighting only if the
fortress, shoreline, or land mass still reads poorly; do not alter camera
choreography, generated floor geometry, route topology, or traversal authority.
