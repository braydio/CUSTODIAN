# CUSTODIAN Empty Convoy Integrated Security Correction

- Workstream: `campaign-empty-convoy-security-integrated-correction-v1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_EMPTY_CONVOY_SECURITY_INTEGRATED_CORRECTION_V1.md`
- Run ID: `20261102T121855Z-aee246deb60e`
- Source commit/tree: `c7bc91207a7b582b657c63785515f0aac19496e9` / `4a5797e7509bc0d9832b5614a44832dfc7ca49ad`
- Original QA finding: On production contract seed `2` (generated map seed `3570245418`, convoy tile `(115,98)`), scanning produced no visible defenders and immediately offered the custody trace. The exact production trigger remains unknown. Source review confirmed unsafe transitions could treat temporary spawn/observation failure as empty defense.
- Correction: Capacity, unavailable services, walkability failures and queue rejection now remain deferred/retryable or unresolved. Each successful defender slot is tracked by identity; missing active actors on reentry do not count as defeats. The trace is gated on verified defeats or authoritative defender absence. Bounded DevObservatory events record prior/current state, reason, seed, counts, capacity, candidates and queue results.
- Security smoke: Passed. Real generated seed-2 map used its actual walkability provider, inserted the convoy at `(115,98)`, and accepted three actual registered defenders. Focused cases cover capacity recovery, unsafe positions, partial queue rejection/retry, missing actors on reentry and authoritative empty defense.
- Recovery smoke: Passed; custody trace, exactly-once salvage, safe-empty evidence, reentry and ledger fallback.
- Placement smoke: Passed for four seeds, three placements.
- Changed-file validation: Passed `4/4`, complete coverage, no failures/skips/timeouts/infrastructure errors. Source-bound report SHA-256: `4adaac526829167ae300569f2e7af9e82bdee03106028c6924b26db819abf1db`. Validated source commit/tree: `c7bc91207a7b582b657c63785515f0aac19496e9` / `4a5797e7509bc0d9832b5614a44832dfc7ca49ad`.
- Shutdown warning classification: The original baseline security smoke had no shutdown leak warning. Running the correction smoke harness against baseline runtime reproduced the same `71 ObjectDB` and `2 resource` warnings as the corrected runtime, attributing them to the generated-map smoke fixture teardown rather than the runtime correction. The canonical runner classifies these as known, nonfatal warnings.
- Landing: Canonical finish landed the implementation at `c7bc91207a7b582b657c63785515f0aac19496e9` and the archive closeout at `09e15e239da24757a9587b61314b4f62e08eba0e`. Both were verified as ancestors of `origin/main` at `4900dbee03f3a9992391c5f985d1c35d819dc7ae` before this documentation-only update. The persistent root checkout was left untouched because it is dirty and behind.
- Post-land QA: The one authorized seed-2 GUI reached `QA_CONVOY_APPROACH_READY` at map seed `3570245418`, convoy `(115,98)`, approach `(115,94)`, and interaction destination `(115,96)`. The user completed the manual review and signed off with “No dice; possible scenario/encounter mismatch.” Human review is complete; integrated gameplay acceptance is `NOT_ACCEPTED`, and the exact failure cause remains unconfirmed. There is no confirmed successful defender encounter, custody trace, or exactly-once salvage. Codex sent no gameplay input. The separate Forlorn Ritualant Threadway finding remains separate. No paired review was launched or accepted; its disposition remains deferred.
- QA evidence and teardown: The detached QA checkout was retired through ordinary non-forced `git worktree remove` after the exact temporary autoload line and four QA files were preserved and removed through scoped cleanup. All 20,057 ignored entries were inventoried; only regenerable Godot caches, `.import` metadata, and Python bytecode were absent/different from the root. The compact host-local evidence archive is `/home/braydenchaffee/.local/share/custodian/evidence/empty-convoy-postland-closeout-2026-11-02/evidence.tar.gz` (SHA-256 `81d2970f1862667d9ae376d7859f71ac280988a39ed73235b781916d06c455b1`); ignored inventory SHA-256 `5deecd15ec66e25602c1e3db6a703d7f40f69c7102eda1166e8fb28994895e9d`. Disk free space rose from `26415376` to `33674740` KiB (measured gain `7259364` KiB, about 6.92 GiB); attached worktrees fell from 108 to 107. No claim or review lock was released.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The isolated worktree lacked generated Godot import state; an editor import aborted with an allocator diagnostic, so its ignored .godot cache was copied from the exact-baseline QA checkout. The post-commit changed-file command initially selected zero files because it compared only the clean worktree; rerunning with --base origin/main selected the committed source paths.`
- Root cause / contributing factors: `Generated import caches are checkout-local, and committed branch changes require an explicit origin/main comparison for changed-file selection.`
- Prevention / pipeline improvement: `Reuse an exact-source generated Godot cache when available, and pass --base origin/main when validating a clean committed workstream branch.`
- Tooling / docs drift discovered: `none`
- Follow-up: `Manual gameplay acceptance is not accepted and its exact failure cause is unconfirmed; correction review disposition awaits separate coordinator control.`

## Next Handoff

- Next workstream: `none authorized`
- Next packet state: `awaiting separate coordinator control for correction review disposition`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
