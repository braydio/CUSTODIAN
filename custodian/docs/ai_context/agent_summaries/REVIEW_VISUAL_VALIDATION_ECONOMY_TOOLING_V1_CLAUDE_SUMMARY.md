# Review Summary: Visual Validation Economy Tooling V1

Reviewed `origin/main` at `dfaf9e269d4c12d98bc03f5800cc34ce3530a50a` in code, architecture, and workflow modes. The implementation provides useful generic presentation probes, cross-record assertions, a standalone image-metrics module, compact ROI reporting, and one live Awakening seam adopter. The review found four correctness defects and two material acceptance-evidence gaps; none require a subjective art decision.

## Findings

- **R0-01 — Invalid ROI geometry fabricates measurements.** Pillow pads crops outside the source image. A 20×10 fully opaque test image cropped at `[15, 0, 10, 10]` yielded a 10×10 output with 0.5 coverage. Invalid ROIs need rejection.
- **R0-02 — A one-pixel boundary seam is invisible to the seam metric.** A red line exactly at vertical boundary x=10 in an otherwise black 20×10 image returned `mean_absolute_delta: 0.0` with band 2. The implementation compares only pixels two positions on either side of the boundary.
- **R0-03 — Dual alpha bounds only enforce the maximum.** An all-transparent image with minimum coverage 0.5 and maximum 1.0 returned pass because the max branch returns before the minimum is checked.
- **R0-04 — The Awakening evidence command reports success after metric failure.** The adapter writes `analyze()` output but never inspects `passed: false` results. A failed void/matte check therefore does not fail the command.
- **R0-05 — Four direct-adopter fallback specs are not tested reusable artifacts.** The catalog has 26 valid scenarios and one new direct adopter. The implementation summary's Twin Crown, Solarium I, Operator mobile guard, and Vaultwing snippets use unresolved placeholders and are not covered by a reusable spec/fixture check.
- **R0-06 — Live Awakening adopter outputs are not available to paired review.** The implementation summary reports successful no-capture and evidence-mode runs, but the structured result, metrics, and ROI sheet were not present in the checkout or tracked files. A fresh run in this worktree could not establish proof because of missing imports/class registration.

The durable findings and evidence are recorded in the archived implementation packet's `Independent Review` section. A bounded correction packet and paired re-review packet are ready and depend on this review landing.

## Validation and Limits

- `python3 -m unittest custodian.tools.iteration.test_build_moment_report custodian.tools.iteration.test_presentation_image_metrics` — 18 tests passed.
- Moment Forge schema, report, and changed-router Python smoke scripts all passed.
- `run_moment.py --list --json` returned 26 entries, all `schema_valid: true`.
- Synthetic probes reproduced the ROI, seam, and dual-threshold defects. Existing synthetic tests do not cover those cases or the evidence adapter's exit status.
- `moment_assertion_dsl_smoke.gd` printed PASS and exited 0, but Godot also emitted widespread missing-import, autoload, and parse errors from the unimported isolated worktree. The run is not considered a clean runtime pass. No direct-adopter `capture-mode none` run or evidence-mode artifact was claimed.
- No reviewed implementation/runtime files were changed. Metrics are read-only presentation evidence and I found no route, collision, or gameplay authority leakage, no aesthetic scoring, and no automatic subjective approval.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: The isolated worktree's missing generated imports/class cache made the Godot smoke emit broad load failures while still exiting 0; runtime adopter validation could not be trusted.
- Root cause / contributing factors: The worktree has no complete `.godot` import/class cache, and the local project root already has an editor running. The validation script's process status alone does not capture engine log failures.
- Prevention / pipeline improvement: Run targeted runtime checks from a fully imported worktree and make the wrapper reject engine load/parse errors even when the script itself exits 0.
- Tooling / docs drift discovered: Four adopter snippets in the implementation summary do not meet the packet's tested reusable fixture/spec fallback.
- Follow-up: visual-validation-economy-tooling-v1-review-corrections-1
- What worked: Python synthetic/schema checks isolated metric behavior without recapturing full-screen evidence.
