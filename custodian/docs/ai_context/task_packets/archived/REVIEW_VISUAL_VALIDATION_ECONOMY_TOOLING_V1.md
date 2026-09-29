# REVIEW: VISUAL VALIDATION ECONOMY TOOLING V1

- Workstream: `review-visual-validation-economy-tooling-v1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `visual-validation-economy-tooling-v1`
- Locks: `moment-forge-tooling`
- Review: `none`
- Review target workstream: `visual-validation-economy-tooling-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_VALIDATION_ECONOMY_TOOLING_V1.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed visual-validation economy tooling reduces routine renderer/model-vision dependence without weakening deterministic presentation proof or subjective human gates.
- Review focus: generic probe compatibility; deterministic image metrics; cross-tick assertions; ROI/contact-sheet minimization; no simulation authority leakage; no hidden aesthetic scoring; direct-adopter usefulness for Awakening/Twin/Operator/Vaultwing; evidence reuse by paired review; preservation of existing Moment Forge scenarios and capture semantics.
- Acceptance: Findings-first review of live `main`. Prove existing scenarios remain compatible, metrics have deterministic synthetic positive/negative controls, direct-adopter no-capture runs expose the promised structured facts, and evidence mode produces compact ROI artifacts without requiring full-frame model inspection. Confirm subjective baseline/art-direction decisions remain human-owned. Blocking findings create the bounded correction pair; do not patch reviewed tooling inside this review workstream.
- Non-goals: Do not review the artistic quality of Awakening, Twin Solaria, Operator, or Vaultwing assets; do not generate new full visual baselines; do not expand into audio tooling or general CI redesign.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Run the focused Moment Forge schema/probe/assertion/report tests and synthetic presentation-image metrics fixtures.
2. Confirm old scenario JSON remains valid without adding new required fields.
3. Prove cross-record assertions can compare equivalent presentation state across ticks/directions.
4. Prove the image metrics distinguish clean and intentionally broken alpha/matte/seam/diff fixtures without subjective scoring.
5. Run available direct adopters in `capture-mode none`; inspect structured JSON, not screenshots, as the primary evidence.
6. Run one representative evidence-mode adopter and verify it emits compact ROI/contact-sheet output plus metrics while preserving access to raw frames as secondary human evidence.
7. Confirm no tool mutates gameplay/simulation state and no metric is treated as collision/navigation/route authority.
8. Confirm paired-review documentation tells reviewers to reuse durable structured evidence instead of recapturing equivalent full-screen media.
9. Confirm no baseline or aesthetic/art-direction result is auto-approved.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The scoped Godot run completed the assertion DSL smoke but emitted broad project-load failures because this worktree lacks generated imports and global class registration; direct-adopter none/evidence runs could not be treated as valid proof.
- Root cause / contributing factors: The isolated worktree does not carry the main checkout's `.godot` import/class cache; a live editor was also active in the project root. The engine smoke returned exit code 0 despite autoload/resource/script errors.
- Prevention / pipeline improvement: Run focused Moment Forge runtime checks from a fully imported worktree and make the validation wrapper fail when engine logs contain load/parse errors even if the script exits zero.
- Tooling / docs drift discovered: The implementation summary's four future-adopter snippets are copy/paste templates, not tested reusable fixture/spec artifacts as required by the parent packet.
- Follow-up: `visual-validation-economy-tooling-v1-review-corrections-1`
- What worked: Synthetic probes and Python schema/report smokes isolated deterministic metric behavior without renderer evidence.

## Independent Review

