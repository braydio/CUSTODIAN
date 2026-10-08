# REVIEW: PERSISTENT CHECKOUT SYNC HARDENING REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-persistent-checkout-sync-hardening-review-corrections-1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `persistent-checkout-sync-hardening-review-corrections-1`
- Locks: `agent-workflow, operator-workbench-publish`
- Review: `none`
- Review target workstream: `persistent-checkout-sync-hardening-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PERSISTENT_CHECKOUT_SYNC_HARDENING_REVIEW_CORRECTIONS_1.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Goal: Independently verify that correction R0-01 removes ignored-tree-wide hashing from ordinary persistent checkout status/sync while preserving path-collision and ignored-byte safety.
- Review focus: bounded ignored-path inspection; collisions against incoming tracked files/directories; large ignored-tree scaling; no regressions in root/art safety gates, serialization, revalidation, OPUI startup, or existing finish delegation.
- Acceptance: Findings-first fresh-context review must prove prompt operation with a large ignored tree and preservation of a colliding ignored file. Any blocking defect creates cycle 2 correction/re-review; otherwise record a passed receipt.
- Non-goals: Do not patch the reviewed correction implementation in this review workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Independently inspect the new candidate-path logic and confirm ordinary status does not traverse/hash all ignored files.
2. Run the large ignored-tree performance fixture and record measured entry count and duration.
3. Prove colliding ignored file and directory cases block without moving HEAD or changing bytes.
4. Run the focused sync, Operator-art, workstream, and OPUI validations.
5. Confirm all prior dirty/ahead/diverged, pending/recovery/Aseprite, lock, race, shell-routing, and no-LFS safety remains.
6. Record stable cycle-scoped findings before deciding pass/follow-up.

## Handoff

- Next action: Claim after `persistent-checkout-sync-hardening-review-corrections-1` lands and archives.
- Blockers or open questions: dependency only.
