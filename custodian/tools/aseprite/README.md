# CUSTODIAN Aseprite Tools

## Humanoid rigid-cutout source

Run `File > Scripts > new_humanoid_rig_source.lua` to create a 96×96,
single-frame RGBA source with the 20 exact part-layer names and a
`__GUIDES_DO_NOT_EXPORT` group. The guide includes the center, baseline,
shoulder, hip, and approximate generic joint locations. Adjust the real pivots
later in the Godot profile resource.

Keep each layer in the assembled character's absolute 96×96 position. Erase
everything except that layer's part; do not tightly crop or move the part to the
top-left.

Run `File > Scripts > export_humanoid_rig_atlas.lua`, select the output PNG,
and the script will write the fixed 480×384, 5×4 atlas without scaling,
filtering, palette conversion, flattening, or changing the source document.
Missing core body layers stop export. `weapon`, `cape`, `back_attachment`,
`front_attachment`, and `reserved` may be blank.

Use source names such as
`enemy_raider__rig_source__base__s__96.aseprite` and runtime names such as
`enemy_raider__rig_atlas__base__s__5x4__96.png`. Author south, north, and east;
west is optional when the Godot skin enables east-to-west mirroring.

## Operator modular alignment reference

`operator_pair_reference.lua` helps the alignment-repair conveyor
(`tools/operator/modular_alignment_repair.py`). While an editable source sheet
is open in Aseprite, run `File > Scripts > operator_pair_reference.lua` and the
script derives the paired sheet from the open filename (swaps
`lower_body`↔`upper_body`, maps `source/animations/` → `runtime/animations/`),
opens it, and pastes it into a new `pair_reference` layer.

The pasted layer is a reference layer: visible on canvas for lining up the
seam, but never exported into the saved PNG, so the partner cannot be baked
into the editable source. Install by copying into your Aseprite scripts folder
(`~/.config/aseprite/scripts/`).
