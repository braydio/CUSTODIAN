# Operator Baseline Validation Rehabilitation Packet Publication

Published a bounded implementation/review contract for the three reproduced Operator validation failures. The implementation is separated from the existing stealth-perception branch and from the active mobile-guard implementation. It will not be claimable until `operator-mobile-guard-composition` archives complete and the shared `operator-runtime` lock is free.

The implementation packet requires the claimed worktree to hydrate the 15 reported LFS pointers, rerun the Godot import preflight, and import only after preflight passes. It then requires live traces for the parry counter and attack-drive carry, plus dependency injection of the Vigil camera probe before Operator `_ready()`. Fixture repair is preferred when runtime contracts are correct; gameplay changes require a demonstrated source-level defect. Each test keeps its protected assertion and adds a meaningful precondition/negative control.

## Validation

- Draft/manual targeted authoring preflight: passed.
- Promoted ready/auto targeted authoring preflight: passed.
- `task_packet_index.py --write` and check: passed.
- `check_ai_context.py --json`: passed with zero findings.
- `validate_review_pairing.py`: passed.
- `run_validation.py --test review_pairing_contract --json`: passed, 1/1.
- `git diff --check`: passed.
- Godot import was not run: current-main LFS preflight identified 15 unrelated Awakening image pointers. The implementation packet requires hydration and a passing preflight in its isolated worktree before import.

## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Current-main import is blocked by missing LFS materialization for unrelated Awakening images.
- Root cause / contributing factors: The latest fetched main contains LFS pointers in its working tree; the authored implementation does not need Godot import, but its execution does.
- Prevention / pipeline improvement: Make hydration and preflight an explicit first step in the claimed implementation worktree, preserving root and other worktrees.
- Tooling / docs drift discovered: No existing packet represented these three baseline regressions; a new paired contract was needed.
- Follow-up: `operator-baseline-validation-rehabilitation`
- What worked: The dispatcher dependency and runtime lock prevent overlap with active mobile-guard work.

## Next Handoff
- Next workstream: operator-baseline-validation-rehabilitation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Claim only after `operator-mobile-guard-composition` archives complete and dispatcher reports the new packet eligible; then hydrate, preflight, import, reproduce, and repair the three checks.
- Blockers or open questions: Current LFS preflight lists 15 unrelated Awakening pointers; the mobile-guard implementation is an explicit dependency and currently holds `operator-runtime`.
