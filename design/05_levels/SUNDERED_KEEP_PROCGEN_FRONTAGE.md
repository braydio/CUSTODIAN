# Sundered Keep Procgen Frontage

- **Status:** active production authority; layering review required
- **Owner:** generated Sundered Keep frontage and distant reveal
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-11

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
non-floor cells remain chasm. Near-field 32×32 water and unambiguous cardinal
foam edges are visual-only and bridge generated coastline into the existing
large vista ocean/storm presentation.

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

The world-side camera uses one continuous spatial envelope: takeover begins at
`first_influence_start`, the horizon resolves at `first_reveal_apex`, fortress
presentation begins at `frontage_reveal_start`, fortress composition reaches
its apex at `frontage_apex`, and authority returns by `gameplay_return`.
Presentation targets interpolate from the reveal apex toward the generated gate
instead of using a fixed Operator-relative offset. Traversal remains unlocked;
the fortress apex receives a 0.9-second minimum presentation hold and triggers
the existing six-frame moonlight sweep once per presentation instance.

The active layering pass keeps the base storm horizon and moonlight punctuation,
but treats the first landmark as a temporary atmospheric silhouette rather than
a second fortress. It retires completely by 42% of frontage takeover, before
the final fortress becomes dominant. The one-shot reveal veil falls nearly away, and the persistent
horizon-seam fog becomes the architectural bridge. The outer wall and central
citadel use the established distant blue-gray palette at reduced `0.35` and
`0.33` scale. The approach gate-shadow veil is not part of this procgen vista;
the ordinary route fade owns the generated-frontage-to-authored-approach handoff.
The existing Descending Ward remains an optional review follow-up rather than an
automatically stacked layer.
The fortress presentation root is positioned once from
`fortress_front_anchor`; the outer wall and citadel retain their reviewed
scene-local offsets and are not pulled apart by gameplay-scale wall/tower
anchors. Generated frontage floor keeps its irregular authoritative footprint
but uses deterministic Keep cliff-rock, wet flagstone, and gate-threshold
sources so the Operator reads as standing on land. Cardinal ocean foam sources
are sparse transparent edge overlays rather than opaque water tiles. The
authoritative frontage-floor/ocean frontier also places the existing 64x96
Sundered Keep cardinal cliff compositions as presentation-only rock shelves;
foam is held to 34% layer alpha as secondary surf. These sprites add no
collision, navigation, or terrain authority.

The cinematic dressing-clearance envelope follows 94% of the generated route,
with wider discs at the first and fortress apexes. Foliage, ruin props,
interactables using normal spawn eligibility, and corridor encounter selection
consume the same protected frontage query; encounter content remains available
in unprotected side pockets. While the vista owns the camera, ordinary procgen
foliage, ruin-prop, and world-progress presentation layers plus the generated
ingress marker are hidden without disabling collision, interaction, navigation,
or spawned runtime state; all are restored when gameplay framing returns.
The storm underlay fit covers the full semantic reveal-to-fortress subject
travel in addition to the zoomed viewport and safety margin; exposing a finite
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

Review the cohesion pass at entry, takeover, first apex, fortress apex,
gameplay return, and terminal apron across production seeds and viewport sizes.
Tune presentation-only local offsets or floor-source weighting only if the
fortress, shoreline, or land mass still reads poorly; do not alter camera
choreography, generated floor geometry, route topology, or traversal authority.
