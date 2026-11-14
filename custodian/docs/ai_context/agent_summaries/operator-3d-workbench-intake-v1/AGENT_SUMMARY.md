# Operator 3D Workbench Intake V1 — Closing Summary

Agent: Claude (Claude Haiku 5.5, dispatcher agent id `claude`)
Workstream: `operator-3d-workbench-intake-v1`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeeaefc-af8c-83ea-925f-091a0130a3fb

## Integration

- Claimed through `dispatch.py claim operator-3d-workbench-intake-v1 --agent claude --mode normal` (run `20261112T175420Z-e3cddd4e1b96`, verified, checkout created).
- Source branch: `agent/operator-3d-workbench-intake-v1` at `fde2793850f463aad97184a513a53110ac5880dd` (preserved remotely, not rewritten).
- Reconciled with `origin/main` at `002504a4da95eb0c89f2649952cdec328718b1ea` by a non-forced merge (`624991c96`). The merge had no conflicts; `validation_manifest.json` still parses and FILE_INDEX merged cleanly.
- Fix commit on top: guards `OperatorWorkbenchApp._preview_tick` against an empty screen stack during teardown. The guard predates this branch (present on `origin/main`) and was failing `operator_workbench_ui_smoke.py` with `ScreenStackError`.

## Host intake evidence

Staged frames: `CUSTODIAN-operator-art/custodian/.ai/operator_3d_animation_preview/` (320 PNGs, `frames80/walking` and `frames80/running`).

- `--plan`: 320 validated frames, 16 sessions, `written: 0`.
- `--apply`: `written: 0`; all 16 sessions `UNCHANGED`. The sessions already existed in the art checkout's Workbench root from an earlier run, so this first apply was a no-op rather than a fresh registration.
- repeated `--apply`: `written: 0`, all `UNCHANGED`.
- `--verify`: `ok: true`, 16 sessions `VERIFIED`.

## Tests

- `test_operator_3d_candidate_intake.py`: 55 run, 0 failed (run with the project `.venv`).
- `test_operator_3d_candidate_ui.py`: 2 run, 0 failed.
- `test_character3d_tools.py`: 23 run, 0 failed, 1 skipped (`StagedConsistencyTests.test_pursuit_contract_matches_staged_manifest`; no Pursuit Frame staged manifest exists in this checkout).
- `operator_workbench_ui_smoke.py`: exit 0 after the tick guard fix (17 PASS lines, including Textual pilot).
- `operator_art_worktree_smoke.py`: exit 0.

## Not yet done

- Literal interactive `operator ui` launch from the persistent art checkout, with all eight directions played for both actions. This needs the landed tooling in that checkout first.
- Failure-injection coverage was taken from the existing intake test suite, not re-executed as a separate campaign.
- Landing through `workstream.py finish` is gated on a fully green validation report. The one skipped test above keeps the report non-green, so the report was not forced.
