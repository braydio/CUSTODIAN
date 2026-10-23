# Carrow Operations House Interior V1

Implemented the 20×14 Operations House as a third named Carrow interior, bound to the generator's real 11×10 `operations_house` site. The room has 280 registered floor sprites, the accepted three-cell south doorway, a clear central aisle, civic controls/dispatch/records/stock dressing from existing Carrow art, a subtle local lighting profile, and one art-bound emergency-spares cache. No route authority, art family, faction behavior, or alarm system was added.

East Machine House and West Draft House remain separate rooms. The regression smoke visits East → Operations → West and back in reverse, checks site-derived return positions and camera/weather/backdrop restoration, preserves the same Operator, and verifies all three caches remain depleted after revisits. Current state and file ownership documentation now describe all three rooms.

## Validation Evidence

- `carrow_operations_house_interior`: PASS (1/1).
- `carrow_yard_interior`: PASS.
- `persistent_compound_layout`: PASS.
- `carrow_backdrop_isolation_smoke.gd`: PASS (eight transitions).
- Changed-file validation: PASS (39 selected, 39 passed, 0 failed, 0 timed out, 0 skipped; complete coverage), `/tmp/carrow-operations-changed-final.json`.
- `git diff --check`: PASS.

The first focused run exposed a missing `K` symbol in the shared room-grid validator; the validator now accepts the dispatch symbol used by the approved layout. A fixture coordinate was corrected to the grid's actual x=9–11 doorway. The initial fresh-worktree parse failure was resolved by allowing Godot to initialize its global-class cache before rerunning validation.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial Godot validation preceded first-worktree class-cache initialization; the accepted dispatch symbol was absent from the common room-layout allowlist; the first doorway assertion used the wrong column.
- Root cause / contributing factors: Fresh-worktree Godot setup and incomplete generic symbol coverage, plus a test coordinate transcription error.
- Prevention / pipeline improvement: Initialize Godot metadata before first focused run and derive collision assertions directly from the authored grid.
- Tooling / docs drift discovered: `CURRENT_STATE.md` described only the East Machine House after W1 had landed; it now records East, West, and Operations. The new backdrop regression is included in validation manifest ownership.
- Follow-up: review-carrow-operations-house-interior-v1
- What worked: A focused structured smoke proved site binding, room geometry, collision cells, return/camera/weather state, backdrop isolation, and cache persistence without adding runtime systems.

## Next Handoff

- Next workstream: review-carrow-operations-house-interior-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: After implementation lands and archives complete, run the paired fresh-context review and inspect the native-scale presentation and collider/doorway geometry.
- Blockers or open questions: none; preserve the separate pending Carrow route-authority migration.
