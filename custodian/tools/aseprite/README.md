# CUSTODIAN Aseprite Tools

`operator_animation_workbench.lua` is the headless assemble/export bridge for
`operator anim`. It exports only manifest-whitelisted layers to ignored
workspace staging; it never writes canonical PNGs. Workbench `.aseprite` files
are disposable editing surfaces, not production assets.
V2 assembly consumes manifest-selected baseline or migration strips, explicit
timeline slots, independent document clocks, and hidden reference layers.

`operator_art_agent.lua` is the separate headless JSON bridge used by
`operator art`. It independently reads the Workbench V2 manifest, permits only
editable bindings and legal timeline/binding rectangles, and refuses reference
layers or manually translated cels. Pixel changes clone the cel image and
replace it inside one Aseprite transaction. V1 supports exact paint/erase,
integer Bresenham square strokes, same-layer copy, and region moves; Python
owns byte backups, SHA concurrency checks, rollback, and journaling. The bridge
renders through Aseprite's actual compositor and never publishes canonical
source.

V2 requests also require a nonce-bearing capability sidecar and strict protocol
handshake. `operator_art_agent_lib.lua` owns shared protocol constants. Clean
renders hide reference/guide/landmark/review layers. Semantic operations create
reserved `__ART_DRAFT__*` layers and never grant them Workbench publish
bindings; bake is explicit and remains confined to an editable binding.
The V2 pilot drives this same bridge through `ArtAgentService`; it does not use
a pilot-only Aseprite path or gain publication authority.

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

## Vigil run grip-pivot normalization

`normalize_vigil_run_pivot.lua` is calibrated only for the supplied 672×96,
seven-frame Vigil dagger run reference. It translates each 96×96 frame so the
measured grip anchors `(50,48)`, `(41,55)`, `(30,48)`, `(38,44)`, `(60,48)`,
`(42,51)`, and `(32,47)` land at the common frame-local pivot `(48,48)`.
Alpha is preserved and the script performs no scaling, rotation, filtering, or
resampling.

```bash
aseprite -b raw_vigil_run.png \
  --script-param output=normalized_7f_melee_vigil_dagger.png \
  --script tools/aseprite/normalize_vigil_run_pivot.lua
```

The current body presentation clock remains six frames. The seventh source
cell is retained in the normalized review strip and must not be silently
promoted into the runtime contract; canonical selection requires an explicit
body/frame-map decision.

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
