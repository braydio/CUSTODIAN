# Task Packet Queue Stranding Hardening — Review Corrections 1

- Workstream: `task-packet-queue-stranding-hardening-review-corrections-1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Result: corrected status classification for ready/manual packets so the MANUAL READY category now reflects actual explicit-claim eligibility.

## Changes

`dispatch.py::_render_status()` now calls the shared `_decision()` eligibility gate for ready/manual packets. Valid packets stay in MANUAL READY. Failed dependency or lock checks use DEPENDENCY/LOCK BLOCKED; pairing, validation-reference, and other eligibility failures use INVALID/RECOVERY with the same reason shown by explicit claim.

Added a dispatcher regression fixture covering a valid ready/manual packet, a ready/manual packet whose review pair is invalid, and a ready/manual packet with a missing validation script. Both invalid fixtures are excluded from MANUAL READY and rejected by explicit claim.

## Validation

- `python3 custodian/tools/agent/test_dispatch.py` — 76 passed.
- `python3 custodian/tools/agent/test_task_packet_contract.py` — 26 passed.
- `python3 custodian/tools/agent/test_task_packet_index.py` — 12 passed.
- `git diff --check` — passed.
- The dispatcher suite exercised status classification and explicit claims in temporary repositories, including the valid-manual control.

No other behavior was changed. The known legacy no-Dispatch display behavior remains out of scope for this bounded correction.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: none
- Root cause / contributing factors: status rendered manual dispatch directly instead of applying the already-shared explicit-claim eligibility decision.
- Prevention / pipeline improvement: use `_decision()` as the single eligibility gate when classifying both automatic-ready and explicit-manual packets.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: focused temporary-repository regressions proved both status and explicit-claim behavior.

## Next Handoff
- Next workstream: `review-task-packet-queue-stranding-hardening-review-corrections-1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: none
- Next action: claim the paired review from a fresh reviewer context and verify the correction against its review packet.
- Blockers or open questions: persistent project-root checkout synchronization is pending because the root checkout has unrelated dirty import sidecars; no root files were modified.
