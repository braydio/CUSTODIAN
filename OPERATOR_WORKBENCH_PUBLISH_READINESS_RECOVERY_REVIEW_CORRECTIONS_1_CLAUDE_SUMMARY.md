# Operator Workbench Publish Readiness Recovery Review Corrections 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

Workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1` (finding `R0-01`).

## What changed
- `operator anim publish` (non-dry-run) no longer calls `animation_workbench.publish()` directly. It builds a `WorkbenchService` and calls `publish(..., prepare=True, force_stale=...)`, the same scoped authority the UI uses: dedicated `workbench/operator-art` identity, `prepare_publish_checkout`, final pre-mutation `inspect_publish_readiness`, then `publish_to_main` with `publication_allowlist()` and `land_main.py`.
- `WorkbenchService.publish` gained keyword-only `prepare` and `force_stale`. UI behavior is unchanged (defaults off). `force_stale` waives only source freshness; identity, dirt, dependencies, transactions and landing still block.
- `operator_cli.py` also catches `ArtWorktreeError` so blockers print as `operator: ...` with exit 2.
- Dry-run still goes straight to the workspace-only backend call.
- New `operator_cli_publish_boundary_smoke.py`, registered in `validation_manifest.json` as `operator_cli_publish_boundary`. Workbench doc updated.

## Evidence
- New smoke covers coordination main (plain and with stale override), detached checkout, dirty art checkout (all exit 2, hashes/HEAD/status unchanged, publish never called), dry-run (no change, no commit), and an eligible art checkout (prepare, inspect, publish ordering; staged set exactly the source; landed on origin/main).
- Negative control: against the pre-fix code the smoke fails at the first case (coordination main exited 0).
- `operator_art_worktree_smoke`, `operator_workbench_mirror_publish_smoke`, `operator_workbench_ui_smoke`, `operator_animation_workbench_smoke` pass; `git diff --check` clean. `run_validation.py --changed --base origin/main`: 12/12 passed, coverage complete.

## Awkward parts
- The test stubs only the Aseprite-facing backend (`w.publish`, `w.load`, plan/workspace), so it proves the boundary, not real Aseprite export. The Textual pilot was skipped (not installed), as before.
- The first run exited silently: my harness swallowed an argparse `SystemExit`. Fixed.
- `--changed` without `--base` selected 0 tests on a committed tree, so the finish report must use `--base origin/main`.
- UI `publish` itself does not call `prepare` (its preview step does); only the CLI passes `prepare=True`.

No canonical art or gameplay changed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: silent SystemExit in test harness; empty `--changed` selection without `--base`.
- Root cause / contributing factors: harness redirected stderr and swallowed argparse exit; default `--changed` base.
- Prevention / pipeline improvement: use `--base origin/main` for finish reports.
- Tooling / docs drift discovered: Workbench doc CLI publish paragraph updated.
- Follow-up: none
- What worked: reusing the art-worktree fixture remote for real identity/readiness/landing.

## Parallel worktree reminder
Other in-progress worktrees exist (for example `agent/procgen-alpine-plateau-underlay-assets`, `agent/awakening-04-05-connector-transition-regression`). The original checkout, `/home/braydenchaffee/Projects/CUSTODIAN` on `main`, is where to return after this task.

## Next Handoff
- Next workstream: review-operator-workbench-publish-readiness-recovery-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
