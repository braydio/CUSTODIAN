# Dispatcher Lock Scope and Fail-Fast Contention Hardening

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9

## What changed

- Centralized the shared dispatch lock path and changed its default acquisition to nonblocking. Optional waits are bounded by `--lock-wait-seconds`; busy results say `LOCAL DISPATCH BUSY`, include the absolute path, and prohibit lock-file deletion or killing the holder.
- Kept packet selection, remote claim CAS, per-workstream serialization, canonical `agent/<id>` publication, post-start verification, remote temporary-claim cleanup, and `last-claim.json` under the shared assignment mutex.
- Dispatcher-owned `workstream.start()` now records its completion locally without publishing diagnostics. The dispatcher releases the shared mutex, prints its authoritative `CLAIMED` receipt, then publishes diagnostics best-effort.
- Added a 15-second timeout to diagnostic `ls-remote`, fetch, and push operations. A failed or timed-out publish records local failure and does not change claim status. Direct workstream starts retain default trace publication behavior.
- Clarified the difference between local dispatcher contention, packet `Locks:` conflicts, and interrupted remote recovery claims in lifecycle and packet documentation.

## Evidence

- Focused suites: workflow control 11 passed; workstream 32 passed; dispatcher 72 passed.
- Existing workflow suite: 57 passed across landing, workstream, artifact-finalization, and branch-hygiene tests.
- Agent workflow smoke passed; review pairing passed for 28 automatic review packets.
- Changed-file validation passed 8/8 with no failures, timeouts, skips, or infrastructure errors. Import preflight passed with no checked-out LFS pointers.
- `git diff --check` passed.
- Lock tests hold the actual lock inode from a separate process, verify default fail-fast and a bounded CLI wait, confirm the lock file remains, confirm `status` works during contention, and prove busy claims create no branch, remote claim, worktree, or receipt.
- The delayed-diagnostic regression holds task A in `RunTrace.publish()` after its receipt exists and proves task B claims successfully before A's diagnostic is released. Forced diagnostic failure still emits a verified `CLAIMED` receipt and leaves the canonical branch while releasing the temporary claim.
- Concurrency tests use temporary repositories and bare remotes; no test diagnostic or claim refs were written to the live CUSTODIAN remote.

## Friction and deferred work

The first changed-file validation run timed out in the unrelated `world_placement_context` Godot test because this fresh worktree had no generated global-script-class cache. `godot_import_preflight.py` passed; after a single headless editor initialization populated the ignored cache, the changed-file validation passed 8/8. The isolated workstream branch push also waited on SSH briefly during setup, then completed. No implementation validation remains blocked.

Daemon/scheduler changes, lock TTLs, automatic lock-file removal, stale-claim deletion, automatic process termination, and distributed leases remain out of scope.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: first changed-file validation timed out before the fresh worktree's generated Godot class cache was initialized
- Root cause / contributing factors: the ephemeral checkout had no ignored `.godot` class cache; the first Godot check began before editor initialization
- Prevention / pipeline improvement: initialize the Godot editor cache after import preflight when changed-file validation selects Godot-owned checks in a fresh worktree
- Tooling / docs drift discovered: none; the user brief supplied a complete implementation and validation contract, and the lifecycle supports direct starts for unpacketed work
- Follow-up: none
- What worked: process-level lock tests and temporary bare remotes reproduced both contention cases without touching live task refs

## Next Handoff

- Next workstream: awakening-room-connectors-polish
- Next packet state: human-required
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9
- Refresh reason: none
- Next action: retry the explicit Awakening claim after `awakening-04-05-connector-transition-regression` releases the shared `awakening-04-05-connector-presentation` packet lock
- Blockers or open questions: the transition-regression workstream remains claimed and currently holds the Awakening packet's logical lock
