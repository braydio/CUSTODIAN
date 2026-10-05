# Operator canvas smoke source independence

Fast 02 transaction 20261005T123558 rolled back cleanly after mandatory validation
failed. The saved six-frame 128x128 document and pending resize were retained.
The production smoke assumed its Fast 02 source was always 96x96, even though
mandatory validation runs after the source swap to the resized sheets.

The smoke now expands the actual source canvas by 32 pixels per axis, derives
strip dimensions, filename size token and per-binding centered offsets, and
compares every source frame's RGBA bytes. Contract assertions remain active.

Validation: full smoke passes against 96x96 sources. An isolated source-only
128x128 reproduction fails with the original test at its fixed 96x96 assertion;
the corrected full smoke passes against all six 128x128 sheets. Temporary source
fixtures were restored; git diff --check passes. Evidence logs are under /tmp
operator-canvas-original-128.log, operator-canvas-fixed-128.log and
operator-canvas-final-smoke.log.

Moment Forge: not run — authoring validation only.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: mandatory smoke rejected legitimate canvas migration
- Root cause / contributing factors: live production source used as a fixed 96x96 fixture
- Prevention / pipeline improvement: derive integration dimensions from current contracts, retain exact RGBA assertions
- Tooling / docs drift discovered: integration test documented fixed dimensions after mutable-source migrations
- Follow-up: fixed-in-scope
