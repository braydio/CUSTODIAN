# Meridian Civic Wall Semantic Manifest

**Canonical manifest:** `custodian/content/metadata/assets/meridian_civic_wall.semantic.json`

**Human-review table:** `custodian/content/metadata/assets/meridian_civic_wall.semantic.csv`

This manifest describes the real **14×14 / 196-module** wall source sheet and its corrected per-module mapping into the first 14×14 cells of a 16×16, 512×512 runtime atlas.

## Runtime contract

- **authored_cell_world_px:** 32
- **runtime_tile_scale:** 1.0
- **unit_rule:** Every promoted wall module is a native 32x32 runtime cell. Do not stretch modules to create height.
- **composition_rule:** Broad horizontal structural mass/roof surface is owned by the floor/roof surface layer. This wall atlas owns exposed caps, faces, openings, rails, transitions, damage, and channel boundaries.
- **topology_first:** Choose geometry/topology class first, then choose a style variant within a compatible family. Never randomly select across corners, straights, terminals, openings, slopes, and damage.
- **orientation_rule:** Do not runtime-rotate or mirror these sprites. Lighting and asymmetric details are authored. Exact directional ports for review_required topology pieces must be reviewed before automatic neighbor-mask selection.
- **facade_rule:** front_facade/front_edge modules belong on authored exposed player-facing edges, not as tiled interior wall-body fill.
- **damage_rule:** Damaged/rubble modules are explicit authored beats only and must never be scattered into continuity-critical runs.
- **collision_rule:** Manifest collision hints are non-authoritative. Authored topology/collision/navigation remain gameplay authority.
- **y_sort_rule:** These are structural presentation modules, not free-standing native props. Depth/layer is determined by the wall presentation system.
- **reserved_rule:** Runtime coords with x>=14 or y>=14 are invalid/reserved transparent cells and must fail closed.

## Families

- **wall_cap** (13): Masonry cap/topology modules for exposed upper wall edges. Topology must be selected before style.
- **wall_pier** (1): Standalone masonry pier/support.
- **civic_opening** (14): Civic arch, gate, window, niche and portal modules.
- **utility_parapet** (10): Low utility parapet and railing modules.
- **retaining_wall** (9): Stone retaining wall faces, terminals and broken variants.
- **pipe_retaining** (10): Retaining wall modules with pipe/conduit language.
- **civic_railing** (4): Civic railing modules for exposed edges.
- **service_gate_edge** (2): Service gate/edge modules with stronger equipment identity.
- **grille_retaining** (16): Industrial grille retaining modules and terminals.
- **retaining_transition** (4): Slope, stair and retaining transitions. Never infer walkability from the sprite.
- **ornamental_railing** (12): Decorative railing and chain-railing vocabulary.
- **industrial_facade** (11): Heavy industrial/service facade modules.
- **rubble_transition** (13): Collapsed, rubble and breach transitions. Never use as random decoration in a continuity-critical wall run.
- **service_facade** (5): Service-facing doors, windows and panels.
- **ornate_facade** (14): Formal/ornate civic facade modules.
- **station_facade** (6): Station-oriented doors and high-formality facade modules.
- **damaged_facade** (11): Damaged doors, windows, collapsed facade faces and breaches.
- **hazard_facade** (15): Hazard-striped industrial retaining/facade modules.
- **hazard_transition** (4): Hazard-marked corners and slope transitions.
- **canal_edge** (15): Water/channel edge, straight, corner and terminal modules. Surface/collision remain separate authorities.
- **service_railing** (7): Service/industrial railing modules.

## Important authoring rule

Do **not** treat this as a bag of interchangeable wall tiles. The composer should resolve: **topology/edge role → family → exact variant**. `review_required=true` means the semantic family is reliable but exact directional ports should be confirmed before fully automatic neighbor-mask placement.

## Suggested validation

- Exactly 196 entries; every logical coordinate 0..13 × 0..13 appears once.
- Runtime coordinates equal source logical coordinates.
- No entry references runtime row/column 14 or 15.
- No `rotation_allowed` or `mirror_allowed` entry is true.
- Structural collision/navigation is never generated from image alpha.
- Automatic composer may use straight/front-facing modules immediately, but must fail closed on unreviewed corner/junction/slope/channel orientations until their directional ports are explicitly approved.
