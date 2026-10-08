# CORRECTION: PERSISTENT CHECKOUT SYNC HARDENING REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `persistent-checkout-sync-hardening-review-corrections-1`
- Kind: `correction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-persistent-checkout-sync-hardening`
- Locks: `agent-workflow, operator-workbench-publish`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-persistent-checkout-sync-hardening-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Parent implementation: `persistent-checkout-sync-hardening` — `custodian/docs/ai_context/task_packets/archived/PERSISTENT_CHECKOUT_SYNC_HARDENING.md`
- Parent review: `review-persistent-checkout-sync-hardening` — `custodian/docs/ai_context/task_packets/archived/REVIEW_PERSISTENT_CHECKOUT_SYNC_HARDENING.md`
- Findings addressed: `R0-01`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Goal: Remove the full ignored-tree hashing bottleneck from persistent checkout status and synchronization while retaining fail-closed protection against ignored local bytes being overwritten by incoming tracked paths.
- Completion boundary: Ordinary coordination-root status, apply, and OPUI startup must not read/hash all ignored files. Collision checks and post-sync ignored-byte proofs must be bounded to incoming candidate paths, and existing synchronization safety behavior must remain intact.
- Work surface: `custodian/tools/agent/persistent_checkout_sync.py`, `custodian/tools/validation/persistent_checkout_sync_smoke.py`, and only directly necessary validation registration/docs.
- Change: Replace `_ignored_manifest()` use over the entire checkout with candidate-path-scoped filesystem inspection for possible incoming collisions and ignored-byte preservation. Add a realistic fixture with a large ignored tree and assert status/sync do not enumerate or hash unrelated ignored files. Keep exact byte hashing for targeted collision candidates or fixture before/after evidence as appropriate.
- Preserve: FF-only mutation, lock and revalidation behavior, root/art identity gates, sparse profile, no-LFS-network rule, `LAND PENDING`/recovery/Aseprite protections, exact ignored Workbench byte preservation, and all existing clean/dirty/ahead/diverged behavior.
- Non-goals: Do not alter Git policy, root/art checkout lifecycle, publication behavior, UI layout, or unrelated sync latency.
- Acceptance:
  1. A root fixture with many unrelated ignored files returns status and completes safe sync without reading/hashing the ignored tree.
  2. Incoming tracked paths colliding with ignored files/directories still block before mutation, preserving file bytes and HEAD.
  3. Existing targeted ignored `.ai/operator_animation_workbench` byte-preservation fixture remains green.
  4. Current sync, Operator-art, workstream (38 tests), and OPUI focused validation remains green.
  5. A live root status probe completes promptly without hashing all 134,037 ignored entries.
- Validation: Run `persistent_checkout_sync_smoke.py`, `operator_art_worktree_smoke.py`, `test_workstream.py`, `operator_workbench_ui_smoke.py`, `bash -n tools/custodian_aliases.sh`, and the focused changed-file validation recipe. Record timing and ignored-entry counts from the large-tree fixture; do not run another unbounded hash scan against the persistent project root.
- Task overrides: `none`
- Deferred: none.

## Handoff

- Next action: Run paired fresh-context review `review-persistent-checkout-sync-hardening-review-corrections-1` after this correction lands.
- Blockers or open questions: none.
