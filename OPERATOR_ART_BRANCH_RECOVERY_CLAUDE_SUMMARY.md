# Operator art branch recovery

Scope: preserve local operator-art work, avoid obsolete remote history.

## State
- Local `workbench/operator-art` was merged with `origin/main` (`342a54a9e`) as `bbfbe3d44`, no conflicts.
- Old remote `workbench/operator-art` (`96c4fce19`) diverged: 178 commits not in main. Merging it conflicted in 89 files, so the merge was aborted.
- Published as `origin/workbench/operator-art-2` (normal push, no force). Old remote left untouched; none of its commits were merged or cherry-picked.

## Preserved local commits
- `45c8d6176` remove superseded 128 full_body ranged_2h relaxed_01 n
- `b5062c7a5` stash southwest ranged_2h rifle idle layer in operator source_work

## Net change vs main
- Added: `RANGED_2H_RIFLE_SOURCE_WORK_CLAUDE_SUMMARY.md`, source_work `operator_ranged_2h_southwest_rifle_idle_relaxed_01_5f_96f.png`
- Deleted: the 128 `full_body` `ranged_2h` `relaxed_01` `n` png / .import / .animation.json under both `runtime/` and `source/` (6 files)

## Open issue before landing
These generated files still reference the deleted 128 sprite and need regeneration via the operator asset pipeline:
- `custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json`
- `custodian/content/sprites/operator/runtime/operator_runtime_frames.tres`
- `custodian/content/data/operator/generated/operator_animation_catalog.generated.json`

Godot import and validators have not been run.
