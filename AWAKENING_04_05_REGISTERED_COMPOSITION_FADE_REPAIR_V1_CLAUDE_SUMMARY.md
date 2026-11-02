# Awakening 04→05 Registered Composition Fade Repair V1 — Closing Summary

## Result

Repaired the live 04→05 fade ownership while preserving the approved registered composition. `RegisteredComposition04_05` remains an immutable visible registration parent at `(349,-2585)`, scale 1, rotation 0. Its 1502×2048 Dust→Connector→Locker children now own independent fade behavior: Locker follows Zone04, Dust follows Zone05 (and the lower→upper passage hold), and Connector follows the merged A/B/C envelope. Hidden legacy Zone04/Zone05 underlays are no longer the presentation or coverage authorities.

The P-9 regression checks the live Locker child through closed, authorization/opening, open_loaded, and empty states. Traversal coverage samples only visible registered pixels and validates forward/reverse presentation equivalence. The existing late-seam Moment Forge scenario now includes the two room interiors, A/B/C, and reverse checkpoints, with a compact five-ROI contact sheet and deterministic alpha checks.

No approved art bytes, transforms, order, Layout geometry, collision, progression, camera, lighting, or gameplay behavior were changed.

## Validation and evidence

- Final `run_validation.py --changed --json`: 14 selected, 14 passed, 0 failed/timeouts, complete changed-file coverage. Report used for lifecycle finish: `/tmp/awakening-fade-repair-validation.json`.
- Focused Awakening scene and P-9 progression checks passed.
- Registered composition traversal passed 1,025 samples; lower→upper traversal coverage also passed.
- Connector asset contract passed with 1502×2048 canvas, unchanged registered source hashes/order/overlap metrics.
- Compact renderer smoke passed; at-exit Godot ObjectDB/resource leak warnings were non-fatal.
- Moment Forge late-seam run passed all 68 assertions. Evidence run: `reports/moment_forge/traversal/awakening_late_seams_v1/20261009T094930-0400`. ROI metrics passed all five matte/void checks; contact sheet: `reports/moment_forge/traversal/awakening_late_seams_v1/20261009T094930-0400/awakening_late_seams_roi_sheet.png`.
- Paired review visual evidence manifest: `/CUSTODIAN/visual_review/awakening-04-05-registered-composition-fade-repair-v1/20261009T135021Z/REVIEW_MANIFEST.json`.
- `git diff --check` passed.

The first Moment Forge attempts failed on a missing fixture command registration, the required sixth contact-sheet tick, and stale forward/reverse comparisons. Those fixture/scenario issues were corrected before the final run. Fresh-worktree Godot import generated unrelated `.import` sidecars; only those generated sidecars were removed. An initially modified validation manifest was redundant with current main and was dropped. No project-root asset was modified.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Initial Moment Forge setup missed the fixture command allow-list and exact contact-sheet tick contract; later checkpoint comparison metadata also needed correction.
- Root cause / contributing factors: Fixture command registration, scenario checkpoints, and evidence-adapter ticks were not validated as one unit before the first run.
- Prevention / pipeline improvement: Validate fixture allow-list, scenario timeline/assertions, evidence-adapter tick selection, and mandatory contact-sheet shape together before running the full capture.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Reusing the existing Moment Forge path kept the state proof deterministic and the visual review artifact compact.

## Next Handoff
- Next workstream: review-awakening-04-05-registered-composition-fade-repair-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired post-land review from a fresh reviewer context; inspect the supplied visual evidence and escalate only if it is materially ambiguous or contradicts the locked composition.
- Blockers or open questions: none.
