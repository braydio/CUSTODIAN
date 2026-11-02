# Review: Bridged Falls Generated Region Lifecycle

Fresh-context independent code, architecture, and runtime review of BF1 on live main `520af6d832a4a79fe2fee110e3424ae1f1083dcd`. Reviewer provenance: `different-agent`. The reviewed implementation was not modified.

## Findings

### R0-01 — generated staging can wait forever after generator failure

- Class: `blocking_defect`
- Domain: `implementation`
- Acceptance affected: BF1 Acceptance 5 and 7 — generation failures must roll back and preserve the authored source, actor, and camera.
- Evidence: `GeneratedRegionLevel._await_level_data()` waits until `level_data_ready` arrives (`custodian/game/world/levels/generated_region_level.gd:111-117`). `ProcGenTilemap.generate()` returns without emitting that signal when the ProcGen owner or required floor/wall layers are missing (`custodian/game/world/procgen/proc_gen_tilemap.gd:1085-1101`); `_on_procgen_finished()` is the later emission path (`:1132-1170`). During route staging, the source and actor have already been frozen. With no completion signal, `stage_level_async()` never returns and `_rollback()` never restores them. The current focused smoke only forces a late missing-spawn failure.
- Disposition: `correction`
- Rationale: This is a confirmed violation of failure rollback acceptance that can strand gameplay indefinitely. A bounded correction must propagate generation failure and prove source/actor/camera restoration.

## Validation

- `generated_region_route_lifecycle_smoke.gd`: PASS after importing the fresh worktree. Its deliberately corrupted `MissingSpawn` control emitted the expected errors and exercised rollback; it did not test generator failure.
- `ash_bell_lower_quarter_route_smoke.gd`: PASS (`nodes=3 edges=6`).
- `procgen_intent_graph_smoke.gd`: PASS.
- `sundered_keep_route_graph_smoke.gd`: reproduced the recorded baseline failure, `Front Gate backtrack arrival guard was not armed`.
- `task_packet_index.py`: PASS; `validate_review_pairing.py`: PASS (50 paired review packets); `run_validation.py --changed --json --base origin/main`: PASS (2 packet/handoff checks, complete changed-file coverage); `git diff --check`: PASS.
- The first smoke attempt before import emitted broad missing class/import errors even though the script printed PASS. It was discarded as invalid evidence; the project import completed and the focused smoke then ran without parse errors. Focused smoke exit reported the existing controlled route errors and Godot shutdown resource-leak warnings.
- `git status` remains scoped to the review receipt, packet lifecycle/index, summary, and authorized correction/re-review packets; no runtime implementation paths were changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: A fresh worktree had no Godot import cache; the unimported smoke printed PASS after parse/runtime errors. The review packet also referred to a manifest ID that is not registered, so the first `run_validation.py --test` query rejected it.
- Root cause / contributing factors: The smoke wrapper does not treat all emitted Godot errors as failure, and the validation manifest has no generated-region lifecycle entry; the direct recipe command is the current executable proof.
- Prevention / pipeline improvement: Import a fresh Godot worktree before the first smoke, inspect error output as well as exit status, and use the direct smoke command until manifest registration is added by an authorized implementation task.
- Tooling / docs drift discovered: The inherited review packet named a landed manifest ID absent from `validation_manifest.json`; its focused-validation field now names the existing direct smoke command.
- Follow-up: bridged-falls-generated-region-lifecycle-review-corrections-1
- What worked: The focused missing-spawn negative control proved the current rollback seam; source inspection isolated the distinct missing-generation-completion path.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c

## Next Handoff

- Next workstream: bridged-falls-generated-region-lifecycle-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction after this review packet archives complete, then run its paired fresh-context review.
- Blockers or open questions: The Sundered Keep route graph smoke retains its reproduced baseline arrival-guard failure.
