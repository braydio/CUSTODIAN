# Character3D VFX Pipeline V1 — Claude summary (WIP, gate 1 failing)

Workstream: `character3d-vfx-pipeline-v1` · Branch: `character3d-vfx-pipeline-v1`, stacked on `agent/operator-3d-workbench-intake-v1` (`fde279385`). Not pushed. Not landed.

## Status

Slice A is partly built. The acceptance gate for attachment geometry is not met, so Workbench inspection and Godot work are not started.

Built:
- `contracts/character_presentation_track.v1.schema.json`, `presentation_effect_registry.v1.json`, `operator_attachment_map.v1.json` (explicit mapping; weapon, muzzle and ejection sockets are marked unavailable, since the rig has no such nodes).
- `presentation/export_attachment_tracks.py`: Blender headless exporter. It binds the clip to the master rig as the sprite renderer does, samples the same instants, applies the same root-motion removal, and projects with an orthographic camera placed by the render formula. A built-in check confirms the root socket lands on the source pivot (128, 212) within 0.0004 px.
- `presentation/build_presentation_tracks.py`: builder and validator. It refuses unless the GLB, master, motion, sample count, canvas, pivot and root registration all match, writes per-direction tracks atomically, and derives foot-contact cues from foot height.
- Tracks written to the ignored art-checkout stage for Walking (25 samples) and Running (15 samples), across 8 directions each.

## Gate 1: attachment geometry (FAILED)

The Running overlay (`scratchpad/vfx/overlay_running_contacts_v2.png`) shows foot markers that float off the feet in several directions, notably NE, SE, W and SW. Re-exporting on the master rig changed nothing, so the rig binding is not the cause.

Likely cause, not yet verified: the staged frames come from `measure_objectfix` / `clean_objectfix`, which may have been adjusted after the raw camera render. If so, a plain camera projection will not match them. Next step is to compare one staged frame against the raw render at the same frame.

## Not done

- Gate 2 (contact timing and loop lifecycle) and gate 3 (Pursuit Frame reuse) are not run.
- Workbench VFX inspector: not built.
- Godot `character_vfx_presenter.gd`, smoke test and Slice B: not started.
- Dust artwork: not generated. The registry entry is a development marker only.
- Documentation (`CHARACTER3D_VFX_PRESENTATION_PIPELINE_V1.md`): not written.
