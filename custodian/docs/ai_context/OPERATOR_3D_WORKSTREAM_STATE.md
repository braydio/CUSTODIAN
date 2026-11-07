# Operator 3D: workstream state and review rules

Read this before touching the Meshy Operator 3D work, the playable 3D preview, or Dropbox visual-review handoffs. It records durable facts so later sessions don't re-derive them.

## Accepted source master

- File: `Character_output(5).glb`, SHA-256 `3004e9b5014450708bab80897a83ae676d27704321d2bc4cacdaf9ef1881c127`.
- Committed at the repo root as `OPERATOR_CHARACTER_MASTER_MESHY_DARK_V1.glb` (Git LFS) on branch `operator-character-master-v1`.
- It is the new-generation DARK Meshy Operator: 19,012 vertices, one mesh, one material, two textures, a 24-joint skin.
- The base model is a Meshy export. The motions appear to be Mixamo clips retargeted onto this rig, but that link is not verified from the files.

## Runtime master is not the 3D model

The runtime master is still the canonical 2.5D 128px Operator, `operator_2_5d_128`. See `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`. No 3D artwork is locked into runtime. The 3D candidate is developer-only and unapproved.

## Render facts

- Candidate scale is 80 px/m. Root is the feet origin at world (0,0,0).
- Horizontal root removal must be applied at object level (`armature.location`). Bone-level removal (`pose_bone.location`) is discarded at render time. This defect was found and fixed, and a regression test covers it.
- Object-fix renders are the valid evidence. Earlier bone-level renders are defective and kept only for comparison.

## Playable preview

- Commit `afb2ad911` on `operator-character-master-v1` is local and not pushed.
- Wrapper: `custodian/tools/debug/operator_3d_playable_preview.gd`. Scene: `custodian/scenes/debug/operator_3d_playable_preview_awakening.tscn`.
- `OperatorBodyPresenter.Owner.PREVIEW_3D_CANDIDATE` is appended to the owner enum. Existing values are unchanged.
- Smoke and motion-capture tests pass. Visual approval is still pending.
- The body is low-contrast (dark grey on a mid-grey floor). It is not transparent. That is an artwork and palette question for art review.
- Staged frames live in `custodian/.ai/operator_3d_animation_preview/` (git-ignored): 4,616 at 80 px/m and 320 at 50 px/m.

## Import and repo hygiene

- Godot headless import rewrites tracked `.png.import` sidecars. Restore them only by explicit path after checking the diff. Never use `git checkout .`.
- A new `class_name` script does not resolve until an editor or import scan has run. Use `preload` if needed.
- `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md` is modified by another workstream. Do not stage or revert it from 3D work.
- 3D work stays on `operator-character-master-v1`. Do not check out or merge `agent/operator-3d-animation-batch-executor-v1` for this work.

## Visual review handoff (Dropbox)

Publish through `custodian/tools/iteration/publish_review_artifacts.py`, using the `git-dropbox-sync:` remote. The default `dropbox:` remote is not configured here.

1. Run `--doctor --remote git-dropbox-sync`.
2. Build the bundle folder. Pass `--source` as an absolute path, and pass each file as `--artifact`.
3. Pass an explicit `--max-files`. The default is 12.
4. Run `--dry-run` and review the selection before any upload.
5. Use `--important` only for a subjective visual question that objective checks cannot settle, with a real `--reason`.
6. Retention defaults to `delete-after-review`. Tell the user, and add `--retain-after-review` only if they want to keep the evidence.

Run `--dry-run` before every upload. A check that omits `--dry-run` can upload by accident.
