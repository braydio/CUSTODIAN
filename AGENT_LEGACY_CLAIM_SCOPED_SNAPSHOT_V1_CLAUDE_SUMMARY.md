# Scoped legacy claim snapshot implementation

Implemented `--scope workstream` in the existing legacy quarantine authority. The new V1 scoped manifest pins `origin/main` and only the exact target claim, agent, and diagnostic refs; it archives the target worktree, review evidence, and workflow traces. It inventories LFS pointers across the selected ancestry, verifies object OID and size, stores only required LFS bytes, and records materialized bytes already covered by the worktree archive without making a duplicate copy. A preflight estimates the selected bundle and all payload bytes and requires a 1 GiB free-space reserve before creating the destination. The scoped verifier checks file digests, bundle heads, safely extracts each archive to a temporary directory, and compares exact path, mode, content, and symlink inventories. Historical V1 verification and the quarantine planner/apply code remain intact.

The focused temporary-repository suite passed **14/14** tests, including the existing quarantine identity/CAS/V1 cases, ignored and untracked payloads and symlinks, target-specific LFS and materialized-byte deduplication, missing LFS refusal, multi-target rejection, storage preflight with no destination creation, and tamper rejection. `py_compile`, `git diff --check`, targeted packet-authoring validation, and `task_packet_index.py` also passed.

The live no-op preservation snapshot was not attempted against the persistent destination: its exact worktree inventory totals 5,739,169,332 bytes while the destination filesystem had 5,071,508,000 bytes free. A zstd probe compressed the 5.39 GiB tar stream to 5.13 GiB, still larger than free space and before the required reserve, so the scoped tool must refuse before writing. No protected no-op worktree, branch, claim, continuation, evidence, or source-validator lock was modified by this implementation. No live quarantine was applied and no review outcome was created.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: persistent storage could not hold the exact protected worktree archive plus the required reserve.
- Root cause / contributing factors: unrelated shared LFS copying was a systemic defect, and the protected worktree itself is larger than currently available persistent storage.
- Prevention / pipeline improvement: implemented scoped OID preservation, materialized-byte deduplication, conservative storage preflight, and isolated restore verification.
- Tooling / docs drift discovered: lifecycle guidance described only the unscoped V1 behavior; added scoped-mode guidance.
- Follow-up: fixed-in-scope
- What worked: target-specific temporary fixtures establish restore behavior and fail-closed cases without touching protected evidence.

## Next Handoff
- Next workstream: review-agent-legacy-claim-scoped-snapshot-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: finish and land this implementation, then run its fresh-context paired review; afterward resume the exact no-op coordinator-closeout and preservation gates.
- Blockers or open questions: persistent backup destination has insufficient free space for the live no-op worktree and reserve; do not quarantine until a verified independent snapshot is available.
