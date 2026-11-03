# Empty Convoy Post-Land QA Closeout

- Workstream: `campaign-empty-convoy-security-integrated-correction-v1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Control: `postland-qa-closeout-and-safe-teardown`
- Implementation: `c7bc91207a7b582b657c63785515f0aac19496e9`
- Landing/archive commit: `09e15e239da24757a9587b61314b4f62e08eba0e`
- `origin/main` verified before this doc-only publication: `4900dbee03f3a9992391c5f985d1c35d819dc7ae`

## Human outcome

- `HUMAN_REVIEW_RECEIVED=true`; `HUMAN_REVIEW_STATUS=COMPLETE`.
- `MANUAL_GAMEPLAY_ACCEPTANCE=NOT_ACCEPTED`.
- Player observation: “No dice; possible scenario/encounter mismatch”.
- `EXACT_FAILURE_CAUSE=UNCONFIRMED`.
- The Forlorn Ritualant Threadway report is a separate finding.
- The `QA_CONVOY_APPROACH_READY` receipt proves safe QA positioning only. It does not prove encounter correctness.
- No confirmed successful defender encounter, custody trace, or exactly-once salvage was recorded. Codex did not initiate a scan, combat, custody trace, or reward mutation.

## Technical QA receipt

- Contract seed `2`; generated map seed `3570245418`; active map path `/root/GameRoot/World/ProcGenRuntime/ProcGenMap`; map instance `650955992649`; loader identity `2:3570245418:650955992649`.
- Convoy event `campaign_empty_convoy_v1:0:3570245418` at `(115,98)`; approach `(115,94)`; interaction destination `(115,96)`; local route `(115,94) → (115,95) → (115,96)`.
- Operator reached `(115,94)` at world position `(3696,3024)`; camera and input were valid; GUI PID `3518798`.
- Targeted `startup_world_entry` and `campaign_empty_convoy_security` validations passed with exit `0` and `source_changed_during_validation=false`; QA parse check and `git diff --check` passed.
- GUI process PID `3518798` was absent at closeout. A host `/proc` scan found no process cwd or open file descriptor under the QA checkout.

## Evidence and teardown

- Host-local evidence archive: `/home/braydenchaffee/.local/share/custodian/evidence/empty-convoy-postland-closeout-2026-11-02/evidence.tar.gz`.
- Archive SHA-256: `81d2970f1862667d9ae376d7859f71ac280988a39ed73235b781916d06c455b1`; manifest SHA-256: `19676a7fe2a6bc56b70afff2845a2e234d51b2759f1d18267847901716cccd4d`.
- The archive contains both QA scripts and UIDs, the exact `project.godot` patch, the post-land and launcher logs, diagnostic log, validation JSON, final outcome, and the full ignored-file inventory. No `.godot` cache or screenshot binaries were included.
- Ignored inventory SHA-256: `5deecd15ec66e25602c1e3db6a703d7f40f69c7102eda1166e8fb28994895e9d`; 20,057 entries / 1,218,975,866 bytes. 19,944 files exactly matched the persistent root. The 47 absent and 66 differing entries were `.godot` cache. The other 16 were generated `.import` metadata or Python bytecode. No ignored Asset Pipeline V2 source master or archive was present.
- QA checkout `/home/braydenchaffee/Projects/.custodian-convoy-postland-09e15e2` was detached exactly at `09e15e239da24757a9587b61314b4f62e08eba0e`, with only the known QA autoload line and four QA source/UID files as local changes. The autoload was reversed with the archived exact patch; the four files were removed only after SHA verification against the evidence archive.
- After verifying the checkout was clean, had no active owner, and its baseline was reachable from `origin/main`, it was removed with ordinary non-forced `git worktree remove`.
- Disk free space measured `26415376` KiB before and `33674740` KiB after; observed delta `7259364` KiB (~6.92 GiB). Attached worktrees: 108 before, 107 after; created `0`, retired `1`.

## Ownership and remaining review

- The correction packet is archived and the implementation is already landed. The canonical `origin/agent/campaign-empty-convoy-security-integrated-correction-v1` branch and dispatch claim are absent.
- No claim, independent review, or lock was released by this closeout. Correction review disposition remains deferred.
- The persistent root checkout was not modified or synchronized: it was dirty with 49 status entries and 52 commits behind at the closeout audit.

