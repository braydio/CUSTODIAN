# Operator Workbench Runtime Resource Publish Allowlist

## What changed

- Added the canonical `custodian/content/sprites/operator/runtime/operator_runtime_frames.tres` output to the Workbench publisher allowlist. The runtime sync pipeline regenerates this SpriteFrames resource during source publication.
- Added the canonical runtime frames resource to the publish transaction's resource snapshot and rollback set.
- Changed resource backup paths from basename-only to repository-relative paths. This prevents the canonical and compatibility `operator_runtime_frames.tres` files from overwriting each other's backups.
- Extended the isolated publish and rollback smokes to prove the canonical resource can be staged, generated resources are restored on downstream failure, and same-named resources get unique backups.

## Validation and evidence

- `python3 custodian/tools/validation/operator_art_worktree_smoke.py`: passed; the fixture publishes and stages the canonical runtime frames resource.
- `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`: passed; both canonical and compatibility frames resources are independently backed up and restored after an injected runtime-build failure.
- `python3 -m py_compile` on the two tooling modules and both changed smokes: passed.
- `git diff --check`: passed.
- `operator_animation_workbench_smoke.py` was attempted but could not complete its live source scan: the isolated worktree contains an unmaterialized LFS pointer at `custodian/content/sprites/operator/source/animations/melee_1h/attack/critical_execution_01/operator__weapon__melee_1h__attack__critical_execution_01__e__8f__156x96.png`. No LFS payloads were fetched and no generated assets were changed in this implementation worktree.
- The user's persistent art checkout was not used as an implementation or validation surface; its current local asset changes remain preserved.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The user's publish blocker was caused by a canonical generated resource missing from the allowlist and transaction backup set. A broader legacy smoke also requires locally materialized LFS assets unavailable in this isolated worktree.
- Root cause / contributing factors: Publish allowlisting covered the compatibility resources under `game/actors/operator` but omitted the canonical SpriteFrames generated under `content/sprites/operator/runtime`. Resource backups keyed only by basename would also collide once the canonical file was included.
- Prevention / pipeline improvement: Added direct allowlist coverage and rollback coverage with two same-basename resources.
- Tooling / docs drift discovered: The publish transaction's expected output contract did not list the canonical runtime frames projection.
- Follow-up: fixed-in-scope
- What worked: Fixture-isolated publication and rollback smokes falsified both failure modes without touching the user's dirty art checkout.
