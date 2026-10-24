# REVIEW AGENT PIPELINE RECOVERY MASTER V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-pipeline-recovery-master-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `agent-pipeline-recovery-master-v1`
- Locks: `pipeline-recovery-bootstrap`
- Review: `none`
- Review stage: `post-land`
- Review target workstream: `agent-pipeline-recovery-master-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PIPELINE_RECOVERY_MASTER_V1.md`
- Reviewed main: `7b82b9630e9a63c52e86f8b4805c577a85496aa5`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the P0 bootstrap's truthfulness, deterministic offline behavior, safe claim/frontier classification, absence of mutating authority and verified self-failure escape hatch before any automatic recovery mutation is authorized.
- Reviewed implementation acceptance: A1-A7 in `AGENT_PIPELINE_RECOVERY_MASTER_V1.md`, including bytes-stable identical snapshots, accepted-review distinction, exact unknown-owner protection, pinned offline plan, zero repo/ref/worktree mutations, existing packet reuse and documentation-drift evidence.
- Review evidence: Fresh main and archived implementation packet + committed code/diff, canonical changed-file/focused reports, independent temporary-repository attacker fixtures, observed refs/dirty checks before and after, and output captured from the offline emergency path.
- Correction threshold: Only confirmed wrong eligibility/ownership/accepted outcome, mutated protected bytes, nondeterminism, missing required evidence or unsafe auto-action warrants cycle-1 correction plus fresh re-review. Nonblocking UX/scope ideas are next-slice and should not grow the bootstrap.
- Focused validation: Reproduce `python3 -m unittest custodian.tools.agent.test_pipeline_recovery custodian.tools.agent.test_queue_frontier custodian.tools.agent.test_dispatch custodian.tools.agent.test_review_outcome -v` plus targeted authoring/AI-context/changed-file gates. Record exact baselines and selected tests.
- Review focus: Adversarial review of claim-only orphan ref, orphan/foreign host, stale/offline main, read-only permission denial, injected `passed` prose with authentic `findings` review outcome, duplicate incident roots, corrupted JSON, unknown worktree bytes, missing deterministic input, network outage, bootstrap process crash, stale index, common mutex ownership, and thread-independent producer/reviewer provenance. Verify no genuine mutation authority was added.
- Acceptance: Produce an independent findings-first `passed`, `findings`, or `human_required` outcome tied to exact main/implementation SHAs and immutable report. Do not call R0 accepted on archived status alone. When failed, author bounded correction and re-review packets; never directly fix the reviewed implementation.
- Non-goals: Do not implement OR1/OR2 or W2, start a second scheduler, change reviewed code, approve human art, release any original claim, or run host cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Do not claim while this is draft/manual: the matching implementation and independent review first require the existing automated authoring preflight and explicit main publication. This is a temporary authoring gate, not permission to weaken reviewer independence or claim evidence.

Start only after normal dispatcher eligibility proves the implementation archived complete on current main. Use a fresh review worktree/context and original evidence; run focused and adversarial fixtures, record all findings with stable cycle IDs and the genuine durable `custodian.review_outcome.v1`. No self-review or source mutation. Mark acceptance only on a verified independent PASS and zero material gaps; otherwise keep original owners and cases protected.
