# enemy_scout humanoid cutout skin

DEV/authoring scaffold. Real sources are 96×96, one frame, transparent, with
these exact layers:

head, torso, pelvis, back_attachment, front_attachment, upper_arm_back, forearm_back, hand_back, upper_arm_front, forearm_front, hand_front, thigh_back, shin_back, foot_back, thigh_front, shin_front, foot_front, weapon, cape, reserved

Export with `tools/aseprite/export_humanoid_rig_atlas.lua` after creating or
checking the source with `tools/aseprite/new_humanoid_rig_source.lua`. Each
complete 96×96 layer image is copied to its fixed cell in a 480×384 (5×4)
atlas; never crop, scale, filter, or palette-convert the parts.

Expected runtime atlases:

- `enemy_scout__rig_atlas__base__s__5x4__96.png`
- `enemy_scout__rig_atlas__base__n__5x4__96.png`
- `enemy_scout__rig_atlas__base__e__5x4__96.png`
- `enemy_scout__rig_atlas__base__w__5x4__96.png`

Assign S/N/E to `enemy_scout_humanoid_rig_skin.tres`. W is optional: if absent
and mirroring is enabled, Godot mirrors the complete east visual root. An
authored W atlas disables mirroring.

The rigid rig reuses pivot motion without deforming pixels. Perspective-extreme
and high-impact poses should use replacement part cells or an authored
full-body fallback strip. Gameplay collision and timing never belong to limbs.
