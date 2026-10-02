# PROCGEN AUTHORED CLAIM REGISTRY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-authored-claim-registry-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, review-procgen-distant-chunk-unload`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `30df23bb4bb2736aeebbf6032fc9560d0b494117`
- Goal: Extract authored floor/overlook/ingress-clearance/reservation ownership from ProcGenTilemap into one canonical claim registry.
- Completion boundary: REFRESH-GATED on reviewed M6 / MR6. Re-audit post-MR6 claim/reservation state before execution. The eventual slice closes when authored-scene floor claims, overlook-pocket plans/commits, ingress dressing-clearance claims, worldgen/terrain reservations that are genuinely the same claim concept, and claim/conflict queries mutate/query one canonical registry under the existing `custodian/game/world/procgen/authored_claims/` package, while runtime prop blockers and unrelated playability state remain with their current owners.
- Current measured state: `custodian/game/world/procgen/authored_claims/README.md` is scaffold-only and still points to `ProcGenTilemap`. Live claim APIs include `claim_procgen_floor_rect_for_authored_scene_world`, `claim_procgen_floor_rect_for_authored_scene_tiles`, `claim_world_overlook_pocket`, `plan_world_overlook_pocket`, `commit_world_overlook_pocket_plan`, `_claim_isolated_world_overlook_pocket`, `claim_world_ingress_dressing_clearance`, `is_inside_world_ingress_dressing_clearance`, and `clear_world_ingress_dressing_clearances`, alongside several reservation dictionaries/terrain-required-cell adapters. Runtime prop blockers are a separate mutation concern and must not be swept into the claim registry by name similarity.
- Evidence: `custodian/game/world/procgen/authored_claims/README.md`; current claim/reservation functions/state in `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/diagnostics/procgen_required_cell_classifier.gd`; `custodian/tools/validation/ash_bell_threadway_generation_contract_smoke.gd`; `custodian/tools/validation/sundered_keep_procgen_frontage_smoke.gd`; `custodian/tools/validation/sundered_keep_ingress_smoke.gd`; `custodian/tools/validation/procgen_terrain_required_cells_smoke.gd`; eventual reviewed M6/MR6 state.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; authored-scene procgen authority reservation API; current terrain/ingress clearance contracts.
- Work surface: Intentionally refresh-gated. Expected canonical package is the existing `custodian/game/world/procgen/authored_claims/` scaffold, with narrow compatibility methods retained on `ProcGenTilemap` only where live callers need them. `custodian/game/world/procgen/diagnostics/procgen_required_cell_classifier.gd` remains diagnostics/classification unless the post-MR6 audit proves ownership belongs elsewhere.
- Change: None while blocked. After M6, classify every claim/reservation dictionary and API by semantic ownership first, then extract only the unified authored/worldgen claim concept. Preserve existing public claim APIs as façade delegates where callers depend on them; do not absorb runtime blockers, authored-level gameplay state, or presentation.
- Preserve: All claim extents, conflict/clearance behavior, ingress frontage, terrain required cells, encounter clearances and fixed-seed results.
- Non-goals: No authored-level redesign, no new claim kinds unless required to faithfully represent current state, no generation export extraction.
- Acceptance: Not implementation-ready until refreshed post-MR6. Final acceptance must enumerate every migrated and intentionally-unmigrated claim/reservation store, leave no duplicate authoritative claim dictionaries, preserve exact claim extents/conflicts/required-cell effects, and expose a deterministic registry snapshot.
- Validation: Refresh after MR6. Expected focused suite includes `res://tools/validation/ash_bell_threadway_generation_contract_smoke.gd`, `res://tools/validation/sundered_keep_procgen_frontage_smoke.gd`, `res://tools/validation/sundered_keep_ingress_smoke.gd`, `res://tools/validation/procgen_terrain_required_cells_smoke.gd`, stuck-pocket/connector regressions selected by the manifest, and changed-file closeout.
- Task overrides: `none`
- Deferred: Generation state/export extraction and façade contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally. Once D1+D2+D3 are all complete, `procgen-generation-data-model-audit` becomes eligible. D4 no longer follows these siblings directly; it is blocked behind the measured GenerationGrid migration initiative.
- Best starting files: ProcGenTilemap claim/reservation methods; authored_claims scaffold; terrain/ingress tests.
- Blockers or open questions: None known at authoring time.
