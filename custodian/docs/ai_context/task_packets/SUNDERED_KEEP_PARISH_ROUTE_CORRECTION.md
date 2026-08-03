# Sundered Keep Parish Route Correction

- **Status:** superseded by authored-vista isolation correction
- **Authority:** `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md`, `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`, `design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md`
- **User brief:** repository-root `CODEX_IMPLEMENT_SUNDERED_KEEP_PARISH_ROUTE_CORRECTION.md`
- **Asset source:** repository-root `CUSTODIAN_parish_outer_wall_asset_pack.zip`

## Goal

The former goal of shipping a generated frontage and distant reveal inside the
live procgen world is superseded. Production now places only a compact ingress
on ordinary generated ground, fades into the authored Vista Approach / Shore
Parish, then fades into Front Gate.

## Scope

- Disable procgen frontage geometry and presentation behind explicit debug
  flags.
- Place the registered ingress through `north_edge_overlook`.
- Keep all ocean, storm, fortress, route-master, reveal, collision, enemies,
  and set dressing inside the authored approach.
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

- No generated Sundered Keep presentation or frontage authority in production
  procgen.
- The production ingress stands on valid procgen floor and enters the authored
  approach rather than Front Gate directly.
- Procgen visibility/processing and Operator/camera state restore on return or
  failure.
- No playable black corridor or full-screen navigable fog.
- Parish exit is at least 300 world pixels farther east with continuous mapped
  collision and visual ground.
- Front Gate arrival cannot immediately backtrack and has intentional lower
  camera coverage.
- Focused and existing route/procgen smokes pass.
- Required renderer captures exist under
  `reports/sundered_keep_route_correction/` for human review.

## Completion Notes

The generated-frontage completion notes and captures below are retained as
historical evidence for the archived experiment; they are not current
production acceptance authority. Runtime/data isolation validation is tracked
by `sundered_keep_procgen_vista_isolation_smoke.gd` and the authored first-
reveal Moment Forge capture.

Historical implementation notes:

Runtime/data implementation and focused structural validation were complete
for the now-superseded generated-frontage direction.
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
