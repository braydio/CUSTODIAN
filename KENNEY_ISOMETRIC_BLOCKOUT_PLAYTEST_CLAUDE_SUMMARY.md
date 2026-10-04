# Kenney Isometric Blockout Playtest — Codex Summary

K3D-1P adds a real-Operator walkaround for the reviewed native/Kenney sample while keeping K3D-1's deterministic capture rig and visual layout intact. The authored dev scene is ready for the user's presentation judgment.

## What changed

- Extracted the existing K3D-1 backdrop, route/anchor guides, native blockout, Kenney floor sequence, props, scales, positions, and z-order into `kenney_isometric_blockout_presentation.gd`; both the original capture rig and new walkaround call this builder.
- Added the authored dev level, standalone `GameRoot` wrapper with the real Operator/controller/gameplay camera and normal support systems, HUD-safe mode label, and `1`/`2`/`Tab` controls.
- Kept the level's only collision as four capsule rails around the neutral `Rect2(-2600, -4300, 5200, 4650)` envelope. No Kenney/native geometry gained collision or navigation authority.
- Added a focused integration smoke, validation-manifest owners, Asset V2 consumer metadata for the existing two families, file-index/current-state entries, and the K3D roadmap/handoff update. No asset pixels, family states, runtime paths, or production boot settings changed.

## Evidence

- `kenney_isometric_blockout_playtest`: passed (1 selected, 1 passed).
- `kenney_isometric_blockout_feasibility`: passed (1 selected, 1 passed); the old scene, viewport, capture camera, metrics API, and evidence files remain untouched.
- GUI sanity: standalone scene spawned at Forum South; W/S movement and gameplay-camera follow worked across the Dais/South Reach route; native/Kenney changed with `1`, `2`, and `Tab` while moving. The initial mode label overlapped the HUD, so it was moved clear; the corrected readout was visible.
- A normal NavigationSystem startup warning reports that no floor TileMap was found. That is expected for this presentation-only sample: the wrapper keeps the required support system, while its `NavigationRoot` remains empty and movement uses the real Operator controller.
- `git diff --check` and the managed task-packet index check pass. The LFS/import preflight found no pointer-only inputs; all 16 existing 256×512 Kenney runtime textures loaded in the smoke.

## Deferred

Human-owned A/B judgment remains open. The user should assess Operator scale, route readability while moving, depth/occlusion, gameplay-camera compatibility, and CUSTODIAN fit before K3D-2 is refreshed. K3D-2 remains human/planning gated; this work makes no art-direction decision.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first clean-worktree smoke lacked Godot's generated global-class cache, and the first GUI pass exposed a HUD/readout overlap. Both were fixed before closeout. An earlier empty source-library claim also held the shared asset-pipeline lock; its branch was removed only after verifying it had no unique commits outside `origin/main`.
- Root cause / contributing factors: The new test initially skipped Godot's editor class scan; the label started inside the HUD footprint; workstream locks remain active until the claimed branch is closed.
- Prevention / pipeline improvement: Mark the playtest validation `needs_import: true`, place the readout outside the HUD area, and verify ancestry before removing an abandoned empty workstream branch.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: The focused smokes protected capture and playtest contracts without a broad validation sweep.

## Next Handoff

- Next workstream: `kenney-orthographic-3d-feasibility`
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: K3D-2 must use the user's walkaround judgment of native versus Kenney presentation with the real Operator and gameplay camera.
- Next action: Have the user run the standalone playtest, record scale/readability/depth/camera/CUSTODIAN-fit observations in the authoring chat, then refresh K3D-2 from current main.
- Blockers or open questions: none for implementation; K3D-2 remains gated on the human judgment and planning refresh.
