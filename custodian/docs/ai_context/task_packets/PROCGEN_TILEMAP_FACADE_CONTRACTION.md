# PROCGEN TILEMAP FACADE CONTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-tilemap-facade-contraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-generation-grid-migration-series-authoring`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `d20010d86eee9540e3dd6e759bb5e359de9a46a8`
- Goal: Finish the V1 ProcGenTilemap decomplexification pass by deleting migration residue and locking the façade around coherent extracted authorities.
- Completion boundary: HARD BLOCKED. XR3 is only the gate that authors/reviews the measured migration DAG; D4 still must not return to `ready` until that generated DAG has executed through its **final reviewed convergence workstream**. X3/XR3 must rewrite this packet's `Depends on` to that concrete final review ID. Only then re-audit `ProcGenTilemap` and define the exact contraction residue.
- Current measured state: `ProcGenTilemap` remains the large generation/runtime façade and still owns generation working state, road/parking topology, authored claims, accepted-state export, streaming adapters, terrain integration, props/foliage, presentation and runtime mutation glue. M4/MR4 and M5/MR5 are complete; M6 is now refreshed and ready with paired MR6 required before S7 closes. D1/D2/D3 are explicitly refresh-gated on **MR6**, not merely M6 landing; X1 follows those extractions, X2/X3 remain refresh-gated on their paired reviews, and the measured migration DAG still does not exist. Therefore no truthful D4 deletion list or final dependency exists today.
- Evidence: current `custodian/game/world/procgen/proc_gen_tilemap.gd`; D1/D2/D3 packets; X1/XR1; blocked X2/XR2 and X3/XR3; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; S1 baseline.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; ARCHITECTURE.md ownership model; extracted service APIs.
- Work surface: Intentionally not frozen. After final migration convergence, re-inventory the surviving `custodian/game/world/procgen/proc_gen_tilemap.gd` façade, its actual extracted owners under `procgen/roads/`, `procgen/authored_claims/`, `procgen/generation/`, `procgen/streaming/`, plus existing terrain/foliage/diagnostics/presentation packages; then rewrite this packet to exact zero-consumer residue and focused ownership tests.
- Change: None while blocked. Final contraction is deletion/delegation cleanup only after the generation-data migration truly converges; do not use D4 as a substitute for unfinished migration work.
- Preserve: All runtime behavior/fingerprints, public methods required by current consumers, scene/node paths where consumers depend on them.
- Non-goals: No renderer consolidation, no gameplay retuning, no arbitrary helper extraction outside the three completed domains.
- Acceptance: Not implementation-ready. The refreshed post-convergence packet must name exact old functions/state to remove or intentionally preserve, prove no duplicate migrated algorithms remain, preserve required façade APIs/scene paths, and measure line/function reduction without using a numeric target as architecture authority.
- Validation: Not implementation-ready. Re-derive after final migration convergence from the actual extracted owners and surviving façade; expected closeout includes focused ownership tests, representative road/claim/generation/streaming/runtime-health suites, S1 quick, and changed-file closeout.
- Task overrides: `none`
- Deferred: Renderer/node attribution follows after placement loader contraction also completes.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Do not claim yet. Complete D1+D2+D3, then `procgen-generation-data-model-audit` → reviewed grid foundation → reviewed migration-series authoring → generated migration implementation/convergence. That series will update this packet's dependency metadata and restore it to ready/auto only after the TileMap-backed generation working representation is no longer a production rejected-candidate dependency.
- Best starting files: ProcGenTilemap; extracted roads/authored_claims/generation services; validation_manifest; ARCHITECTURE.md.
- Blockers or open questions: Blocked on the newly measured GenerationGrid migration initiative. The final convergence workstream ID is intentionally not guessed here; `procgen-generation-grid-migration-series-authoring` owns that exact dependency once the reviewed audit establishes the real migration clusters.
