# Sundered Keep — Shore Parish / Outer Wall Approach

Status: active production authority; renderer review required
Last updated: 2026-07-31

## Purpose

The Shore Parish / Outer Wall Approach is the authored middle leg between the
generated campaign frontage and the existing Sundered Keep Front Gate.

Production traversal is:

```text
procgen campaign world
→ generated Sundered Keep frontage and distant reveal
→ short normal fade
→ authored Shore Parish / Outer Wall Approach
→ short normal fade
→ Sundered Keep Front Gate
```

The authored scene is one continuous level. Its arrival, northbound parish,
close checkpoint detail, long east traverse, and exit are subregions rather
than separately loaded route stages.

## Ownership boundary

Procgen owns the playable world through the generated frontage exit. It owns
terrain, navigation, collision, spawn rejection, dressing rejection, the
distant landmark, and the single world-side camera reveal.

The authored approach owns:

- the northbound Shore Parish floor;
- the close outer-wall checkpoint composition;
- the long eastbound traverse;
- local collision rails and subregion metadata;
- a restrained local fog ribbon;
- the route exit to Front Gate.

The Front Gate owns its southern arrival apron, protected spawn area, gatehouse
siege, and all Keep-interior progression.

## Camera contract

The persistent shared gameplay camera is the only production camera.

The procgen leg may temporarily apply one reversible distant-reveal influence.
The camera must be fully released before the generated frontage exit. The
authored approach does not run a second presentation camera or a second
fortress reveal. Historical `SecondVista*` markers may remain as semantic
layout anchors, but their controller weights are always zero.

The approach must not contain a child `Camera2D`, leave presentation framing
active, or switch the gameplay camera to a different follow target.

## Transition contract

Both production handoffs use the ordinary route `fade` style:

- `@world_origin -> vista_approach` at the generated frontage terminal;
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

content/backgrounds/sundered_keep/approach/fog/
  outer_wall_checkpoint_fog_ribbon_01.png
```

The ground overlays are playable presentation underlays only; collision and
route authority remain in mapper data. The fog ribbon is a six-frame local
effect, never a transition veil, and is clamped to a maximum alpha of `0.30`.

The old Grand Vista component stack is retained as reference material but is
hidden in production. It has no floor, collision, transition, or camera
authority.

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

- Procgen remains active through one generated frontage and one distant reveal.
- Camera authority is released before the first fade.
- Parish arrival is readable and northbound.
- The close checkpoint detail does not become another world-scale cinematic.
- The long east traverse is playable and collision-complete.
- No full-screen fog or black navigable corridor exists.
- The approach exit and reverse entry are route-owned normal fades.
- All approach placement records are editable in the production mapper.
- Required renderer frames contain no exposed clear color, gray overscan,
  rectangular composition seams, or unreadable route surface.
