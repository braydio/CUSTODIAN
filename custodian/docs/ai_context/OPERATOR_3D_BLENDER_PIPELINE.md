# Operator 3D: Blender pipeline notes

Read this before doing any Blender, GLB, or 3D-to-sprite work for the Meshy Operator.
Scope: how the Operator's rigged exports, turnaround renders, and sprite proofs were built, and what to avoid. This is evidence and process context. It does not approve any 3D artwork for production.

The scripts and renders live in the external proof workspace `~/Projects/.operator-3d-animation-proof/` (outside this repo). Paths below are relative to that workspace unless marked otherwise.

Date: 2026-11-07. Blender 5.2.3 LTS, Linux (Arch). Covers the Meshy Operator source, the rig and animation exports, the turnaround and sprite renders, and the playable-preview inputs.

## 1. Blender MCP: what was and was not used

- **Not used.** Every Blender step in this work ran as headless Blender through the CLI:
  `blender -b --factory-startup --python <script> -- <args>`. No `mcp__blender__*` tool was called, so nothing here is a verified MCP workflow.
- The MCP server's own instructions, which I read but did not exercise, say:
  - Blender must be running with the add-on enabled and connected.
  - `execute_blender_code` is a last resort; prefer the dedicated tools.
  - Set mode and active/selected objects before operators, and flush bmesh edits.
  - Return structured data, not print output.
  - Don't destructively change shared data without confirmation.
- If the MCP route is wanted later, the headless scripts below port directly into `execute_blender_code` calls, and the scene-inspection tools would replace the probe scripts.

## 2. Practical lessons from headless Blender 5.2

These were learned by failing first. Each one is a trap the next person will hit.

**Scene and import**
- `bpy.ops.wm.read_factory_settings(use_empty=True)` still leaves default objects behind (`Cube`, `Camera`, `Light`). Delete everything that existed before the import, and track the set difference.
- The glTF importer adds an `Icosphere` helper inside a `glTF_not_exported` collection. It is not source geometry. Hide it for render and measurement instead of deleting it.
- The Meshy master's `Armature` node has scale 0.01 (glTF units are centimetres). Bone-space values are about 100x the world values, so measure in world space (`obj.matrix_world`), or account for that scale.
- glTF Y-up becomes Blender Z-up as `(x, y, z) -> (x, -z, y)`. Mesh height is along glTF Y, not Z.
- Animation-only GLBs (no skin) import as empties named after the bones, with object-level `location` and `rotation_quaternion` curves. They do not import as armature bones.
- The decoded Meshy GLB uses `EXT_meshopt_compression`. This Blender build lacks the meshopt bridge library, so it fails with `Meshopt decoder library not found`. We worked around it with a decompressed copy (glTF-Transform `copy`, run after approval).

**Actions (Blender 5 API)**
- `act.fcurves` no longer exists. Walk `act.layers -> strips -> channelbags -> fcurves`.
- The data-path form for bone curves is `pose.bones["Name"].location`.

**Rest pose and comparisons**
- Earlier "21/24 bone mismatch" results were a comparison artifact. Bone matrices and empty world matrices are not in the same convention. Compare glTF-level data, or compare relative (rotation-angle or translation-length) invariants.
- A rotation and its inverse have the same angle, so angle-only checks cannot catch a sign flip. Always compare full matrices or positions too.
- Verify ground truth against a working file first. The skinning check that disagreed with Blender even on the known-good `running.glb` was a bug in the ground-truth math, not in the adapter.

**Cameras and rendering**
- For an orthographic camera at elevation, use `direction.to_track_quat("-Z", "Y")`. Using `"Z"` as the up axis rolls the camera 90 degrees at side azimuths.
- Eevee in Blender 5.2 is `BLENDER_EEVEE` (not `BLENDER_EEVEE_NEXT`). It renders headless with a transparent background (alpha 0).
- `World.use_nodes` is deprecated (removal planned in Blender 6.0), but it still works in 5.2.
- Rendering re-evaluates animation. A bone `location` change made in the script can be discarded at render time. Object-level transforms (`armature.location`) survive. This was the cause of the root-offset defect. Test the actual render output, not only the scene state.
- Use `world_to_camera_view` (from `bpy_extras.object_utils`) to check projections against the contract pixel. Our tests confirmed the origin projects to (64,106) at 128 px / 50 px/m, (128,212) at 256 px / 80 px/m, and (256,424) at 512 px / 80 px/m.

