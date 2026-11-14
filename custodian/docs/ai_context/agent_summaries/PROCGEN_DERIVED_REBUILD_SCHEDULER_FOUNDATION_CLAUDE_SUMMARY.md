# Procgen Derived Rebuild Scheduler Foundation — Closing Summary

Implemented M1's shared dirty-request ledger at `ProcGenTilemap`'s existing
rebuild boundaries. The scheduler tracks topology, collision, walkable-boundary,
navigation, shadows, and presentation requests with deterministic batch/reason/
region snapshots, coalesced counts, committed counts, and cumulative commit
durations. Existing systems still own rebuild effects. Synchronous commit points
and navigation's deferred flush timing remain as before.

The dedicated scheduler smoke proves two same-batch collision requests collapse
to one pending entry with a unioned region and sorted reasons (2 requested, 1
coalesced), then records one commit and 23 microseconds. Runtime-health smoke
verifies live adapter accounting for topology, boundary, navigation, shadows,
and presentation. `runtime_wall_collision_compaction_smoke.gd` passed with 19
bodies / 443 shapes and verified destroying one tile preserved its neighbor.
`navigation_elevation_smoke.gd` passed. The S1 quick benchmark passed with
`determinism_ok=true`; both 48x48 seed-420777 runs produced fingerprint
`1773840677`.

The first changed-file report had every selected test green but was incomplete
because the runtime-health smoke was not registered as a manifest test. The
manifest now includes it. Two early closeout attempts were stopped when another
procgen workstream started broad validation against the shared Godot user cache;
the final sweep completed after those runs finished. Its 21 selected tests all
passed and its coverage report is complete (5 covered files, 0 uncovered).
A first scheduler smoke also ran before the fresh worktree had imported its
LFS-backed assets, producing project-wide load noise after the smoke passed.
The cached LFS objects were materialized, preflight passed, a full import
completed, and local LFS/import churn was restored before closeout.

No before/after performance reduction is claimed: this foundation records
requests and commits without batching rebuild work. Full producer cutover and
commit batching remain M2. Moment Forge was not run because the change only
adds scheduling telemetry and preserves presentation/gameplay timing.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: the first changed-file report lacked coverage for the runtime-health smoke; two closeout attempts overlapped separate procgen sweeps; the initial smoke ran before LFS hydration/import.
- Root cause / contributing factors: the existing health smoke lacked a validation-manifest entry, separate worktrees share Godot's user cache, and a fresh checkout has no populated `.godot` import cache.
- Prevention / pipeline improvement: register health tests in the manifest, serialize broad sweeps, and hydrate cached LFS objects before Godot import; the manifest and validation sequence are now corrected for this task.
- Tooling / docs drift discovered: validation policy relies on agents to serialize sweeps across worktrees; the runner's project-local lock does not enforce that cross-worktree rule. Follow-up: manual follow-up to add a shared Godot validation lock.
- Follow-up: fixed-in-scope (runtime-health manifest coverage); manual-follow-up (shared cross-worktree validation lock).
- What worked: focused tests passed; cached LFS hydration avoided network fetches.
