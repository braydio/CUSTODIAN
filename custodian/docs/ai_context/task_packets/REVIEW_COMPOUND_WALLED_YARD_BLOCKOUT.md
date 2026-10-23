# REVIEW COMPOUND WALLED YARD BLOCKOUT

- Packet schema: custodian.task_packet.v2
- Workstream: review-compound-walled-yard-blockout
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: compound-walled-yard-blockout
- Locks: compound-layout
- Kind: review
- Review: none
- Review target workstream: compound-walled-yard-blockout
- Review target packet: custodian/docs/ai_context/task_packets/archived/COMPOUND_WALLED_YARD_BLOCKOUT.md
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Review modes: code, architecture, runtime, visual
- Review cycle: 0
- Max automatic review cycles: 2
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Visual review: conditional
- Goal: Independently verify the landed implementation of compound-walled-yard-blockout.
- Reviewed implementation acceptance: Every Acceptance item in custodian/docs/ai_context/task_packets/COMPOUND_WALLED_YARD_BLOCKOUT.md.
- Review evidence: Actual landed code, provenance, deterministic traces, smoke outputs and scoped changed-file validation.
- Correction threshold: Missing proof, second runtime authority, invalid geometry/nav, double state, broken backwards-compatibility or incomplete accepted behavior yields findings and correction, not PASS.
- Review focus: Seven seeds deterministic, boundary closes except authorized gates, all mandatory exterior doors and yard/service routes reachable; both gates open/closed give correct physical crossing, no missing floor/anchor or invalid spawn.
- Focused validation: Extend legacy planner/runtime validation and NEW closed-perimeter flood fill, ingress and clearance checks.
- Acceptance: Findings-first pass or bounded correction/re-review DAG with reproduction and exact impacted files; user visual acceptance not agent-owned.
- Non-goals: New runtime implementation, gameplay feel certification or retroactive art approval.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Independent Type A Codex review handoff (2026-10-17)

- The Type A blockout landed, but this review still needs a fresh, separately owned decision. Re-run true perimeter sealing, dual-gate/yard/building access, legacy compatibility, negative seal control and real generator smoke. A working gate electronics state machine is deferred to secure-access fixtures, so don't falsely require electronics now.
- The bunker R1 handoff is `custodian/docs/ai_context/workstream_handoffs/COMPOUND_BUNKER_R1_CODEX_TAKEOVER_20261017.md`; Type A has no acceptance dependency on bunker R1, but both reviews and correction share the `compound-layout` lock. Verify dispatcher ownership before running. For an automated paired review invoke `paired_review_runner.py` directly from a fresh Codex context, not `dispatch claim-next` then runner for the same ID.

## Handoff

- Next action: On genuine PASS, release review-gated descendants; on defect create one minimal correction and a fresh review.
- Blockers or open questions: None for deterministic acceptance; human feel/art remains separate.
