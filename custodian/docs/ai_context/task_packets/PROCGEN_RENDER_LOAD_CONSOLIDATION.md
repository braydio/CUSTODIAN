# PROCGEN RENDER LOAD CONSOLIDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-render-load-consolidation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-render-attribution-v1`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Reduce procgen presentation node/render overhead by consolidating the highest-cost presentation-only owners identified by the attribution packet, without moving gameplay authority into visibility/render systems.
- Completion boundary: REFRESH-GATED on landed `procgen-render-attribution-v1`. Do not choose a batching/lazy-realization target before attribution measures the post-D4/P7 runtime. After V1 attribution, rewrite this same packet in place to the exact top safe owner(s), exact files/material constraints, baseline counts, visual/objective parity checks, and target reduction.
- Current measured state: Attribution V1 has not run, so there is no evidence-backed highest-cost compatible presentation owner to consolidate. Current pre-contraction runtime contains structural TileMaps plus separate macro/depth, foliage/dressing, road/surface decals, props, nonwalkable/coastline and shadow/overlay presentation, but D4/P7 may change ownership boundaries before attribution. The old packet incorrectly spoke as if the ranked attribution report already existed.
- Evidence: current `PROCGEN_RENDER_ATTRIBUTION_V1.md`; live render-isolation/presentation gauges in `proc_gen_tilemap.gd`; existing presentation package paths; S1 baseline. The future V1 attribution closing report becomes the primary evidence when this packet is refreshed.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; attribution report; presentation-only ownership invariants; `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md` and the active frame-specific visual lock.
- Work surface: Intentionally not locked while blocked. After attribution, select only the top measured presentation-only owner(s) whose semantics/material/z-order/streaming constraints permit consolidation, and name their exact landed files plus focused tests in the refreshed packet.
- Change: None while blocked. Do not preselect MultiMesh, TileMap batching, chunk containers, or lazy realization before attribution proves the owner and compatibility constraints.
- Preserve: Exact gameplay topology/state, collision/navigation, interaction targets, visual registration, deterministic placements, streaming lifecycle, and the selected region-frame visual baseline.
- Non-goals: No arbitrary batching of interactive/destructible/gameplay nodes; no content-density reduction; no shader/art redesign; no hidden simulation suppression.
- Acceptance: Not implementation-ready. The refreshed packet must name the measured owner baseline, exact target files, why the owner is presentation-only, objective pixel/registration/state parity checks, and an evidence-backed reduction target. Gameplay/interaction/destruction owners are excluded.
- Validation: Not implementation-ready. Refresh from the V1 attribution report, then run only target-owner focused smokes, attribution rerun, S1 runtime cases, smallest objective ROI/image checks needed for parity, and changed-file closeout.
- Task overrides: `none`
- Deferred: Final end-to-end soak and stable regression budgets follow.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.


## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh instruction: Bring the landed predecessor implementation/review summary and any new live-state evidence back to this ChatGPT conversation. Re-derive this packet here with the user against current `main` before changing it to `ready/auto`. Do not let the execution agent silently reinterpret architecture, scope, sequencing, visual direction, or acceptance during the refresh.

## Handoff

- Next action: Land measured consolidation; procgen-performance-soak-v1 becomes eligible.
- Best starting files: S10a attribution report; selected presentation owner files; streaming/chunk lifecycle; visual-economy tooling.
- Blockers or open questions: None known at authoring time.