# Independent WB25-1 Review

## Findings

### R0-01 — Direction workflow projection reads the wrong workspace and stale creation hint

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: One structured projection truthfully reports coverage/workflow state; Workbench/session/workspace identity includes art generation; existing Workbench source/workspace/publication state owns workflow truth.
- Evidence: `custodian/tools/operator/operator_animation_targets.py:159` constructs the family directory without direction; lines 187/192 pass that directory to `_workspace_state`. `custodian/tools/operator/ui/service.py:453` places each manifest under the direction directory. A fresh fixture at `operator_2_5d_128/melee_1h/attack/fast_01/n/workbench.json` with a passed publish receipt returned workflow `NONE`, rather than `RUNTIME_VERIFIED`.
- Additional evidence: `_workspace_state` at lines 125-128 trusts `creation.state`, which is seeded as `NEW / UNSAVED` and is not rewritten on save. In an isolated creation fixture with a document hash different from its blank baseline, `animation_workbench.state(manifest, document)` returned `NEW / READY TO PUBLISH`, while `_workspace_state` returned `EDITING`.
- Disposition: correction
- Rationale: The promised workflow projection cannot observe real direction sessions, and fixing only the directory would still leave saved creation readiness false. This is a bounded correctness issue in workflow projection, not ingress orchestration or a UI redesign.
- Follow-up: `operator-2-5d-workbench-cockpit-foundation-review-corrections-1` and its paired fresh re-review.

## Verdict

Findings: 1 blocking defect, 0 material evidence gaps, 0 non-blocking issues, 0 optional improvements. No reviewed implementation was edited. Reviewer context: fresh. Reviewer provenance: different-agent. Reviewed main: `3c23a493992cdf8c20724d7d9c25c3235211c263` (implementation commit `7bca39ef53e22d1738641400e28b221e371cfd35` plus completion/landing merges).

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Verified acceptance and evidence

- Generation/path compatibility, plan parsing, and target-projection smokes passed on this review checkout.
- Inventory comparison proved exact equality with the completed audit's 69 live semantic family keys, exactly 1 authored canonical family, 68 remaining families/544 strips, and all four accepted profile/reference/source/design hashes. V1 legacy rank/priority/state values are preserved.
- The first canonical family retains eight direction leaves, 15 frames, 128x128 cells, unknown/null FPS; legacy/fallback/projected negatives and stale-reference smoke passed.
- `/home/braydenchaffee/Projects/CUSTODIAN/.ai/operator-ui-venv/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py` passed every Textual case, including matrix/tree identity, transient deletion stabilization, stale scan/session rejection, live preview ownership, and refresh coalescing. System Python initially skipped optional Textual cases; that run alone was not used as the UI proof.
- Correction/re-review authoring preflight and repository review-pairing validation passed. Review artifact `git diff --check` passed.
- `git diff 7bca39ef5^ 7bca39ef5 --check` passed. The diff through reviewed main has no changes to `custodian/game/`, Operator production runtime/generated resources, Operator source art, or `project.godot`.
- Reused the committed implementation smokes and canonical visual-contract/audit authority. The implementation's broad 19/19 report is a durable summary claim; this review obtained fresh narrow checks and independent fixture evidence rather than claiming a committed raw broad report exists.
- Moment Forge: not run — authoring UI/model review has no gameplay or presentation changes; accepted visual/profile decisions remain unchanged.

## Reproduction details

Both probes used `tempfile.TemporaryDirectory` and imported live landed modules. The first used `WorkbenchService.workspace(selection)` to place the direction manifest, then `project_targets` to inspect the same selection. The second wrote `creation.state = NEW / UNSAVED`, an `aseprite.last_synced_sha256` for blank bytes, and different saved document bytes; it compared the existing backend state result with the new projector classifier. Neither probe changed production or repository files.

## Persistent root synchronization

Synchronization is pending. The root is on main with three tracked import modifications:
- `custodian/content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png.import`
- `custodian/content/levels/awakening/04_locker_reliquary/awakening_locker_reliquary_underlay_1502x2048.png.import`
- `custodian/content/levels/awakening/05_dust_lung/awakening_dust_lung_underlay_1502x2048.png.import`

It also contains nine untracked Operator 2.5D reference `.import` files: eight direction sidecars and `operator_2_5d_rotation_lock_128.png.import`. Every byte was preserved; no reset, clean, stash, rebase, or branch switch was used.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: System Python omitted optional Textual checks on the first UI smoke run.
- Root cause / contributing factors: Textual dependencies live in the existing Operator UI virtual environment.
- Prevention / pipeline improvement: Reran the full UI smoke through the existing virtual environment; record the interpreter explicitly in future UI evidence.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Temporary isolated workflow fixtures exposed a gap beyond the existing green model/UI checks.

## Next Handoff
- Next workstream: operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction, validate it, and continue into its fresh paired re-review.
- Blockers or open questions: none for the correction; persistent root sync remains pending because the coordination checkout has preserved local import changes.
