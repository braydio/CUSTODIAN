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
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Attribute procgen presentation node, rendered-object, and draw-call cost to concrete presentation owners before changing renderer structure.
- Completion boundary: Done when deterministic fixed-seed runtime cases report per-owner node/render object counts and compatible-isolation deltas for the major procgen presentation families, with no visual/gameplay output changes.
- Current measured state: S1 records total node/render/draw pressure and ProcGenTilemap already exposes a cached five-branch render-isolation surface, but no canonical report ranks which procgen presentation families actually own the load.
- Evidence: S1 benchmark; Developer Observatory render metrics; ProcGenTilemap isolation/debug surfaces; macro/road/foliage/depth presentation owners.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 schema; presentation-only ownership rules.
- Work surface: Developer Observatory/benchmark diagnostics and minimal presentation-owner tags/debug snapshots; no production rendering behavior changes.
- Change: Extend structured benchmark evidence with stable presentation-owner categories such as structural TileMaps, road/surface decals, foliage, ruin/interior props, macro stamps/depth presentation, wall overlays/shadows, ingress presentation and other measured families. Use existing isolation toggles where safe to estimate deltas; do not infer gameplay ownership from visibility. Produce a ranked JSON/report consumed by the next packet.
- Preserve: Pixels, node construction, gameplay authority, collision/navigation, streaming state and fixed-seed world output.
- Non-goals: No batching/MultiMesh conversion, no node deletion, no aesthetic changes, no broad renderer redesign.
- Acceptance: Fixed-seed attribution accounts for the overwhelming majority of procgen presentation nodes/rendered objects into named owners, reports unattributed residue explicitly, and repeated runs preserve fingerprints/presentation counts within deterministic expectations.
- Validation: New attribution smoke/report + S1 quick/runtime benchmark + existing render isolation/presentation smokes + changed-file closeout.
- Task overrides: `none`
- Deferred: Actual consolidation is the next packet and must target evidence-backed owners only.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, and finish normally so dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land attribution report; procgen-render-load-consolidation becomes eligible.
- Best starting files: DevObservatory procgen metrics; ProcGenTilemap render-isolation/debug snapshot; major procgen presentation services.
- Blockers or open questions: None known at authoring time.
