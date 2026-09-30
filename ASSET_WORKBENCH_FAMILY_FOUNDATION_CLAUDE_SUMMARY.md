# Asset Workbench Family Foundation — Closing Summary

Implemented Slice 1 as a read-only Asset V2 FAMILY navigator. `asset ui` lazily
loads the optional Textual interface; the shell `asset` command reuses the
existing Operator UI virtual environment for this subcommand when available.
Contracts and lifecycle state flow through immutable projections over
`load_all_families()` and `get_family_status()`. Search uses only the accepted
snapshot, and failed refreshes keep the last view and semantic selection.

## Files changed

- Added `custodian/tools/assets/asset_workbench/` projections, service,
  transactional browser, Textual app, and optional dependency requirements.
- Extended `custodian/tools/assets/asset.py` and `tools/custodian_aliases.sh`
  with the optional `asset ui` launch path.
- Added `custodian/tools/validation/asset_workbench_ui_smoke.py` and its
  focused `asset_workbench_ui` manifest owner.
- Updated the Asset Pipeline V2 command reference, Asset Workbench roadmap,
  current state/context/index, and archived the completed task packet.

## Evidence

- Baby Opossum projects all 50 states, 7 action groups, body and barrel_prop
  layers, 4dir policy, auto-mirror policy, and authored/mirrored status fields.
- Its 22 cataloged runtime PNGs were LFS pointers in the worktree. All 22
  objects were already in the local cache and were materialized with targeted
  `git lfs checkout`; no network download occurred and Git reports no asset
  changes. The resulting projection reports 15 states with art and mirrored
  runtime directions on 3 states.
- The focused smoke passes with Textual Pilot using
  `.ai/operator-ui-venv/bin/python`. It also proves fixture read-only behavior,
  search without rediscovery, refresh failure retention, semantic selection,
  deterministic fallback, mirror provenance, and ordinary CLI operation when
  Textual imports are blocked.
- `asset_pipeline_v2_smoke.py`, `asset_pipeline_cli_ux_smoke.py`, and
  `asset_requirements_smoke.py` pass.
- `run_validation.py --changed --json`: passed 11/11 selected unit checks;
  the system-Python run explicitly skipped its optional Textual Pilot, which
  passed separately in the supported UI environment.
- `git diff --check`: passed.
- No migration rows or production edits were in scope. No downstream CI link
  was available at closeout.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first Pilot run caught an unsupported Tree constructor
  argument. Runtime art initially appeared absent because cached LFS content
  had not been checked out in this worktree.
- Root cause / contributing factors: Textual 0.89.1 exposes `show_root` as a
  property; degraded LFS smudge leaves pointer files despite locally cached
  objects.
- Prevention / pipeline improvement: Keep the Pilot smoke in the focused owner
  and check pointer/cache state before interpreting catalog-backed assets as
  missing.
- Tooling / docs drift discovered: `ASSET_PIPELINE_V2.md` omitted `asset ui`;
  corrected in this slice.
- Follow-up: fixed-in-scope
- What worked: Fixture-backed refresh/search coverage plus real-family
  projection kept the read boundary explicit.
