# CORRECTION: Procgen Semantic Candidate Generation (G3) — Truthful Semantics-First Closure

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-semantic-candidate-generation-correction-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-task-packet-pipeline-execution-hardening-v1`
- Locks: `procgen-generation`
- Kind: `correction`
- Review: `none`
- Reviewed main: `076c436e9`
- Parent implementation: `procgen-semantic-candidate-generation` — `custodian/docs/ai_context/task_packets/archived/PROCGEN_SEMANTIC_CANDIDATE_GENERATION.md`
- Parent review: `none` — this correction was not produced by a paired independent-review cycle on the parent packet (G3 declared `Review: none`). It originates from `task-packet-pipeline-execution-hardening-v1`'s own postmortem, which found G3's landed roadmap evidence overstated its closure while auditing agent-pipeline completion-truth. See `Current defect/evidence` below in place of numbered finding IDs.
- Findings addressed: `n/a (see Current defect/evidence; not sourced from a numbered independent-review receipt)`
- Affected acceptance: G3's own claimed acceptance — "G3 lands S3's Exit condition: rejected eval-mode candidates no longer pay for final-presentation/collision realization" — and S3's own Exit condition in `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`: "Rejected attempts should die as data without final TileMap painting, runtime nodes, props, streaming setup, shadows, collision bodies, or navigation realization."
- Current defect/evidence: G3 (landed main SHA `3f729650d`) gates three specific presentation/collision *rebuild* functions inside `_fill_tilemaps()` — `_rebuild_runtime_wall_collision()`, `_rebuild_nonwalkable_surface_visuals()`, `_rebuild_runtime_walkable_boundary()` — behind `not generation_evaluation_mode`, per the roadmap's own G3 Completion Evidence section. It does not change candidate construction's live-node cost: `CustodianContractMap`'s candidate loop still instantiates a live `ProcGenTilemap` (the `proc_gen_map.tscn`/`ProcGenTilemap` TileMap node and its presentation/collision/nav scaffolding) for every rejected attempt before the G2 semantic snapshot is built and evaluated. Rejected candidates therefore do not yet "die as data" in the sense S3's Exit condition requires; they still pay live-node instantiation cost G3's roadmap evidence implied was eliminated. See the correction note now recorded directly in `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`'s G3 Completion Evidence section.
- Goal: Make rejected-candidate evaluation possible from semantic data alone, without instantiating `proc_gen_map.tscn`/`ProcGenTilemap`/TileMap/presentation/collision/nav nodes for any rejected attempt, and correct S3/G3's roadmap claim to match what is actually true afterward.
- Completion boundary: Close only the gap between "semantic snapshot built and evaluated" and "candidate construction no longer requires a live `ProcGenTilemap` node for a rejected attempt." Do not redesign candidate generation, acceptance scoring, or the G2 semantic model's contents; do not touch the accepted-candidate materialization path (G4/G5), runtime mutation scheduling (M-lane), or placement extraction (P-lane). The live-node/TileMap adapter path may remain in the codebase only as an explicit parity oracle or test seam (for example to cross-check the semantics-first path's snapshot against the historical live-node snapshot during this transition) until the semantics-first path is proven correct and the live-node path for rejected attempts is provably removable; it must not remain the production path for rejected-candidate evaluation.
- Current measured state: Per `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`'s G2/G3 Completion Evidence (re-derived from that live roadmap text at the SHA above, not carried over stale): G2 already builds a `custodian.procgen_candidate_semantic_model.v1` snapshot from an *already-generated* candidate via `candidate_semantic_adapter.gd`, and `CandidateEvaluator.evaluate_snapshot()`/`measure_snapshot()` already evaluate purely from that snapshot with verified parity against the live-node evaluator. What G2/G3 did not change is *how the candidate used to build that snapshot comes into being* — it is still constructed via the live `ProcGenTilemap` path. This is the correction's actual target: move candidate construction itself onto a semantics-first path so the live `ProcGenTilemap` instantiation this snapshot is adapted from is no longer required for a rejected attempt.
- Evidence: `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` G2/G3 Completion Evidence sections (landed SHAs `bd72df6a4`, `3f729650d`) and this packet's correction note therein; `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd` (adapts an existing live candidate into the snapshot rather than constructing one from semantic data); `CandidateEvaluator.evaluate_snapshot()`/`measure_snapshot()` (already snapshot-only, reusable by a semantics-first constructor without modification).
- Task-specific authority: `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` (S3 Goal/Exit, G2/G3 Completion Evidence and this packet's correction note); `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd` and the G2 semantic model contract; `CandidateEvaluator`'s snapshot-mode evaluation contract.
- Work surface: Candidate construction inside `CustodianContractMap`'s candidate loop and its semantic-model production path (`candidate_semantic_adapter.gd` and any new semantics-first constructor it requires); consumers are `CandidateEvaluator.evaluate_snapshot()`/`measure_snapshot()` (already snapshot-only, must not require behavior changes) and the existing G2/G3 focused smokes (`procgen_candidate_semantic_model_smoke.gd`, `procgen_candidate_evaluator_smoke.gd`, `procgen_contract_rescue_diagnostic_smoke.gd`, `procgen_terrain_required_cells_smoke.gd`).
- Required correction: Production rejected-candidate evaluation must be reachable from semantic data without instantiating `proc_gen_map.tscn`, `ProcGenTilemap`, or any TileMap/presentation/collision/nav node for that rejected attempt. The live-adapter (`candidate_semantic_adapter.gd`'s current node-to-snapshot path) may remain in the codebase only as an explicit, clearly-labeled parity oracle or test seam — never the production path a rejected attempt runs through — until proven removable. Accepted-candidate handling (G4 materialization) is unaffected; it already receives a real `ProcGenTilemap`. Update `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`'s S3 Exit condition status and G3 Completion Evidence to state plainly, without overstatement, exactly what this correction closes and what (if anything) remains open afterward.
- Preserve: G2's semantic snapshot contract, fingerprint stability, and `CandidateEvaluator.evaluate_snapshot()`/`measure_snapshot()` parity with the live-node evaluator; G4/G5 accepted-candidate materialization and its runtime fingerprint contract; all currently-passing S1/G1-G5 focused smokes and their exact pass semantics; determinism across fixed S1 seeds.
- Non-goals: No changes to runtime mutation scheduling (M-lane), placement extraction (P-lane), accepted-candidate materialization internals, or the G2 semantic model's field contents. No broad ProcGenTilemap façade contraction (that is D4, later, dependency-gated on G5+M6). No performance soak or benchmark sweep as part of this correction; that is S11/F1's job.
- Acceptance: A focused test demonstrates a rejected candidate attempt evaluated end-to-end (semantic snapshot construction through `CandidateEvaluator.evaluate_snapshot()` accept/reject decision) without any `ProcGenTilemap`/TileMap node, presentation node, collision body, or nav node existing for that attempt at any point during the attempt — falsifiable by asserting zero such nodes were created for rejected attempts, not by inspecting timing alone. Existing G1-G5 focused smokes continue to pass unchanged (evaluator/semantic-model parity, terrain-required-cells, contract-rescue diagnostic 36/36 seeds, S1 quick/full fixed-seed determinism). If the live-node adapter path is preserved as a parity oracle, it is clearly labeled as test/parity-only in code and docs, not reachable from the production rejected-candidate path. `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`'s S3 Exit condition and G3 Completion Evidence read truthfully after this lands — no overstated closure claim remains uncorrected.
- Validation: `procgen_candidate_semantic_model_smoke.gd`, `procgen_candidate_evaluator_smoke.gd`, `procgen_contract_rescue_diagnostic_smoke.gd`, `procgen_terrain_required_cells_smoke.gd`, a new focused smoke proving zero live nodes for rejected attempts, S1 quick fixed-seed determinism; changed-file closeout. No broad procgen benchmark sweep required for this correction.
- Task overrides: `none`
- Deferred: Proving the live-adapter path fully removable (versus retained long-term as a parity oracle) is a follow-up decision once the semantics-first path has run long enough to build confidence; M-lane/D-lane/P-lane work remains out of scope here and continues to follow the roadmap's existing dependency order.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG and corrects G3's overstated closure within it rather than replacing it. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching `design/00_meta/MASTER_ROADMAP.md` row at closeout with truthful landed evidence, then finish normally so `procgen-runtime-mutation-scheduler-cutover` (M2) — which now also depends on this workstream — can become eligible/resumed.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `<removed | intentionally-preserved | n/a — fill at closeout>`
- Evidence: `<fill at closeout with concrete files/tests/runtime observations>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Claim via `dispatch.py claim procgen-semantic-candidate-generation-correction-1 --agent <agent-id>` once `review-task-packet-pipeline-execution-hardening-v1` has passed. Do not claim before then; the dependency is enforced by the dispatcher, not by convention.
- Best starting files: `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd`; `CandidateEvaluator.evaluate_snapshot()`/`measure_snapshot()`; `CustodianContractMap`'s candidate loop; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` S3/G2/G3 sections.
- Blockers or open questions: Whether the live-node adapter path can be proven fully removable versus needing to stay as a permanent parity oracle is an open question this correction does not have to resolve; ship the semantics-first production path and record whichever disposition is actually true.
