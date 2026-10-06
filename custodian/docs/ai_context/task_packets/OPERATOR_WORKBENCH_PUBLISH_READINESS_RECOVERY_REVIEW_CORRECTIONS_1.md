# CORRECTION: OPERATOR WORKBENCH PUBLISH READINESS CLI BOUNDARY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-operator-workbench-publish-readiness-recovery`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-operator-workbench-publish-readiness-recovery-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `21ffccb775b24ed3d8c7e8d7651acdd438a18017`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include this exact Authoring chat URL in each correction/review summary and handoff.
- Parent implementation: `operator-workbench-publish-readiness-recovery` — `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
- Parent review: `review-operator-workbench-publish-readiness-recovery` — `custodian/docs/ai_context/task_packets/REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md`
- Findings addressed: `R0-01`
- Affected acceptance: Publication may mutate canonical Operator source only from the dedicated art checkout after readiness/preparation, then stage the fixed allowlist and land through the approved Operator publication authority.
- Current measured state: UI publication currently calls the structured readiness/preparation and scoped `publish_to_main` path. The documented CLI path calls the lower-level Workbench transaction directly; the four existing focused Workbench smoke scripts pass but do not assert CLI checkout/readiness enforcement.
- Current defect/evidence: `operator_cli.py:58` invokes `animation_workbench.publish()` directly. That backend replaces canonical files but does not verify checkout identity, run readiness/preparation, enforce the publication allowlist, or use `publish_to_main`; the UI service does. A clean coordination-main CLI invocation therefore bypasses the acceptance boundary.
- Goal: Make the documented CLI publication route obey the same dedicated-checkout readiness and scoped landing contract as the UI, or fail closed before canonical mutation when that contract cannot be provided.
- Completion boundary: Close the CLI publication bypass with one shared publication authority. Preserve CLI dry-run and explicit stale-source semantics where compatible with the reviewed contract. Add fixture-isolated tests proving unsafe checkout/readiness cases make no canonical changes and the dedicated art-checkout CLI path cannot bypass scoped staging/landing.
- Evidence: Parent finding `R0-01`; `custodian/tools/operator/operator_cli.py`; `custodian/tools/operator/animation_workbench.py`; `custodian/tools/operator/ui/service.py`; `custodian/tools/operator/operator_art_worktree.py`; four focused Workbench smoke scripts.
- Task-specific authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; archived implementation and review packets named above; `custodian/tools/operator/operator_art_worktree.py` for checkout/readiness/allowlist/landing authority.
- Work surface: CLI dispatch in `custodian/tools/operator/operator_cli.py`; a narrow shared service/backend seam if needed; focused CLI/publication regression coverage in `custodian/tools/validation/` and the existing Workbench smoke owners.
- Required correction:
  1. Ensure non-dry-run CLI publication cannot call canonical-mutating `animation_workbench.publish()` without dedicated `workbench/operator-art` identity, structured readiness, final pre-mutation revalidation, and the existing `publish_to_main` scoped stage/commit/land flow.
  2. Preserve dry-run as a no-canonical-mutation operation and keep the explicit stale-source override bounded by the existing reviewed CLI contract; do not let it override checkout identity, unknown dirt, missing dependencies, or landing authority.
  3. Add adversarial CLI-level coverage for coordination `main`, an arbitrary/detached checkout, dirty/readiness-blocked art checkout, and an eligible dedicated art checkout. Assert failure cases preserve canonical source/runtime hashes and make no tracked changes; assert the success case stages only `publication_allowlist()` and reaches the approved landing path.
- Preserve: UI publication behavior; local-only LFS preparation and exact donor verification; source freshness; transaction rollback and `RECOVERY_REQUIRED`; pending-land retry; current allowlist and `land_main.py` authority; no user worktree mutation outside the safe preparation contract.
- Non-goals: Do not change Operator pixels, timing/gameplay semantics, FX adoption, sparse dependency scope, general Git/workstream lifecycle, or redesign the Workbench publisher.
- Acceptance:
  1. `operator anim publish` from coordination `main`, arbitrary/detached checkouts, or any readiness-blocked art checkout fails before canonical source/runtime mutation and reports an actionable blocker.
  2. An eligible dedicated art checkout CLI publication runs structured readiness/preparation and a final immediate pre-mutation readiness check, then uses the exact publication allowlist and approved landing authority.
  3. CLI dry-run does not replace canonical files, create a publication commit, or land changes.
  4. Stale-source override does not bypass checkout identity, dirty-state, dependency, sparse-profile, transaction, or landing guards.
  5. Existing four focused Workbench smoke validations and the new CLI boundary regression pass; no canonical art/gameplay changes are included.
- Validation: Run the new focused CLI publication regression first, followed by `operator_art_worktree_smoke.py`, `operator_workbench_mirror_publish_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, and `git diff --check`. Reuse valid exact-head import/LFS evidence; preflight before any Godot import and never fetch LFS from the network.
- Task overrides: `none`
- Deferred: none.

## Completion Truth

Required before completion.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `operator_cli.py` non-dry-run publish now calls `WorkbenchService.publish(..., prepare=True, force_stale=...)` instead of `animation_workbench.publish()`. `ui/service.py` runs `prepare_publish_checkout` before mutation, then `publish_to_main` with the existing final `inspect_publish_readiness` revalidation and allowlist; `force_stale` waives only source freshness. New `operator_cli_publish_boundary_smoke.py` (registered as `operator_cli_publish_boundary`) drives `operator_cli.main` against fixture remotes: coordination main (with and without `--force-stale-source`), detached checkout, and dirty art checkout all exit 2 with unchanged hashes/HEAD/status and no publish call; dry-run makes no change or commit; the eligible art checkout runs prepare, then inspect, then publish, stages exactly `[SOURCE]` and lands on origin/main. The test fails (exit 0 from coordination main) against the pre-fix code. The four focused Workbench smokes and `git diff --check` pass; `run_validation.py --changed --base origin/main` passed 12/12 with complete coverage.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first test run exited silently with argparse code 2 (extra positional `group`), because the harness swallowed `SystemExit` inside its stdout/stderr redirect. `run_validation.py --changed` without `--base` selected zero tests on a committed tree, which `validation_green` treats as not green.
- Root cause / contributing factors: Test harness captured argparse errors without surfacing them; the default `--changed` base is the working-tree diff.
- Prevention / pipeline improvement: Pass `--base origin/main` when generating the finish validation report from a committed branch.
- Tooling / docs drift discovered: The Workbench doc described only `--force-stale-source` for CLI publish; updated with the shared-authority and fail-closed contract.
- Follow-up: `none`
- What worked: Reusing the art-worktree smoke's fixture remote exercised the real checkout identity, readiness and landing code with only the Aseprite backend stubbed.

## Handoff

- Next action: Paired review `review-operator-workbench-publish-readiness-recovery-review-corrections-1` before any downstream Workbench lane advances.
- Blockers or open questions: none.
