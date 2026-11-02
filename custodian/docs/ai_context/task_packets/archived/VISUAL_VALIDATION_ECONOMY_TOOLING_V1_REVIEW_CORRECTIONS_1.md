# CORRECTION: VISUAL VALIDATION ECONOMY TOOLING V1 REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `visual-validation-economy-tooling-v1-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-visual-validation-economy-tooling-v1`
- Locks: `moment-forge-tooling`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, workflow`
- Paired review workstream: `review-visual-validation-economy-tooling-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `dfaf9e269d4c12d98bc03f5800cc34ce3530a50a`
- Parent implementation: `visual-validation-economy-tooling-v1` — `custodian/docs/ai_context/task_packets/archived/VISUAL_VALIDATION_ECONOMY_TOOLING_V1.md`
- Parent review: `review-visual-validation-economy-tooling-v1` — `custodian/docs/ai_context/task_packets/archived/REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1.md`
- Findings addressed: `R0-01, R0-02, R0-03, R0-04, R0-05, R0-06`
- Affected acceptance: Parent packet acceptance for deterministic configurable image metrics, trustworthy ROI/evidence checks, and five direct-adopter paths or tested reusable fixture/specs.
- Current defect/evidence: The parent review confirmed silent padded out-of-bounds crops, a one-pixel boundary seam false-negative, ignored minimum alpha threshold when both bounds exist, an Awakening evidence adapter that exits 0 after failed metrics, four adopter snippets that are not covered by reusable fixture/spec tests, and no durable Awakening run output available to independently verify the implementation summary's claimed no-capture/evidence runs.
- Goal: Make image metrics reject invalid geometry and correctly evaluate declared thresholds, propagate failed evidence checks as failures, provide tested reusable direct-adopter specifications for the four feature runtimes unavailable to this tooling slice, and make one clean live adopter proof available for paired review.
- Completion boundary: Fix the four narrow metrics/adapter defects and add automated checks for their failure cases; package the four non-Awakening adopter patterns as reusable specs/fixtures with schema/contract validation and usage documentation; produce and record a reproducible Awakening no-capture run plus one compact evidence-mode proof after confirming the project import is healthy.
- Current measured state: Parent review synthetic repros: padded ROI returned 0.5 coverage on an opaque image, a one-pixel red line on a declared seam returned delta 0.0, and transparent alpha coverage passed the `[0.5, 1.0]` bounds. A transparent ROI also yields a failed adapter metric while `main()` returns 0. The four summary templates contain unresolved tick placeholders and have no validating test. The review worktree's Godot invocation emitted project import/class errors, and no adopter run artifacts were available to reuse.
- Evidence: `custodian/docs/ai_context/task_packets/archived/REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1.md`, findings R0-01 through R0-05; parent implementation packet direct-adopter acceptance.
- Task-specific authority: `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; parent implementation and review packets.
- Work surface: `custodian/tools/iteration/presentation_image_metrics.py`, `custodian/tools/validation/awakening_late_seams_evidence.py`, `custodian/tools/iteration/test_presentation_image_metrics.py`, and tested reusable adopter specs/fixtures plus their focused validation.
- Required correction: Validate all ROI edges against source image size before crop; include boundary pixels in seam measurements or otherwise detect a discontinuity located on the declared seam; combine minimum and maximum alpha constraints conjunctively; return nonzero from the Awakening evidence adapter whenever any required metric fails; add tested reusable adopter specs for Twin Crown, Solarium I, Operator mobile guard, and Vaultwing closure that downstream packets can instantiate without new probe/metric design; run the live Awakening adopter in none mode and once in evidence mode from a healthy import, then record the structured result and compact evidence locations in the closing summary or a committed machine-readable receipt.
- Preserve: Existing image-metric schema and raw metric reporting where compatible, valid ROI behavior, Moment Forge V1 scenario compatibility, capture-mode semantics, the human gate for subjective art/baseline decisions, and the rule that presentation metrics do not become gameplay authority.
- Non-goals: New art/runtime feature implementation, aesthetic scoring, changing existing gameplay or route authority, broad Moment Forge redesign, and full-frame evidence generation.
- Acceptance:
  - Out-of-bounds and negative-origin ROIs fail explicitly; valid in-bounds crops retain exact existing dimensions and values (`R0-01`).
  - Synthetic positive and negative controls detect a one-pixel discontinuity exactly at a declared boundary, while a clean seam remains within its expected metric (`R0-02`).
  - Alpha checks with both minimum and maximum thresholds fail below the minimum, fail above the maximum, and pass within the interval (`R0-03`).
  - Awakening evidence adapter exits nonzero and identifies failed check indices when required metric checks fail; passing metrics still produce the sheet and manifest (`R0-04`).
  - Four committed adopter specs/fixtures are exercised by a focused test or schema smoke and provide the required stage/state, probe/assertion, authority, and compact-evidence pattern for their parent feature packet (`R0-05`).
  - A clean `traversal/awakening_late_seams_v1` no-capture run passes, and one evidence-mode run produces a metrics manifest plus five-cell contact sheet; the structured results and retained/reproducible paths are recorded for paired review (`R0-06`).
- Validation: `python3 -m unittest custodian.tools.iteration.test_presentation_image_metrics custodian.tools.iteration.test_build_moment_report`; `python3 custodian/tools/validation/moment_forge_schema_smoke.py`; `python3 custodian/tools/validation/moment_forge_report_smoke.py`; `python3 custodian/tools/validation/moment_forge_changed_router_smoke.py`; `python3 custodian/tools/validation/run_validation.py --changed --json` after inspecting resource availability and ensuring no concurrent validation sweep.
- Task overrides: `none`
- Deferred: Any live feature-specific adopter wiring whose prerequisite runtime remains unavailable; visual baseline and art-direction judgments remain with each feature's human review.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial changed-file coverage did not map the new adopter specs and focused adapter/spec tests; an evidence receipt was also briefly placed in the adopter-spec directory, where the spec loader correctly rejected it.
- Root cause / contributing factors: The validation manifest had no owners for the new tests/spec data, and the reusable spec loader intentionally treats every JSON file in its directory as a scenario template.
- Prevention / pipeline improvement: Added dedicated validation manifest entries and explicit owners for both focused tests and adopter specs; kept the live-run receipt with curated evidence.
- Tooling / docs drift discovered: The changed-file router lacked coverage for the new visual-economy test/spec files; repaired in-scope.
- Follow-up: `fixed-in-scope`
- What worked: Cached LFS checkout plus a single headless editor import restored the isolated worktree, after which the live runs and changed validation passed.

## Independent Review

- Status: `passed`
- Review workstream: `review-visual-validation-economy-tooling-v1-review-corrections-1-r1`
- Reviewed on main: `d2c530c2386117cbfb04f55076cce9a5553043d2`
- Review modes: `code, runtime, workflow`
- Reviewer provenance: `same-agent-fresh-context`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_VISUAL_VALIDATION_ECONOMY_TOOLING_V1_REVIEW_CORRECTIONS_1_R1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

### Original finding disposition

- `R0-01` — `fixed`. Independently reproduced a padded out-of-bounds ROI and confirmed `MetricsError`; negative/overflow/nonpositive geometry is rejected by the metric path.
- `R0-02` — `fixed`. A one-pixel vertical boundary discontinuity measured delta `63.75`; the clean seam control measured zero.
- `R0-03` — `fixed`. With bounds `[0.5, 0.75]`, coverage `0` and `1` fail while `0.5` passes.
- `R0-04` — `fixed`. Focused adapter test proves failed required metrics return exit code 1 and identify failed indices; passing metrics still emit sheet and manifest.
- `R0-05` — `fixed`. Four adopter specs are exercised by focused schema/fixture validation. The Operator animation values remain symbolic by design: the README instructs downstream consumers to bind roles and instantiate assertion templates when the feature runtime lands.
- `R0-06` — `fixed` (supplemental to this review packet's stated R0-01..R0-05 scope). The durable receipt's canonical scenario hash matches `run_moment.scenario_sha256`; both none/evidence runs report the same fingerprint, 26 probes, zero warnings, and 5/5 ROI checks. Retained metrics match the receipt and the contact sheet is 1200×444.

### Validation

Focused unittest suite: 27 tests passed. Moment Forge schema, report, and changed-router smokes passed; `run_moment.py --list --json` reported all 26 scenarios schema-valid. Review-pairing validation passed. The broader `task_packet_index.py` check reports pre-existing managed-block drift; it is refreshed in this review branch and rechecked before commit.

## Completion Notes

- Implemented all six review corrections with focused negative/positive controls and four reusable downstream adopter specs.
- Both Awakening live runs passed with stable fingerprint `be8bd7cf283947d0f7b7c4f868c1dcd721551c9004c4e58323fe237efabee3e6`; the evidence adapter passed 5/5 ROI checks and wrote a 1200×444 contact sheet.
- Durable compact evidence and full structured receipt are in `reports/moment_forge/curated/awakening_late_seams_v1_review_correction_1/`; reproduction commands are recorded in `live_run_receipt.json`.
- Focused tests (27), Moment Forge schema/report/router smokes, and `run_validation.py --changed --json` passed with complete coverage: 10 selected checks, 0 failures.
- Full frames and timestamped run directories are ephemeral worktree artifacts; the compact contact sheet, metrics, and receipt are retained for paired review.
