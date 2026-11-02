# WB25-1 R0-01 Independent Re-review

## Findings

R0-01 is **fixed**. No blocking defects, material evidence gaps, non-blocking issues, or optional improvements remain in this bounded correction review.

- Finding ID: R0-01
- Original class/domain: blocking_defect / implementation
- Affected acceptance: Each canonical direction projects its actual Workbench workflow; current saved creation readiness comes from backend document evidence.
- Disposition: no_action
- Rationale: Fresh isolated probes place manifests through `WorkbenchService.workspace()`, reproduce both original failures against the landed correction, and prove the required states and isolation. No new R1 finding was identified.

## Verdict and provenance

Passed against main `26808a029fb80115fa847fc3d378c345075e9a03`; correction commit `a49f7c2802419203c438e9ca89f0fac0726d79e1`.
Reviewer context: fresh. Reviewer provenance: different-agent.
Review workstream: `review-operator-2-5d-workbench-cockpit-foundation-review-corrections-1`.
Reconstructed from the archived WB25-1 and correction packets, prior review receipt/summary, correction summary, active migration roadmap, and live landed code.
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Acceptance evidence

- `operator_animation_targets.py:182-184` computes workflow separately for every direction beneath its generation/family workspace. Fresh fixtures used the service-owned path for all eight directions. A passed publish receipt gives `RUNTIME_VERIFIED` only to the populated direction; absent siblings stay `NONE`.
- A family-parent manifest and the actual legacy service workspace (`<workspace>/melee_1h/attack/fast_01/n`, without a `legacy_96` directory) do not change any 2.5D leaf. Editing one direction's manifest/document leaves siblings unchanged.
- `operator_animation_targets.py:128-139` calls the existing `animation_workbench.state()` read-only classifier. A current saved document different from its blank SHA baseline gives backend `NEW / READY TO PUBLISH` and projection `READY_TO_PUBLISH`; unchanged or absent documents give `EDITING`.
- An absent document remains `EDITING` even when the persisted creation hint falsely says `NEW / READY TO PUBLISH`. The persisted hint therefore cannot substitute for current document evidence.
- Independent mutations of either recorded canonical profile SHA or normalized reference SHA force `STALE_REFERENCE` across both published and saved creation workspaces. The final override at `operator_animation_targets.py:205-206` preserves precedence.
- Every independent projection call compared SHA-256 snapshots of all fixture files before/after. No files appeared, disappeared, or changed; manifests/documents remain byte-exact and no manifest upgrade path is called.
- Fresh inventory comparison equals all 69 production-reachable audit family keys: exactly 1 authored canonical family, 68 missing canonical families, and 544 remaining baseline strips. First-family geometry remains eight directions, 15 frames, 128x128 cells with unknown/null FPS.
- Accepted profile authority remains `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`. Direct bytes retain normalized reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`, first source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, and design-lock SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.
- Diff from the correction parent through reviewed main contains no `custodian/game/`, `project.godot`, Operator source art, or production runtime resource changes. The unrelated landed queue-hardening merge was outside this review's implementation scope.

## Validation

All required focused checks passed:

- `python3 custodian/tools/validation/operator_animation_targets_smoke.py`
- `python3 custodian/tools/validation/operator_animation_plan_smoke.py`
- `python3 custodian/tools/validation/operator_asset_schema_smoke.py`
- `/home/braydenchaffee/Projects/CUSTODIAN/.ai/operator-ui-venv/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py` — all Textual pilot cases executed, including browser races and matrix/tree selection identity.
- Independent temporary-directory probes described above; exact inventory/hash comparison.
- `git diff --check` and `git diff a49f7c280^ HEAD --check`.

The focused lifecycle report is ephemeral at `/tmp/wb25-r01-review-validation.json`; this committed summary and archived correction receipt are the durable evidence. No broad sweep was required by this review packet.
Moment Forge: not run — authoring model/UI correction has no gameplay or rendered-presentation change. Visual review: none.

## Persistent root synchronization

Synchronization is pending: root `main` is behind `origin/main` and contains three tracked modifications:

- `custodian/content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png.import`
- `custodian/content/levels/awakening/04_locker_reliquary/awakening_locker_reliquary_underlay_1502x2048.png.import`
- `custodian/content/levels/awakening/05_dust_lung/awakening_dust_lung_underlay_1502x2048.png.import`

Nine untracked files also block sync: `custodian/content/sprites/operator/reference/operator_2_5d/directions/{n,ne,e,se,s,sw,w,nw}.png.import` and `custodian/content/sprites/operator/reference/operator_2_5d/operator_2_5d_rotation_lock_128.png.import`.
All bytes are preserved. The safe lifecycle sync must report pending; no reset, clean, stash, rebase, branch switch, or forced update is authorized.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Graph discovery had stale persistent-root metadata and no indexed nodes for the new review worktree.
- Root cause / contributing factors: The isolated checkout was not covered by the existing graph.
- Prevention / pipeline improvement: Used focused landed diff and exact-symbol reads after graph-first discovery; used the existing Textual interpreter on the first UI run.
- Tooling / docs drift discovered: none affecting acceptance
- Follow-up: none
- What worked: Service-owned workspace paths and full fixture-tree snapshots falsified direction/generation/readiness defects without art or implementation mutation.

## Next Handoff
- Next workstream: operator-2-5d-workbench-ingress
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: WB25-2 must consume accepted WB25-1 APIs/state model and this passed R0-01 correction re-review before becoming claimable.
- Next action: Open the authoring chat and refresh the existing WB25-2 packet in place using this summary and workstream ID.
- Blockers or open questions: WB25-2 planning refresh; persistent-root synchronization separately remains pending because the coordination checkout contains preserved local import changes.