## 3. How the exports were built

**Source and proof**
1. Meshy Operator source: `model.meshy` decoded with the repo's `meshydecode` alias (`meshy_container.py`). The container's auth tag is skipped, so the output is not cryptographically authenticated.
2. Accepted master: `Character_output(5).glb` (SHA-256 `3004e9b5…`), 19,012 vertices, 24-joint skin, one mesh, one material, two textures. Committed as `OPERATOR_CHARACTER_MASTER_MESHY_DARK_V1.glb` (LFS) on `operator-character-master-v1`.

**Animation exports**
- The Running and Walking exports are skinned to the same master: 22 bone-targeted curves each, with rest TRS identical to the master (checked by glTF JSON, not by Blender objects).
- The nine motion-only clips (alert, casual_walk, dead, run_03, runfast, skill_01, skill_03, triple_combo_attack, unsteady_walk) carry 24-joint channels, with node names identical to the master.
- Adapter (`scripts/adapt_motion_to_master.py`): copies each motion animation's raw accessor bytes unchanged into the master's BIN chunk, rebases buffer views and accessors, and keeps node indices. Mesh, skin, and nodes are not touched. It writes a derived skinned GLB and verifies byte-identical values.
- Transparency test: the derived Running GLB reproduces the original's 24 pose matrices and all 19,012 evaluated vertices exactly (difference 0.0 at five frames).

**Render exports**
- Turnarounds (8 views, 5-degree elevation): `scripts/capture_turnaround.py`, one fresh Blender process per model.
- Sprite batch and scale probe: `scripts/render_operator.py` and `scripts/measure_render.py` (`--root-mode object` is the fixed default).
  - Camera: orthographic, 45-degree elevation, 50 or 80 px/m, root at the feet origin, 24 fps sampling from the authored range.
  - Direction convention: S=0, SE=45, E=90, NE=135, N=180, NW=225, W=270, SW=315 (camera azimuth; `A=0` views the character's front, which faces -Y).
- Alpha cleanup: `scripts/alpha_cleanup.py` (raw renders are never edited; derived copies have RGB zeroed where alpha is 0, and visible pixels are checked for exact identity).
- Viewports and placement: `scripts/compact_viewports.py`, with destination = source + target_pivot - source_pivot. Nothing is resampled, and labels stay outside the cells.
- Aseprite export: `scripts/export_aseprite.py` (rows = 8 directions, columns = frames, no labels).

**Preview staging**
- `scripts/stage_godot_preview.py` writes the validated cleaned frames into `custodian/.ai/operator_3d_animation_preview/` (git-ignored) as 4,616 cells at 80 px/m and 320 at 50 px/m, with metadata and per-cell hashes.

## 4. Known open items

- The glTF ground-truth positional check disagrees with Blender even on the known-good Running file. The rotation-level check passes for all nine motions. Joint positions are verified only through the transparency test and the render checks.
- The triple-combo and dead root-motion audits are numerical and complete. Their artistic readability has not been reviewed.
- Source artwork contrast (dark body on a mid-grey floor) is a palette question for art review, not a rendering fix.

## 5. Key scripts

| Purpose | Path (under `operator_running_scale_probe_v1/scripts/` unless noted) |
|---|---|
| Decode, adapt, verify | `adapt_motion_to_master.py`, `verify_derived_pose.py`, `dump_pose.py` (sprite-batch scripts folder) |
| Turnaround | `capture_turnaround.py` (sprite-batch folder) |
| Render | `render_operator.py` (batch), `measure_render.py` (probe, object-root mode) |
| Root audit and regression | `root_motion_audit.py`, `test_root_removal_regression.py` |
| Cleanup and viewports | `alpha_cleanup.py`, `compact_viewports.py`, `export_aseprite.py` |
| Preview staging | `stage_godot_preview.py` |
| Godot tests | `custodian/tools/validation/operator_3d_playable_preview_smoke.gd`, `..._motion_capture.gd` |
