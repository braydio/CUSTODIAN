# PROCGEN GENERATION GRID MIGRATION SERIES AUTHORING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-grid-migration-series-authoring`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-generation-grid-foundation`
- Locks: `procgen-generation-roadmap`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `architecture, workflow`
- Paired review workstream: `review-procgen-generation-grid-migration-series-authoring`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `f2bc848515b8454f362167f57eb87bfe823ac184`
- Goal: Convert the reviewed post-D audit and reviewed GenerationGrid seam into the complete, dependency-correct implementation packet series needed to migrate the remaining generation pipeline to storage-agnostic semantics, add a pure-data backend, cut rejected candidate evaluation over to it, and retire the live-TileMap rejected-candidate path before D4.
- Completion boundary: Done when every remaining audited generation helper/cell-operation cluster has exactly one bounded migration owner; migration ordering reflects real read/write dependencies; a pure-data backend/parity packet, production candidate cutover packet, legacy evaluation-path demolition packet, final convergence/soak packet, and paired reviews are authored; D4's blocked state is replaced with an explicit dependency on the final reviewed convergence workstream; and no runtime implementation occurs in this authoring workstream.
- Current measured state: The reviewed audit provides the exact post-D1/D2/D3 helper/operation inventory and migration dependency graph. The reviewed GenerationGrid foundation provides the canonical storage API and TileMap-backed compatibility backend. Those two artifacts are the minimum evidence required to slice the broad migration honestly; before them, helper cluster boundaries were intentionally unknown.
- Evidence: Reviewed `procgen-generation-data-model-audit`; reviewed `procgen-generation-grid-foundation`; live post-foundation call graph; S1 benchmark; G1-G5 evaluator/materializer contracts; current D4 packet.
- Task-specific authority: Reviewed audit + reviewed grid foundation; `AGENT_TASK_PACKET_TEMPLATE.md`; procgen roadmap; current task-packet/review lifecycle.
- Work surface: Procgen roadmap/master roadmap, active task packet directory/index, D4 dependency/status metadata, FILE_INDEX, and only documentation/coordination artifacts needed to publish the migration DAG.
- Change: Author the remaining migration series from measured clusters, not arbitrary file chunks. Each implementation packet must name exact helpers/owners and old TileMap-backed path disposition; preserve deterministic fingerprints; use the shared GenerationGrid contract; have focused validation; include Completion Truth; and pair substantial architecture changes with independent review. The generated series must include, at minimum, stages that collectively: migrate every audited semantic-generation cluster off direct TileMapLayer storage access; implement a pure-data GenerationGrid backend; prove TileMap-backed vs pure-data semantic/fingerprint parity; switch rejected candidate construction/evaluation to the pure-data backend without Node/TileMap instantiation; keep accepted candidate materialization through G4/G5; remove production reachability of the legacy live-TileMap rejected-candidate path; run a rejection-heavy fixed-seed performance/correctness convergence; and only then unblock D4.
- Preserve: Current runtime code; reviewed audit/grid artifacts; historical G1-G5 evidence; M/P lanes; D1-D3 ownership; D4 intent as final façade contraction after the real generation-data migration.
- Non-goals: No runtime implementation; no helper migration; no guessing packet boundaries unsupported by the reviewed audit; no changes to gameplay/design content.
- Acceptance: Generated DAG is acyclic and fully pre-authored as far as reviewed evidence supports; every audited semantic helper/cell-operation cluster maps to exactly one implementation owner; no cluster is duplicated or orphaned; pure-data backend/cutover/demolition/convergence stages are explicit; each packet's Goal/Completion boundary/Acceptance collectively prove its own migration claim; D4 is updated to depend on the final reviewed convergence workstream rather than merely D1+D2+D3; dispatcher/task-packet validation and index checks are green.
- Validation: `check_ai_context.py --json`; task-packet index check; review-pairing validator; dependency-cycle/duplicate-workstream checks; dispatcher status confirms expected blocking/eligibility; `git diff --check`. No Godot run is required for docs-only packet authoring.
- Task overrides: `none`
- Deferred: Runtime execution of the newly authored migration series.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

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

- Next action: After paired review passes, the generated migration-series root packet(s) become eligible according to their declared dependencies; D4 remains blocked until that series' reviewed convergence packet completes.
- Best starting files: reviewed audit and grid-foundation summaries/artifacts; post-foundation roadmap; `PROCGEN_TILEMAP_FACADE_CONTRACTION.md`; active packet template/review template.
- Blockers or open questions: Exact migration packet count/names are intentionally determined from the reviewed audit; do not preselect them from the old ~40-helper/~147-call-site snapshot.
