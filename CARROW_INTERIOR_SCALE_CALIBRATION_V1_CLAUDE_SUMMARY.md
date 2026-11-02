# Carrow Interior Scale Calibration V1

Workstream: `carrow-interior-scale-calibration-v1`

## Result

Implemented three fixed debug-only Machine House scale scenes. They share one builder/controller, the shipped Operator scene and capsule collider, the shipped CameraController, the same camera base zoom (`0.84`), 150 px/s movement speed, lighting, 32 px floor sources, 13 registered Machine House art sources/z values, and three East storage identities/resource sets. The harness has its own minimal room geometry and never instantiates `GothicCompoundMap` or changes the production East, West or Operations room data.

Launch in Godot with any one of these paths:

- `res://scenes/debug/carrow_machine_house_scale_24x18.tscn` — 24×18 cells, 768×576 px, 432 floor cells, 154 collider cells.
- `res://scenes/debug/carrow_machine_house_scale_30x22.tscn` — 30×22 cells, 960×704 px, 660 floor cells, 174 collider cells.
- `res://scenes/debug/carrow_machine_house_scale_36x26.tscn` — 36×26 cells, 1152×832 px, 936 floor cells, 194 collider cells.

Use `WASD` to move the real Operator. `1`, `2` and `3` teleport to ENTRY, CENTER and NORTH. `R` resets to ENTRY. `F1` toggles outlines derived from the actual physics colliders and Operator shape, `F2` toggles the 32 px grid, and `F3` toggles the read-only values overlay. The common `0.84` camera base zoom is locked in all three fixtures so room-dependent auto-zoom does not alter the comparison.

## Evidence

The deterministic smoke proves the exact floor/collider cell sets, four-cell south exit, clear four-column aisle, fixed equipment rectangles, all 13 source paths/anchors/z values at scale 1, the three art-bound storage IDs and contents, one actual Operator, camera setup, room bounds, physical clearance at every waypoint and all four doorway cells, controls/reset, missing-art/malformed-config/door-block/overlap negative cases, and absence of a production route owner.

Renderer evidence contains nine 768×576 captures (ENTRY/CENTER/NORTH for each size), one `geometry.json` per size, and the numeric `comparison.json`. The generated files are under the scoped ignored `reports/carrow_scale_calibration/` path. A local copy for fresh-context review is retained at `.git/custodian-review-runs/carrow-interior-scale-calibration-v1/20261016T012240Z-44c5ccfe48e1/`. Geometry JSON records native source bounds intersecting walkable floor cells as presentation-vs-solid evidence; those sprite bounds do not define or modify collision.

Validation passed:

- `carrow_machine_house_scale_calibration` manifest test.
- `carrow_operations_house_interior` and `carrow_yard_interior` regressions (including East/West/Ops).
- `carrow_backdrop_isolation_smoke.gd` direct run.
- Changed-file validation: 34 selected tests passed, 0 failed, 0 skipped, complete coverage.
- `validate_review_pairing.py`: 102 paired packets passed.
- `task_packet_index.py`, `check_ai_context.py` (0 errors/warnings), and `git diff --check`.
- Direct 24×18 scene launch at 768×576 under the renderer exited without script errors.

The machine review does not score aesthetics or choose a preferred production size. It leaves the hands-on scale choice to the user. No production room/router file changed.

The packet called the evidence directory ignored, but the repository had no matching ignore rule. Added only `reports/carrow_scale_calibration/` to the root `.gitignore`; this is recorded as tooling/docs drift in the packet.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: the specified generated-evidence directory lacked a repository ignore rule; first Godot use performed a full import scan.
- Root cause / contributing factors: packet and repository ignore policy drifted.
- Prevention / pipeline improvement: define scoped generated-output exclusions with the packet that requires them.
- Tooling / docs drift discovered: `reports/carrow_scale_calibration/` was not ignored as specified.
- Follow-up: review-carrow-interior-scale-calibration-v1
- What worked: actual shape queries established clearance against PhysicsServer2D geometry while fixed cell tests proved room ownership.

## Next Handoff

- Next workstream: review-carrow-interior-scale-calibration-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
- Refresh reason: none
- Next action: after implementation lands and archives complete, run the fresh-context paired technical review and verify all nine captures, geometry JSON, unchanged production room files, and focused regressions.
- Blockers or open questions: none for technical completion; the user's later production-size choice remains separate and human-owned.
