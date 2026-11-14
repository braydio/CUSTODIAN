# Visual Validation Economy Tooling V1 Review Corrections 1

Implemented and archived workstream `visual-validation-economy-tooling-v1-review-corrections-1` addressing findings R0-01 through R0-06.

## Changes and evidence

- Pixel metric ROIs now reject negative/out-of-bounds coordinates and non-positive dimensions. `alpha_bounds` applies minimum and maximum coverage thresholds conjunctively. Seam checks inspect adjacent pixel pairs in the declared band and detect one-pixel discontinuities on the boundary; positive and negative controls cover horizontal and vertical seams.
- The Awakening evidence adapter now returns nonzero and reports failed metric indices. Tests exercise failed and passing metrics, output sheet/manifest creation, and exit status.
- Added four reusable, schema/DSL-checked adopter templates for Twin Crown, Solarium I, Operator mobile guard, and Vaultwing bonding closure. Added validation manifest ownership and dedicated focused entries for the new spec and adapter tests.
- Updated Moment Forge design/usage docs, validation recipes, file index, and packet index. Completed packet is archived at `custodian/docs/ai_context/task_packets/archived/VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1.md`.
- Awakening `traversal/awakening_late_seams_v1` no-capture and evidence runs both passed. Both reported stable fingerprint `be8bd7cf283947d0f7b7c4f868c1dcd721551c9004c4e58323fe237efabee3e6`, 26 probe samples, zero warnings, and 395 completion ticks. Evidence-mode adapter passed all 5 ROI checks and produced a 1200×444 contact sheet. The compact sheet, metrics JSON, and detailed run receipt are retained under `reports/moment_forge/curated/awakening_late_seams_v1_review_correction_1/`; receipt includes exact reproduction commands. Full run directories are ephemeral worktree artifacts.

## Validation

- Focused Python suites: 27 tests passed (metrics, report builder, adopter-spec contract, adapter failure/pass behavior).
- Moment Forge schema, report, and changed-router smoke checks passed.
- Final `python3 custodian/tools/validation/run_validation.py --changed --json`: passed, complete coverage, 10 selected checks, 0 failures.
- `git diff --check` passed.
- Healthy import: used local cached LFS objects only, then one headless editor import in the isolated worktree; import completed successfully. No LFS fetch/pull was used.

## Negative controls, deferrals, and friction

- Synthetic transparent and over-opaque alpha inputs fail a bounded alpha interval; a mid-coverage input passes. One-pixel horizontal/vertical seams are detected, and the existing clean uniform seam remains at zero delta. Invalid ROI origins/edges/dimensions raise `MetricsError`.
- Four adopter specs remain templates pending their feature-owned runtime consumers. They bind to read-only snapshots/production roles downstream; they do not implement those features or make aesthetic judgments.
- The first changed-file sweep found the new test/spec files lacked validation-manifest ownership. I added dedicated entries and reran to complete coverage. The initial focused sweep also caught that a live evidence receipt placed in the spec directory was interpreted as a spec; I moved it to curated evidence.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: New spec/test files were initially uncovered by changed-file validation; the receipt was briefly placed in the directory scanned for scenario-spec JSON.
- Root cause / contributing factors: Validation ownership had not been registered, and the spec directory treats every JSON file as a candidate template.
- Prevention / pipeline improvement: Added explicit manifest ownership and dedicated test entries; placed runtime proof with curated report evidence.
- Tooling / docs drift discovered: Changed-file validation coverage for the new adopter/spec tests was missing; fixed in-scope.
- Follow-up: fixed-in-scope
- What worked: Cached local LFS checkout, one editor import, deterministic live runs, and concise curated evidence kept the proof reproducible without retaining full-frame artifacts.
