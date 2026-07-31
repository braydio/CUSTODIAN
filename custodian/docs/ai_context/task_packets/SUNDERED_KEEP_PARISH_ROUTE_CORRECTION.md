# Sundered Keep Parish Route Correction

- **Status:** review
- **Authority:** `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md`, `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`, `design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md`
- **User brief:** repository-root `CODEX_IMPLEMENT_SUNDERED_KEEP_PARISH_ROUTE_CORRECTION.md`
- **Asset source:** repository-root `CUSTODIAN_parish_outer_wall_asset_pack.zip`

## Goal

Ship the production route as generated frontage with one distant reveal,
ordinary fade into the authored Shore Parish with one close-detail reveal and
a longer grounded checkpoint traverse, then ordinary fade into Front Gate.

## Scope

- Materialize and protect procgen frontage floor/corridor authority.
- Remove the second procgen and authored Parish camera pulls.
- Integrate the supplied northbound, eastbound, checkpoint-detail, local-fog,
  and Front Gate arrival-apron assets.
- Extend mapper-owned Parish markers, subregions, rails, and exit eastward.
- Guard Front Gate arrival from immediate backtracking.
- Update route, renderer, and reverse-traversal regression coverage.

## Constraints

- Procgen presentation sprites never own floor, collision, navigation, or
  encounter authority.
- Parish overlays own visuals only; mapper JSON owns layout and collision.
- Return Causeway remains debug-only.
- Production transitions use existing ordinary fades.
- Status remains `review` until 2560x1440 renderer captures are human-approved.

## Acceptance

- No water-walking or ordinary blockers in protected frontage cells.
- Exactly one procgen reveal and one Parish reveal release camera authority in
  both directions.
- No playable black corridor or full-screen navigable fog.
- Parish exit is at least 300 world pixels farther east with continuous mapped
  collision and visual ground.
- Front Gate arrival cannot immediately backtrack and has intentional lower
  camera coverage.
- Focused and existing route/procgen smokes pass.
- Required renderer captures exist under
  `reports/sundered_keep_route_correction/` for human review.

## Completion Notes

Runtime/data implementation and focused structural validation are complete.
The supplied five assets are imported and mapper/runtime-wired. Production
edges are ordinary fades, procgen exposes one camera envelope and protected
frontage cells, Parish owns four visual overlay records and 45 collision rails,
and Front Gate owns its presentation apron plus 144 px arrival guard.

Renderer evidence exists at 2560×1440 under
`reports/sundered_keep_route_correction/`:

- `procgen_normal_gameplay.png`
- `procgen_first_reveal_apex.png`
- `procgen_reverse_south_camera_released.png`
- `procgen_generated_frontage_exit.png`
- `parish_arrival_northbound.png`
- `parish_close_detail_reveal.png`
- `parish_long_east_traverse.png`
- `front_gate_arrival_clear.png`

Automated review found visible rectangular/seam artifacts in the authored
Parish composites and gray overscan below the Front Gate arrival frame. These
are recorded visual-review findings, not suppressed test failures. The packet
therefore remains `review` pending human approval or a follow-up art-layout
pass. Do not promote it solely on structural smoke success.

Validation run on 2026-07-31:

- `sundered_keep_procgen_frontage_smoke.gd` — PASS, 24 seeds / 24 fingerprints;
- `sundered_keep_world_vista_smoke.gd` — PASS;
- `sundered_keep_approach_smoke.gd` — PASS;
- `sundered_keep_approach_outskirts_mapper_smoke.gd` — PASS;
- `sundered_keep_route_graph_smoke.gd` — PASS;
- `route_profile_selection_smoke.gd` — PASS;
- `sundered_keep_large_layout_smoke.gd` — PASS;
- `sundered_keep_parish_route_correction_smoke.gd` — PASS;
- `run_procgen_validation_suite.sh` — PASS (slow diagnostic omitted by the
  suite's default configuration);
- `run_route_pipeline_suite.sh` — PASS after replacing obsolete authored
  Camera 1/Camera 2 polish gates with the current Parish contract smokes.

Known non-failing harness noise remains: missing navigation warnings for
isolated enemy fixtures and ObjectDB/resource leak diagnostics at Godot exit.
