# PROCGEN AUTHORED CLAIM REGISTRY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-authored-claim-registry-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, procgen-distant-chunk-unload`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Extract authored floor/overlook/ingress-clearance/reservation ownership from ProcGenTilemap into one canonical claim registry.
- Completion boundary: Done when authored-scene floor claims, overlook pockets, ingress dressing clearances, terrain reservations, encounter reservations, and claim queries mutate/query one registry with ProcGenTilemap delegating.
- Current measured state: ProcGenTilemap owns claim_procgen_floor_rect_for_authored_scene_*, claim_world_overlook_pocket, claim_world_ingress_dressing_clearance and multiple reserved-region/cell dictionaries/helpers.
- Evidence: Ash-Bell authored reservation work; Sundered Keep frontage/ingress smokes; terrain required-cell diagnostics; chunk lifecycle/cache.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; authored-scene procgen authority reservation API; current terrain/ingress clearance contracts.
- Work surface: game/world/procgen/authored_claims/ registry, ProcGenTilemap delegation, reservation/ingress/terrain tests.
- Change: Create one deterministic registry for claim type, bounds/cells, owner/source, and optional clearance metadata. Migrate existing claim APIs to it without changing callers where unnecessary. Registry owns data/conflict queries, not authored-scene traversal or presentation.
- Preserve: All claim extents, conflict/clearance behavior, ingress frontage, terrain required cells, encounter clearances and fixed-seed results.
- Non-goals: No authored-level redesign, no new claim kinds unless required to faithfully represent current state, no generation export extraction.
- Acceptance: Existing claim/terrain/ingress tests match exactly; no duplicate claim dictionaries remain in ProcGenTilemap; registry snapshot is deterministic.
- Validation: Ash-Bell reservation/Threadway + Sundered Keep frontage/ingress + terrain required-cells + stuck-pocket protections + changed-file closeout.
- Task overrides: `none`
- Deferred: Generation state/export extraction and façade contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; ProcGenTilemap facade contraction waits for all three extraction siblings.
- Best starting files: ProcGenTilemap claim/reservation methods; authored_claims scaffold; terrain/ingress tests.
- Blockers or open questions: None known at authoring time.
