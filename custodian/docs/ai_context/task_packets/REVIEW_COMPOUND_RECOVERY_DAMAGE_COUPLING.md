# REVIEW COMPOUND RECOVERY DAMAGE COUPLING

- Packet schema: custodian.task_packet.v2
- Workstream: review-compound-recovery-damage-coupling
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: compound-recovery-damage-coupling
- Locks: compound-recovery
- Kind: review
- Review: none
- Review target workstream: compound-recovery-damage-coupling
- Review target packet: custodian/docs/ai_context/task_packets/archived/COMPOUND_RECOVERY_DAMAGE_COUPLING.md
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Review modes: code, architecture, runtime, visual
- Review cycle: 0
- Max automatic review cycles: 2
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Visual review: conditional
- Goal: Independently verify the landed implementation of compound-recovery-damage-coupling.
- Reviewed implementation acceptance: Every Acceptance item in custodian/docs/ai_context/task_packets/COMPOUND_RECOVERY_DAMAGE_COUPLING.md.
- Review evidence: Actual landed code, provenance, deterministic traces, smoke outputs and scoped changed-file validation.
- Correction threshold: Missing proof, second runtime authority, invalid geometry/nav, double state, broken backwards-compatibility or incomplete accepted behavior yields findings and correction, not PASS.
- Review focus: Equal real damage in each archetype causes deterministic nonzero service loss, correct grid load-shedding, restoration via heal, exact snapshots and no ghost output/double health.
- Focused validation: Existing infrastructure/capacitor/service smokes and NEW archetype damage/revisit test.
- Acceptance: Findings-first pass or bounded correction/re-review DAG with reproduction and exact impacted files; user visual acceptance not agent-owned.
- Non-goals: New runtime implementation, gameplay feel certification or retroactive art approval.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Handoff

- Next action: On genuine PASS, release review-gated descendants; on defect create one minimal correction and a fresh review.
- Blockers or open questions: None for deterministic acceptance; human feel/art remains separate.
