# PROCGEN TILEMAP FACADE CONTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-tilemap-facade-contraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-road-authority-extraction, procgen-authored-claim-registry-extraction, procgen-generation-state-extraction`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Finish the V1 ProcGenTilemap decomplexification pass by deleting migration residue and locking the façade around coherent extracted authorities.
- Completion boundary: Done when ProcGenTilemap is a runtime state/TileMap host and coordinator with narrow delegation to generation, roads, claims, terrain, foliage, diagnostics, presentation, streaming and mutation services, with zero duplicated migrated algorithms.
- Current measured state: At this packet's current blocked state, D1 road authority, D2 authored-claim registry, and D3 generation-state extraction are still dependency-gated future work, not already-landed facts. The G3 correction additionally proved that ProcGenTilemap's remaining generation core uses TileMapLayer as working memory and requires the post-D1/D2/D3 GenerationGrid migration initiative before a truthful final façade contraction can begin.
- Evidence: `PROCGEN_SEMANTIC_CANDIDATE_GENERATION_CORRECTION_1_CLAUDE_SUMMARY.md`; `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; D1/D2/D3 packet contracts; the current blocked GenerationGrid X1/X2/X3 chain; S1 line/function baseline. Re-derive final line/function counts and read the actual D1/D2/D3/migration summaries before this packet is reactivated.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; ARCHITECTURE.md ownership model; extracted service APIs.
- Work surface: ProcGenTilemap cleanup, validation manifest, architecture/current-state/file index docs, focused façade/ownership smoke.
- Change: Delete zero-consumer migrated functions/state, simplify façade methods to delegation, tighten service initialization/lifecycle, and update validation ownership so edits to an extracted service select focused tests instead of broad ProcGenTilemap coverage. Measure lines/functions after cleanup but do not remove useful façade APIs solely for a number.
- Preserve: All runtime behavior/fingerprints, public methods required by current consumers, scene/node paths where consumers depend on them.
- Non-goals: No renderer consolidation, no gameplay retuning, no arbitrary helper extraction outside the three completed domains.
- Acceptance: No duplicate migrated road/claim/export algorithms remain; focused ownership tests prove callers route through service owners; ProcGenTilemap line/function count materially drops from S1 baseline with behavior green.
- Validation: Ownership/architecture smoke + representative road/claim/state/streaming/runtime health suites + S1 quick + changed-file closeout.
- Task overrides: `none`
- Deferred: Renderer/node attribution follows after placement loader contraction also completes.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Do not claim yet. Complete D1+D2+D3, then `procgen-generation-data-model-audit` → reviewed grid foundation → reviewed migration-series authoring → generated migration implementation/convergence. That series will update this packet's dependency metadata and restore it to ready/auto only after the TileMap-backed generation working representation is no longer a production rejected-candidate dependency.
- Best starting files: ProcGenTilemap; extracted roads/authored_claims/generation services; validation_manifest; ARCHITECTURE.md.
- Blockers or open questions: Blocked on the newly measured GenerationGrid migration initiative. The final convergence workstream ID is intentionally not guessed here; `procgen-generation-grid-migration-series-authoring` owns that exact dependency once the reviewed audit establishes the real migration clusters.
