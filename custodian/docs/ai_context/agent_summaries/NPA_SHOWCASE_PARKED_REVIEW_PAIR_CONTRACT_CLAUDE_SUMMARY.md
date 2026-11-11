# Parked Review-Pair Contract Correction

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

The shared pairing contract now accepts an intentionally parked implementation/review pair only when both packets are `draft/manual`. Such packets remain non-claimable through the existing dispatcher status and eligibility rules. Ready implementations still require a `ready/auto` paired review; blocked implementations reject draft reviewers and require the existing ready/auto or blocked/manual states.

The proposed script's exact docstring anchor had drifted in `task_packet_contract.py`; its fail-closed check correctly made no edits. I reviewed the live validator and applied the same bounded correction at its current text. The patch changes only the shared contract and its direct unit tests. No queue packets, runtime files, or other worktrees were modified.

## Validation

- `python3 custodian/tools/agent/test_task_packet_contract.py`: 27 passed.
- `python3 custodian/tools/agent/test_dispatch.py`: 80 passed.
- `python3 custodian/tools/agent/validate_review_pairing.py`: PASS, 61 `Review: auto` packets paired.
- `python3 custodian/tools/agent/check_ai_context.py --json`: PASS, zero findings.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: 6 selected, 6 passed, 0 failed.
- `git diff --check`: PASS.
- Runtime/gameplay validation: not applicable; tooling-only change.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: supplied correction's exact docstring anchor was stale; its guard prevented unsafe partial edits.
- Root cause / contributing factors: live contract wording changed after the candidate script was prepared.
- Prevention / pipeline improvement: keep patch scripts fail-closed; reconcile stale anchors against the live source before adapting a correction.
- Tooling / docs drift discovered: none beyond the stale proposed patch anchor.
- Follow-up: fixed-in-scope
- What worked: shared validator is used by both dispatcher and global AI-context/pairing checks.

## Next Handoff
- Next workstream: npa-7-commanded-ally-contracts-planning
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: resume the existing NPA-7 publication recovery branch, sync it safely with origin/main, rerun its post-sync gates, and finish publication without claiming or implementing NPA-7.
- Blockers or open questions: none; publication remains gated on successful post-sync validation.
