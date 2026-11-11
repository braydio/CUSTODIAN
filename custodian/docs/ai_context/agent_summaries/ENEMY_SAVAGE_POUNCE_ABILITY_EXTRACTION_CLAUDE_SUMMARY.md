# Enemy Savage Pounce Ability Extraction Summary

Implemented the NPA-2 pounce extraction. `SavagePounce` now owns launch eligibility, phase/timer/cooldown state, committed direction, travel, contact-window evaluation, one-hit bookkeeping, cancellation, and debug diagnostics. `SavagePounceConfig` and `savage_pounce_default.tres` own the original 13 tuning values. `enemy.gd` retains the `savage_pounce_enabled` feature switch, config binding, fixed-step priority, and shared host services. The existing Savage two-hit chain implementation and tuning remain actor-owned and unchanged.

The scene binds the focused config. Presentation, interruption, behavior range, and diagnostics query the ability. Focused validation now reads the typed ability/debug seam. Active architecture/context and ability ownership docs describe the extracted boundary and leave NPA-3 scoped to the chain.

## Validation

- `enemy_savage_pounce`: passed; covers config defaults, launch band, ordering, timing, contact window, damage/impact, directional miss, travel, cooldown, parry/block, interruption, and chain control.
- `savage_runtime`: passed; presentation priority reads the ability state.
- `run_validation.py --changed --json`: 25 selected, 25 passed, 0 failed, 0 timed out, 0 skipped, complete changed-file coverage. The final report covers implementation/code/test/config/manifest files with complete ownership; repository docs and `.uid` sidecars are explicitly excluded from test selection. `workstream.py finish` first rejected a noncanonical Completion Truth receipt; the packet now uses the enforced `custodian.task_completion.v1` fields.
- `git diff --check`: passed.

## Friction / Deferrals

The fresh worktree needed a one-time Godot editor import to populate generated class/resource caches. That import generated unrelated Operator `.import` sidecars, which were removed. The first pounce smoke fixture also assumed direct manual movement/time advancement and reused absolute coordinates; it was changed to run against physics frames with a `CharacterBody2D` mock target and per-case position resets. The Godot class `.uid` files for both new scripts are retained as standard script sidecars. No visual capture was needed because the packet's acceptance is state/timing/geometry based.

NPA-3 Savage two-hit-chain extraction remains intentionally deferred until this implementation receives paired review and the planning refresh gate is revisited.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Smoke setup initially violated physics callback assumptions and reused world positions; editor import created unrelated sidecars.
- Root cause / contributing factors: Migration changed the test from direct phase ticking to real `CharacterBody2D` movement, while the fixture retained assumptions from the pre-extraction smoke.
- Prevention / pipeline improvement: Keep movement ability tests on physics frames, use physics-body targets, and reset positions between cases; remove unrelated import sidecars after fresh editor imports.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Focused actor-local ability ownership used existing narrow Enemy services and retained pounce-before-chain ordering.

## Next Handoff
- Next workstream: review-enemy-savage-pounce-ability-extraction
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Claim and run the paired review from a fresh reviewer context.
- Blockers or open questions: none
