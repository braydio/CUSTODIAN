# Sundered Keep — Shore Parish / Outer Wall Approach

Status: active production authority; renderer review required
Last updated: 2026-08-03

## Purpose

The Sundered Keep Vista Approach is the authored Shore Parish destination after
the generated playable frontage and before the existing Front Gate.

Production traversal is:

```text
procgen campaign world
→ generated playable frontage and distant Keep reveal
→ terminal ingress on the generated gate anchor
→ short normal fade
→ authored Sundered Keep Vista Approach / Shore Parish
→ short normal fade
→ Sundered Keep Front Gate
```

The authored scene is one continuous level. Its arrival, northbound parish,
close checkpoint detail, long east traverse, and exit are subregions rather
than separately loaded route stages.

## Ownership boundary

Procgen owns the playable generated frontage, its floor/collision/navigation,
shore boundary, props/enemies, terminal ingress, and the clipped distant Keep
reveal. Its presentation root remains below gameplay and owns no physics.

The authored approach begins after that terminal and owns:

- ocean and storm presentation;
- distant and close fortress presentation;
- route-master ground, including the northbound Parish and east traverse;
- the authored camera reveal;
- authored boundary collision and subregion metadata;
- approach enemies and set dressing;
- the route exit to Front Gate.

The Front Gate owns its southern arrival apron, protected spawn area, gatehouse
siege, and all Keep-interior progression.

## Camera contract

The persistent shared gameplay camera is the only production camera.

The authored approach owns the destination reveal while it is active. The
persistent shared camera remains the only gameplay camera and must restore
Operator follow and cleared presentation bounds on return. Historical
`SecondVista*` markers may remain semantic layout anchors, but they do not
grant procgen any reveal or framing authority.

The approach must not contain a child `Camera2D`, leave presentation framing
active, or switch the gameplay camera to a different follow target.

## Transition contract

Both production handoffs use the ordinary route `fade` style:

- `@world_origin -> vista_approach` at the generated-ground ingress;
- `vista_approach -> front_gate` at the east end of the authored approach.

There is no playable blackout corridor, operator-following shadow road,
full-screen fog handoff, or `occluded_handoff` in the production route.
Reverse traversal uses the same route-owned fade transaction and restores the
correct node, runtime map, spawn, and camera authority.

## Authored layout

```text
EntrySpawn
  ↑ northbound Shore Parish route
  ↑ close outer-wall/checkpoint detail
  → long east traverse
  → ReturnCauseway / route exit
```

The east traverse must be materially longer than the checkpoint reveal area.
The route remains readable under normal gameplay framing and is never hidden
by a full-screen veil.

## Runtime art

The production overlay records are mapper-authored in
`sundered_keep_approach_outskirts.json` and consumed by
`sundered_keep_approach.gd`:

```text
content/sprites/world/return_causeway/path/overlays/
  sundered_keep_shore_parish_northbound_ground_01.png
  sundered_keep_outer_wall_east_traverse_ground_01.png

content/backgrounds/sundered_keep/approach/near_detail/
  sundered_keep_outer_wall_checkpoint_detail_01.png

game/world/approaches/sundered_keep/
  procedural_fog_ribbon_2d.gd
  procedural_fog_ribbon_band.gdshader
```

The ground overlays are playable presentation underlays only; collision and
route authority remain in mapper data. The checkpoint fog is a shader-driven
local ribbon with two drifting noise fields and feathered vertical edges,
never a transition veil, and is clamped to a maximum authored tint alpha of
`0.30`. The retired `9216x384` six-frame sheet is not production content.

The authored scene owns its own Shore Parish ocean/storm and near-fortress
layers. The separate procgen distant-reveal stack may live under
`WorldLandmarks`, but it must remain clipped outside playable frontage, below
generated terrain, and free of collision/navigation. Authored images likewise
own no physics; mapper-authored perimeter rails constrain the authored route.

## Mapper authority

The authoritative approach mapper is:

```text
custodian/scenes/debug/sundered_keep_approach_mapper.tscn
custodian/scenes/debug/sundered_keep_approach_mapper.gd
```

It previews the production approach and authors:

```text
custodian/content/levels/sundered_keep/
  sundered_keep_approach_outskirts.json
  sundered_keep_approach_collision.json
  sundered_keep_approach_occlusion.json
```

The mapper supports route/floor records, collision rails, semantic markers,
subregions, occlusion regions, and all authored visual overlay records. Runtime
code may consume these records but must not silently place alternate route
geometry outside mapper authority.

## Visual coverage

Every supported gameplay and reveal framing must resolve to deliberate terrain,
fortress architecture, water/void treatment, fog, or foreground occlusion.
Engine clear color, gray overscan, exposed texture rectangles, and seams are
review failures.

## Validation

Required structural coverage includes:

```text
custodian/tools/validation/sundered_keep_approach_smoke.gd
custodian/tools/validation/sundered_keep_approach_outskirts_mapper_smoke.gd
custodian/tools/validation/sundered_keep_parish_route_correction_smoke.gd
custodian/tools/validation/sundered_keep_route_graph_smoke.gd
custodian/tools/validation/route_profile_selection_smoke.gd
```

Renderer review is produced by:

```text
custodian/tools/validation/sundered_keep_route_correction_review.gd
```

at `2560×1440` under:

```text
reports/sundered_keep_route_correction/
```

Required Parish frames are arrival northbound, close detail reveal, and long
east traverse. Human approval is required before this authority can be marked
complete. A successful file export alone is not visual approval.

## Acceptance criteria

- Procgen shows the generated playable Sundered Keep frontage and clipped
  distant reveal before entry without covering its walkable floor.
- Procgen is hidden and processing-disabled while the authored approach is
  active, then restored exactly on return or entry failure.
- The authored approach owns Shore Parish and its local reveal, then restores
  Operator camera follow and presentation bounds on exit.
- Parish arrival is readable and northbound.
- The close checkpoint detail does not become another world-scale cinematic.
- The long east traverse is playable and collision-complete.
- No full-screen fog or black navigable corridor exists.
- The approach exit and reverse entry are route-owned normal fades.
- All approach placement records are editable in the production mapper.
- Required renderer frames contain no exposed clear color, gray overscan,
  rectangular composition seams, or unreadable route surface.
