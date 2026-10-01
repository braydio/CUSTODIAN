# PROCGEN GENERATION GRID MIGRATION SERIES AUTHORING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-grid-migration-series-authoring`
- Status: `blocked`
- Dispatch: `manual`
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
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Convert the reviewed post-D audit and reviewed GenerationGrid seam into the complete, dependency-correct implementation packet series needed to migrate the remaining generation pipeline to storage-agnostic semantics, add a pure-data backend, cut rejected candidate evaluation over to it, and retire the live-TileMap rejected-candidate path before D4.
- Completion boundary: REFRESH-GATED on the passed `review-procgen-generation-grid-foundation`. The exact migration cluster graph and even the canonical GenerationGrid API do not exist yet, so this packet must not author implementation work from stale pre-foundation assumptions. After XR2, rewrite this same packet in place from the reviewed X1 inventory + reviewed X2 seam, then publish only the migration DAG that live evidence supports.
- Current measured state: X1/X2 have not landed, so there is currently no reviewed post-D helper inventory, no canonical GenerationGrid seam, no pure-data backend, and no evidence-backed migration cluster dependency graph. `ProcGenTilemap` remains the live TileMap-backed generation working-state host. The previous packet text described reviewed predecessors as if they already existed.
- Evidence: current X1/XR1 and blocked X2/XR2 packet contracts; live `custodian/game/world/procgen/generation/` package; current `proc_gen_tilemap.gd`; current D4 blocked packet; S1/G1-G5 historical evidence.
- Task-specific authority: Reviewed X1 audit + reviewed X2 foundation once they exist; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; procgen roadmap and task-packet/review lifecycle.
- Work surface: Intentionally not locked while blocked. After XR2, this remains a docs/coordination-only workstream over the procgen roadmap, master roadmap, active task-packet directory/index, D4 dependency metadata, FILE_INDEX, and exact reviewed X1/X2 artifacts. No runtime `.gd` changes.
- Change: None while blocked. After XR2, author measured implementation/review packets for every remaining semantic-generation cluster exactly once, including pure-data backend parity, rejected-candidate cutover, legacy live-TileMap rejected-path demolition, and final convergence/soak; then rewrite D4's dependency to the actual final reviewed convergence workstream.
- Preserve: Current runtime code; reviewed audit/grid artifacts; historical G1-G5 evidence; M/P lanes; D1-D3 ownership; D4 intent as final façade contraction after the real generation-data migration.
- Non-goals: No runtime implementation; no helper migration; no guessing packet boundaries unsupported by the reviewed audit; no changes to gameplay/design content.
- Acceptance: Not authoring-ready until XR2. The refreshed packet must prove the generated DAG is acyclic, covers every audited cluster exactly once, names exact live helpers/owners and old-path disposition, includes pure-data/cutover/demolition/convergence stages, and rewires D4 only to a concrete final reviewed convergence workstream.
- Validation: After refresh, run `check_ai_context.py --json`, packet index checks, review-pairing validator, dependency-cycle/duplicate-workstream checks, dispatcher status, and `git diff --check`; no Godot run for the authoring-only slice.
- Task overrides: `none`
- Deferred: Runtime execution of the migration DAG generated after XR2.

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
