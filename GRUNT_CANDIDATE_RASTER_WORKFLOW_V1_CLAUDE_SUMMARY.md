# Grunt Candidate Raster Workflow V1

Workstream: `grunt-candidate-raster-workflow-v1`

Implemented and validated the plan-driven raster preparation workflow in `custodian/tools/iteration/raster_pipeline/`, with a pinned Grunt source plan at `custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json`. It extracts the four labeled directions, creates 64/72/80px body candidates using each existing converter mode (`crisp`, `balanced`, `clustered`), and writes deterministic JSON facts and a compact contact sheet to an ignored review workspace. Outputs include source/tool/config/output hashes, decoded pixel hashes, alpha/contact and silhouette diagnostics, palette/outlier/fringe facts, coordinates, and severity. Cleanup is report-only unless a separate reviewed approval names exact candidate hashes and before/after RGBA edits; cleaned files and reversible audit stay in the ignored output workspace.

The plan validates the hydrated source SHA and can recover the identical ZIP member into ignored scratch if the source is missing or an LFS pointer. The tracked source and all 12 old preview files remain unchanged. The dev-only Godot A/B harness can select the generated mode and height while preserving its old baseline comparison path and displaying invalid-image feedback. No runtime scene, collider, combat, animation, Asset V2, or production art replacement was changed.

Registration is reported against the actual Grunt actor placement: frame row 79, sprite offset -18px, centered 96px frame (`47.5px` center), and collision ground 13px. This yields actor ground projection 13.5px and a 0.5px residual, within the plan's declared 1px tolerance. The report does not describe the baseline as exact alignment.

## Evidence

- `python3 custodian/tools/validation/grunt_raster_pipeline_smoke.py`: PASS, synthetic and hydrated source, deterministic replay, cleanup gating, hash/path/symlink safety, and registration assertions.
- `python3 custodian/tools/validation/pixelart_colors_smoke.py`: PASS for all three converter modes; omitted flag retains legacy crisp behavior.
- `python3 custodian/tools/iteration/raster_pipeline/raster_pipeline.py --plan custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json --out .ai/grunt-candidate-raster-workflow-v1/out`: PASS, 36 candidates. Report records actor-ground residual `0.5`, severity `within_declared_tolerance`.
- `python3 custodian/tools/agent/check_ai_context.py --json`: PASS, zero findings.
- `python3 custodian/tools/agent/task_packet_index.py`: PASS after archiving the completed implementation packet.
- `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --json`: PASS, 43 selected / 43 passed / 0 failed / 0 timeout / 0 infrastructure errors; machine report at `.ai/grunt-candidate-raster-workflow-v1/changed-validation.json`.
- `git diff --check`: PASS.
- Godot editor import completed; `grunt_candidate_ab.tscn` then loaded headlessly with the generated crisp south 72px candidate and no script errors. Only the existing no-navigation warning for the comparison scene's two real Grunts appeared.

One initial fresh-worktree Godot scene launch failed before the import/class cache was initialized; editor import resolved it and the harness subsequently loaded. Godot created `.import` sidecars for the old preview PNGs during inspection; these generated sidecars were removed and are not part of the implementation.

## Human visual review

The compact A/B evidence was published through `publish_review_artifacts.py`, with delete-after-review retention:

- Manifest: `/CUSTODIAN/visual_review/grunt-candidate-raster-workflow-v1/20261019T101558Z/REVIEW_MANIFEST.json`
- Exact questions: “Which raster mode preserves material clusters best?” and “Do the candidate soles actually align with the original Grunt contact plane?”
- Cleanup after the decision is recorded: `python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/grunt-candidate-raster-workflow-v1/20261019T101558Z/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`

No aesthetic choice or approval was made by the implementation agent. The task packet records the human decision as separate from tooling completion.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: initial headless scene load preceded editor import; Godot produced disposable `.import` sidecars for baseline preview files.
- Root cause / contributing factors: empty generated import cache in the isolated worktree; editor inspection side effects.
- Prevention / pipeline improvement: initialize editor imports before fresh-worktree scene checks; remove generated sidecars from scope.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: objective source-backed measurements and a complete changed-file sweep established technical status without self-approving art.

## Next Handoff

- Next workstream: `review-grunt-candidate-raster-workflow-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f
- Refresh reason: none
- Next action: run the paired post-land independent review from a fresh reviewer context.
- Blockers or open questions: human visual decision remains open: which mode preserves material clusters best, and whether soles align with the original contact plane.
