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
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Reduce procgen presentation node/render overhead by consolidating the highest-cost presentation-only owners identified by the attribution packet, without moving gameplay authority into visibility/render systems.
- Completion boundary: Done when the top measured compatible presentation owner(s) are consolidated behind existing semantic state, targeted owner node counts materially fall, pixels/streaming semantics remain correct, and no gameplay/collision/nav state is removed or visibility-gated.
- Current measured state: Attribution V1 ranks concrete presentation owners after generation/streaming/loader architecture has stabilized; prior capture showed roughly 10.8k total nodes and ~696-699 draw calls but did not identify safe consolidation owners.
- Evidence: PROCGEN_RENDER_ATTRIBUTION_V1 closing report; S1/S10a structured metrics; presentation-specific smokes and render isolation.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; attribution report; presentation-only ownership invariants.
- Work surface: Only the top one or two evidence-backed presentation subsystems plus their focused tests/metrics. Prefer existing containers/TileMap batching/MultiMesh only where art/material semantics are compatible.
- Change: Select the largest safe presentation-only owner and, if necessary, the next largest compatible owner. Replace per-item nodes with a coherent batched representation or lazy chunk-level realization while preserving semantic IDs, z/layering, deterministic placement, streaming hide/show and debug attribution. Keep an adapter only if a live consumer needs it and define its exit.
- Preserve: Exact gameplay topology/state, collision/navigation, interaction targets, visual registration, deterministic placements, streaming lifecycle, human-owned aesthetic baselines.
- Non-goals: No arbitrary batching of interactive/destructible/gameplay nodes; no content-density reduction; no shader/art redesign; no hidden simulation suppression.
- Acceptance: Combined targeted owner node count drops by at least 30% against S10a on the same cases, total procgen presentation nodes materially improve, draw calls do not materially regress, objective image/registration checks pass, and gameplay fingerprints remain unchanged.
- Validation: Target-owner focused smokes + attribution rerun + S1 runtime cases + smallest objective image/ROI checks needed for visual parity + changed-file closeout.
- Task overrides: `none`
- Deferred: Final end-to-end soak and stable regression budgets follow.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land measured consolidation; procgen-performance-soak-v1 becomes eligible.
- Best starting files: S10a attribution report; selected presentation owner files; streaming/chunk lifecycle; visual-economy tooling.
- Blockers or open questions: None known at authoring time.