- Status: `findings`
- Review workstream: `review-visual-validation-economy-tooling-v1`
- Reviewed on main: `dfaf9e269d4c12d98bc03f5800cc34ce3530a50a`
- Review modes: `code, architecture, workflow`
- Blocking defects: `4`
- Material evidence gaps: `2`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01, R0-02, R0-03, R0-04, R0-05, R0-06`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `visual-validation-economy-tooling-v1-review-corrections-1`

### Findings

#### R0-01 — ROI bounds are silently padded

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Image metrics must accept named ROIs and emit reliable deterministic measurements.
- Evidence: `custodian/tools/iteration/presentation_image_metrics.py:49` delegates to Pillow `crop` without validating the crop against the source dimensions. A 20×10 fully opaque image cropped at `[15, 0, 10, 10]` reports a 10×10 region with 50% coverage because Pillow pads the out-of-bounds half as transparent pixels.
- Disposition: `correction`
- Rationale: Invalid ROI geometry currently produces plausible but fabricated metrics rather than an explicit error.

#### R0-02 — A one-pixel seam on the declared boundary is missed

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: The seam metric must distinguish clean and intentionally broken seam fixtures.
- Evidence: `presentation_image_metrics.py:142` samples only `boundary - band` and `boundary + band`. In a black 20×10 image with a one-pixel red line at x=10, `seam_discontinuity(..., axis="vertical", boundary=10, band=2)` returns `mean_absolute_delta: 0.0`.
- Disposition: `correction`
- Rationale: The declared boundary itself can contain a visible discontinuity while the reported evidence says zero change.

#### R0-03 — Minimum alpha coverage is ignored when both bounds are configured

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Alpha coverage thresholds must be configurable and enforce their declared limits.
- Evidence: `presentation_image_metrics.py:187` returns from the max-bound branch before checking the minimum. An all-transparent image with `min_coverage_ratio=0.5` and `max_coverage_ratio=1.0` passes.
- Disposition: `correction`
- Rationale: A valid two-sided threshold is evaluated as only its upper bound.

#### R0-04 — Awakening evidence adapter exits successfully on failed metric checks

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Evidence mode must provide trustworthy compact ROI/contact-sheet output plus machine metrics.
- Evidence: `custodian/tools/validation/awakening_late_seams_evidence.py:47-67` writes `analyze()` results and returns normally without checking any `passed: false` entry. Its `max_void_ratio: 0.98` check fails for a fully transparent ROI, but `main()` still prints success and returns 0.
- Disposition: `correction`
- Rationale: Automation can accept failed evidence checks as successful completion.

#### R0-05 — Four unavailable direct adopters have no tested reusable fixture/spec

- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: The five direct-adopter paths must either be implemented or have a tested reusable fixture/spec where their runtime dependency is unavailable.
- Evidence: The scenario catalog has 26 schema-valid entries and only one new direct adopter, `traversal/awakening_late_seams_v1`. The implementation closing summary contains four copy/paste snippets with unresolved tick placeholders; no test or committed fixture validates those adopter specifications. Required acceptance explicitly calls for tested reusable fixtures/specs.
- Disposition: `correction`
- Rationale: The current handoff requires downstream packet authors to fill in and validate the tooling design themselves, so the promised reusable adoption path is not yet proven.

#### R0-06 — Live Awakening adopter outputs are not durably available to paired review

- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: Paired reviews can reuse implementation report/metrics/evidence paths; the direct-adopter none/evidence checks expose the promised facts and compact ROI artifacts.
- Evidence: The implementation summary states that the Awakening no-capture repeat and one evidence-mode run passed, but the corresponding run directory, structured JSON, ROI metrics, and contact sheet are not in the checkout or its tracked files. This review could not reproduce the outputs: the assertion DSL command returned 0 while Godot emitted missing imports, autoload failures, and parse errors from the unimported worktree. No adopter run or evidence-mode result is claimed by this review.
- Disposition: `correction`
- Rationale: The feature is available on current main and its implementation packet required one runnable none-mode proof plus one evidence-mode proof. Without durable machine evidence or a clean reproducible rerun, this paired review cannot independently confirm those acceptance claims.

### Validation Evidence

- `python3 -m unittest custodian.tools.iteration.test_build_moment_report custodian.tools.iteration.test_presentation_image_metrics` — 18 tests passed.
- `python3 custodian/tools/validation/moment_forge_schema_smoke.py` — passed.
- `python3 custodian/tools/validation/moment_forge_report_smoke.py` — passed.
- `python3 custodian/tools/validation/moment_forge_changed_router_smoke.py` — passed.
- `python3 custodian/tools/iteration/run_moment.py --list --json` — 26 existing scenarios, every entry `schema_valid: true`.
- Synthetic probes confirmed R0-01 through R0-03.
- `godot --headless --path . --script res://tools/validation/moment_assertion_dsl_smoke.gd` printed the DSL smoke PASS and exited 0, but also emitted thousands of missing-import, autoload, and parse errors due the worktree's unimported project state. This is not counted as a clean runtime pass; no direct adopter run or evidence-mode output is claimed.
- Implementation summary reports prior live Awakening runs, but no corresponding structured result/metrics/contact-sheet artifact was present for review reuse.
- Code review found no evidence that metrics mutate simulation state, confer route/collision authority, or encode aesthetic approval. Paired review instructions correctly prioritize structured evidence reuse.

## Human Gate

No human visual gate is required to review this tooling's technical correctness. Any question about whether a specific game scene or asset actually looks good belongs to that feature's human art review, not this tooling review.

## Handoff

- Next action: Auto-dispatch after `visual-validation-economy-tooling-v1` lands.
- Blockers or open questions: Dependency only.
