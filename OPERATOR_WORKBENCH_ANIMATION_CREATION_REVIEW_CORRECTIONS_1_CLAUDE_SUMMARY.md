# Operator Workbench Animation Creation Service Correction

## Outcome

Fixed R0-01 in the shared Workbench publication guard. Creation-layer identity validation now derives the trusted semantic identity from the selected animation and each binding's own layer, so the creation path no longer reads an `identity` local that was only initialized by the adopted-FX branch.

Extended the Aseprite-backed creation smoke to publish both full-body and modular sessions through `WorkbenchService.publish`, the same service boundary used by OPUI and the CLI. The fixture intercepts the dedicated art-checkout boundary to execute the real Workbench transaction against a disposable repository; source export, CREATE collision checks, timing sidecars, runtime-copy projection, transaction journal, and manifest normalization use the production backend. Existing separate art-worktree and import/runtime checks continue to exercise their production paths.

Negative cases mutate owner, layer, semantic identity, source path, and source-contract path. Each is rejected before the guarded publisher is invoked, and the saved document and canonical source state remain intact. A target created after the service publish preview is also preserved on rejection. Both successful templates produce source/runtime pixel-identical layers, normalize to source-backed sessions, and appear as DORMANT in browser discovery.

## Evidence

- `operator_animation_workbench_smoke.py`: passed real full-body and modular service publication, invalid-contract refusals, target-after-preview refusal, saved-document preservation, exact source/runtime pixel equality, manifest normalization, timing, and DORMANT discovery.
- `operator_workbench_ui_smoke.py`: passed service projections and discovery; optional Textual pilot skipped because Textual is not installed.
- `operator_workbench_mirror_publish_smoke.py`: passed CREATE/REPLACE, mirror, collision, import metadata restore, and rollback.
- `operator_art_worktree_smoke.py`: passed real isolated art-checkout lifecycle; its local fixture exercised retries while fixture `main` advanced.
- `operator_cli_publish_boundary_smoke.py`: passed.
- Godot import preflight: passed; no checked-out LFS pointers.
- Runtime SpriteFrames import smoke: passed (588 imports).
- Modular layer Godot smoke: passed after changed-file validation generated the fresh worktree script-class cache. The first attempt before that warm-up emitted cache-related parse/load errors and was stopped.
- Strict animation contract report: passed; 63 expected, 60 present, zero required missing, three optional absent.
- `run_validation.py --changed --json`: passed, 8 selected checks, zero failures.
- Python compile checks and `git diff --check`: passed.

The service fixture mocks only the outer art-checkout/landing orchestration and downstream importer/resource builder commands; it runs the actual service guard and Workbench transaction. The separate art-worktree, import-preflight, SpriteFrames, and Godot modular checks provide evidence for those production stages.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first standalone modular Godot smoke ran before the fresh worktree had a generated script-class cache.
- Root cause / contributing factors: New worktrees need the changed-file validation warm-up before this standalone script can resolve project classes.
- Prevention / pipeline improvement: Run the prescribed changed-file sweep before standalone class-dependent Godot checks.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: The new service-level fixtures reproduced and then closed the precise UI/CLI publication boundary gap.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Next Handoff
- Next workstream: review-operator-workbench-animation-creation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Auto-dispatch the paired cycle-1 re-review; resume downstream cockpit/UX planning only after it passes.
- Blockers or open questions: Optional Textual interactive pilot remains unrun because the dependency is absent.
