# INDEPENDENT REVIEW — Persistent Administrator original review source-scope recovery

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-persistent-task-administrator-review-scope-recovery-v1
- Category: agent-ops
- Kind: review
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P0
- Depends on: agent-persistent-task-administrator-review-scope-recovery-v1
- Locks: agent-persistent-task-administrator-scope-recovery
- Review: none
- Review target workstream: agent-persistent-task-administrator-review-scope-recovery-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_PERSISTENT_TASK_ADMINISTRATOR_REVIEW_SCOPE_RECOVERY_V1.md
- Reviewed main: 1ea8acc6a95866c04c4cfd3957e897a1d831a0dc
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently falsify the EXACT one-path historical source-scope exception before allowing the already-claimed original administrator implementation review to resume.
- Reviewed implementation acceptance: Independently reproduce both preapproval rejection and postapproval admission using immutable original administrator history and the proper accepted correction receipt. Verify the newly fetched coordinator approval-main never changes the original reviewed-main identity, reviewed code tree, canonical changed-file selection or source hashes.
- Review evidence: Existing original review pinned SHA `1ea8acc6a95866c04c4cfd3957e897a1d831a0dc`, original archived packet blob `3387dd7346b12aa41ea4fd496f0b162d245cc8a9`, omitted service path mode `100644` and blob `326e0b074d0b84dbfe35cde7714de852dbbb91af`, correction implementation commit and its tests, actual accepted-review contract. The original prelaunch claim and evidence remain preserved on host.
- Correction threshold: Any second path admitted, self-authorizing JSON, unpinned approval, mutable baseline, incorrect planner/apply digest, weak review receipt, bypassed test coverage, original claim mutation, or synthetic original PASS is blocking. Record stable `R0-NN` findings.
- Focused validation: Test exact historic archive source inventory, wrong packet/blob/mode/tree, extra code paths, altered attestation, missing independent PASS, forged/changed correction review/receipt, stale approval-main, root divergence, already-running reviewer, moved original claim, and direct final verification after successful host validation. Run focused unit suite and canonical changed-file validation with nonzero coverage. If host-private run unavailable, report that gap, do not issue PASS on unverified host behavior.
- Review focus: One source-scope correction only. Confirm newer `origin/main` is **approval evidence**, never an alternate implementation/test source or authorization for a new review claim. Ensure no unrelated previous exception behavior changes.
- Acceptance: Genuine fresh independent review with zero blocking defects and gaps; canonical findings/PASS and target receipt through existing review lifecycle. Does not grant original administrator review PASS or permit autonomous delegation.
- Non-goals: Do not mutate the original administrator review claim, archived packet, private host run, root dirty files, unrelated historical attestation cases, runtime, or B/C executable authority.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Read root and local AGENTS.md, the two correction packets and source tools from a fresh context. Verify the original historic Git identity independently. Falsify the implementation, especially planner/applier/post-review consistency and review-approval check. Do not infer acceptance from successful validation or a valid JSON file.

## Handoff

- Next workstream: review-agent-persistent-task-administrator-v1
- Next packet state: already-claimed host_validation_recovery (never re-claim)
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Refresh reason: none
- Next action: On independently accepted correction, use the exact original host-private run ID to call `paired_review_runner.py review-agent-persistent-task-administrator-v1 --continue-run <original-id> --recover-host-validation --plan` from a clean detached `origin/main` coordinator. Only after a fresh plan permits it, apply with its SHA and `--authorize-fresh-reviewer-context`.
- Blockers or open questions: The original implementation is still unreviewed. A valid correction PASS does not close that review or enable Phase B/C.
