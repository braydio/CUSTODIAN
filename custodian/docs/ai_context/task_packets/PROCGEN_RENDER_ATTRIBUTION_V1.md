# PROCGEN RENDER ATTRIBUTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-render-attribution-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-tilemap-facade-contraction, contract-world-loader-contraction`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Attribute procgen presentation node, rendered-object, and draw-call cost to concrete presentation owners before changing renderer structure.
- Completion boundary: Done when deterministic fixed-seed runtime cases report per-owner node/render object counts and compatible-isolation deltas for the major procgen presentation families, with no visual/gameplay output changes.
- Current measured state: Pre-contraction runtime already exposes a concrete render-isolation surface in `custodian/game/world/procgen/proc_gen_tilemap.gd`: `set_procgen_major_visuals_visible()`, `set_runtime_wall_collision_isolation_enabled()`, `set_wall_shadow_isolation_enabled()`, and `get_procgen_render_isolation_status()`. The status currently reports Floor, Walls, DepthBackdrop, NonWalkableSurfaceBase, NonWalkableSurfaceOverlay, SurfaceMaterialOverlay, runtime wall collision, and wall-shadow isolation. Presentation gauges already expose foliage sprite, road decal, interior prop, fruit sprite, and macro stamp counts. Focused presentation owners exist under `custodian/game/world/procgen/presentation/`, `foliage/`, `dressing/`, `surfaces/`, terrain/nonwalkable code, and ruin/interior prop paths. S1 provides total node/render/draw pressure, but there is still no canonical per-owner attribution report.
- Evidence: `custodian/game/world/procgen/proc_gen_tilemap.gd` render-isolation API and presentation gauges; `custodian/tools/validation/procgen_render_isolation_smoke.gd`; `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`; `custodian/game/world/procgen/presentation/`; `custodian/game/world/procgen/foliage/`; `custodian/game/world/procgen/dressing/`; `custodian/game/world/procgen/surfaces/`; Developer Observatory; S1 benchmark.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 schema; presentation-only ownership rules.
- Work surface: Re-inventory the **post-D4/P7 live presentation owners** at task start, then extend structured diagnostics primarily through `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`, `custodian/game/systems/debug/dev_observatory.gd` / existing observability surfaces, and only minimal owner tags/snapshots in the actual presentation packages. Reuse `ProcGenTilemap` render-isolation controls only while they still exist after D4; do not preserve façade residue just for this packet.
- Change: On the landed post-D4/P7 architecture, attribute presentation cost to concrete current owners rather than a hard-coded pre-contraction list. Start from structural TileMaps and the live isolation surface, then measure road/surface presentation, foliage/dressing, ruin/interior props, macro/depth/void presentation, nonwalkable/coastline presentation, shadows/overlays, ingress presentation, and any new owner introduced by the preceding extractions. Produce ranked structured JSON/report with explicit unattributed residue; do not change production rendering.
- Preserve: Pixels, node construction, gameplay authority, collision/navigation, streaming state and fixed-seed world output.
- Non-goals: No batching/MultiMesh conversion, no node deletion, no aesthetic changes, no broad renderer redesign.
- Acceptance: Fixed-seed attribution accounts for the overwhelming majority of procgen presentation nodes/rendered objects into named owners, reports unattributed residue explicitly, and repeated runs preserve fingerprints/presentation counts within deterministic expectations.
- Validation: `res://tools/validation/procgen_render_isolation_smoke.gd`, S1 quick/runtime benchmark, directly affected macro/foliage/surface/nonwalkable presentation smokes selected from `validation_manifest.json`, the new attribution report validation created in this workstream, and changed-file closeout. No aesthetic capture is required for attribution-only work.
- Task overrides: `none`
- Deferred: Actual consolidation is the next packet and must target evidence-backed owners only.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land attribution report; procgen-render-load-consolidation becomes eligible.
- Best starting files: DevObservatory procgen metrics; ProcGenTilemap render-isolation/debug snapshot; major procgen presentation services.
- Blockers or open questions: None known at authoring time.
