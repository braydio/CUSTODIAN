# Hub First-Set Blockout V1 — Workstream Summary

## What changed

- Added `HubFirstSetLayout` as the runtime authority for the exact 32px grid,
  district envelopes, markers, threshold volume, and marker-label offsets.
- Added `HubFirstSetMap`, configured from that layout for walkability,
  navigation, boundary collision, district fills, named marker nodes, and labels.
- Added a Road-only presentation scene over the existing five production plate
  pairs. The Road script now has an opt-in collision switch; the legacy Road
  scenes keep collision enabled, while H1 leaves its blocker root empty.
- Added explicit map-label offsets for close marker clusters so the required
  overview can label each handoff point independently.
- Added the standalone Operator/camera playtest at `Spawn_SouthReach` and a
  focused registered smoke for layout, routes, minimum envelope width, module
  registration, collision ownership, inert transitions, spawn, and camera bounds.
- Reconciled the directly related Hub/Road docs and recorded H1 in current
  state and the file index.

## Evidence

- Focused: `hub_first_set_blockout` — passed; 13,110 walkable cells, 48 merged
  boundary rails, 14 named markers.
- Existing compatibility checks: `road_of_witnesses_production` passed;
  `twin_solaria_runtime` passed.
- Changed-file closeout: `/tmp/hub_first_set_blockout_validation.json` — passed
  14/14 tests, complete coverage, no uncovered changed files.
- `git diff --check` — passed.
- Human overview: `reports/hub_first_set_blockout/overview.png` (2048×2048).
  Human topology/readability approval is pending; no subjective approval is
  claimed here.

## Friction and deferred work

The claim command completed but returned no stdout. Its Git-common-dir receipt
verified the workstream, branch, and worktree, so the task was resumed from that
receipt without a second claim. The fresh checkout needed the validation
runner's import step before global script classes/resources loaded. The first
changed-file pass passed every selected test but exposed missing validation
ownership for the new Road presentation scene; adding the scene to the H1
owner list made the rerun complete. One overview capture showed overlapping
marker labels; the layout now owns stable offsets and the final image replaced
the first at the same path.

`check_ai_context.py` still reports 20 pre-existing packet/index findings
outside this task (historical feedback receipts, stale packet index entries,
and an unrelated missing V2 Work surface). H2-H6 transitions and Contract
prewarm/deployment remain deferred, as does production Hub art.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: Dispatcher stdout was lost after a successful claim; fresh worktree imports were required; the first coverage report omitted the Road presentation scene; initial marker labels overlapped.
- Root cause / contributing factors: durable claim receipt was not reflected in stdout; worktree-local Godot caches; validation owner list initially missed one scene; close marker spacing required authored label offsets.
- Prevention / pipeline improvement: use the durable claim receipt when stdout is absent; list all authored scene dependencies as validation owners; keep label offsets in layout data for close marker clusters.
- Tooling / docs drift discovered: 20 unrelated existing `check_ai_context.py` findings.
- Follow-up: none
- What worked: receipt-based recovery and the focused smoke made the structural proof repeatable.
