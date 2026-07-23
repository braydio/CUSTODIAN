# Asset Layout and Naming Convention

Last updated: 2026-07-22

## Scope

This convention covers current Godot runtime assets in `res://content/` with a concrete migration applied to operator animation textures referenced by:

- `res://game/actors/operator/operator.tscn`

## Standard Layout

```text
content/
  _aseprite/            # ALL .aseprite/.ase source files, mirroring content tree
  _pipeline/            # staged intake only, never read by runtime scenes
  metadata/             # shared authored/generated metadata and game32 sidecars
  runtime/              # generated runtime catalogs/packs not owned by sprites/tiles
  sprites/
    <entity>/
      runtime/            # files directly loaded by scenes/resources
        <layer>/
          <action_group>/
      source/             # non-aseprite editable source files (.xcf, .psd, .gif)
      archive/            # deprecated but retained files not used by runtime
    environment/
      props/
        <prop_id>/
          runtime/
            body/
    enemies/
      <enemy>/
        runtime/
          <layer>/
            <action_group>/
    raw/
  tiles/
    <feature>/
      runtime/          # tile art directly consumed by TileSets/scripts
      source/           # oversized/reference art and raw exports
      legacy/           # retained generated/history copies
  ui/
  raw/
  unregistered/         # imported art quarantine; not runtime authority
```

For the full content-root domain map, see `res://content/README.md`.

## Content Root Domain Rules

- Do not add new runtime assets loose at `res://content/`, `res://content/sprites/`, or `res://content/tiles/`.
- Runtime art belongs in the owning feature domain, usually `sprites/<owner>/runtime/`, `sprites/environment/props/<prop_id>/runtime/`, `tiles/<feature>/runtime/`, `props/<set>/`, or a documented generated runtime pack under `runtime/`.
- Source and master art belongs in `source/`, `masters/`, or `content/_aseprite/` for `.aseprite` / `.ase` files.
- `_pipeline/` is ingest staging/history and should not be referenced by runtime scenes, resources, or scripts.
- `unregistered/` is quarantine. Promote assets out of it only by assigning an owning runtime/source domain, updating references/manifests, and verifying Godot import paths.
- `legacy/` folders are historical or compatibility surfaces. Keep them local to the feature they explain, and document why they are retained in a local README when possible.

## Persistent Runtime-Ready Drop

Use `custodian/asset_drop/runtime_ready/inbox/` for new assets that are already ready for
Godot import. This intake lives outside `res://` and maps mirrored inbox paths into
`res://content/`:

```text
custodian/asset_drop/runtime_ready/inbox/tiles/roads_paths/runtime/roads/new_tile.png
-> res://content/tiles/roads_paths/runtime/roads/new_tile.png
```

Run a dry-run before applying:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
```

Use a same-name `.runtime.json` sidecar for explicit routing when the inbox path cannot
express the correct owner. The router archives processed sources and writes receipts.
It rejects different existing targets unless `--replace` is supplied.

Do not use this generic path for sprite sheets that require normalization, compatibility
outputs, or `SpriteFrames` rebuild hooks. Those belong in
`res://content/sprites/_pipeline/inbox/`.

## Aseprite Source File Convention

**All `.aseprite` and `.ase` source files must live under `content/_aseprite/`.**

This is a consolidated source tree that mirrors the content hierarchy:

```text
content/
  _aseprite/
    sprites/
      operator/source/foo.aseprite
      operator/dev/bar.aseprite
      effects/source/hit_spark/hit-spark-1.aseprite
      environment/foliage/tree_verdent_96x128.aseprite
      items/faded_instinct.aseprite
    tiles/interiors/runtime/prop_sheet.aseprite
    tiles/interiors/source/props_cables_01.aseprite
    ui/terminal/source/Icons_Tilesheet.aseprite
    props/ruins/portal_arrival.aseprite
```

When you save a new `.aseprite` file anywhere under `content/`, it is automatically
swept into the mirrored path under `_aseprite/` by one of:
- **Pre-commit hook** (active — runs `git commit` in the repo root)
- **`watch_aseprite.sh` daemon** (optional — instant move on save via inotify)

The runtime PNG exports stay in their original location. The `.aseprite` source is
always findable at `content/_aseprite/<original-relative-path>`.

### Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| `tools/aseprite/sweep_aseprite.sh` | One-time cleanup: move all existing `.aseprite` files into place | `./tools/aseprite/sweep_aseprite.sh --apply --git` |
| `tools/aseprite/watch_aseprite.sh` | inotify daemon: auto-move on save (requires `inotify-tools`) | `./tools/aseprite/watch_aseprite.sh --daemon` |
| `.githooks/pre-commit` | Auto-sweep staged `.aseprite` files before every commit | Active when `core.hooksPath` is set |

### Exceptions

Third-party addon assets (e.g. `addons/fightengine/demo/Assets/Aseprite/*.ase`)
are not moved — they belong to their respective packages.

## Naming Rules

- New sprite sheets use `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png`.
- Enemy actors use `sprites/enemies/<owner>/runtime/<layer>/<action_group>/<canonical_filename>.png`; the enemy domain is part of the canonical path and enemy outputs must not be written loose under `sprites/<owner>/`.
- Allied non-Operator actors currently use `sprites/<owner>/runtime/<layer>/<action_group>/<canonical_filename>.png`, with `sprites/allies/<owner>/...` retained as a compatibility surface during migration.
- Use owner names such as `operator`, `enemy_grunt`, `drone`, `fallen_star_katana`, or `hit_spark`.
- Use layer names such as `body`, `weapon`, `fx`, `shadow`, or `mask`.
- Use action groups such as `locomotion`, `melee`, `defense`, `ranged`, `reaction`, `death`, `impact`, or `interaction`.
- For in-world props, use `environment/props/<prop_id>/runtime/<layer>/` and the `interaction` action group for open/close/activate/deactivate-style animations.
- Use direction codes `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`, or `omni`.
- Use zero-padded variants where order matters: `fast_01`, `fast_02`, `light_01`, `heavy_01`.
- Use lowercase snake_case only.
- Intake manifests in `_pipeline/inbox/` should match their PNG basename.

Examples:

```text
operator__body__locomotion__walk__n__8f__96.png
operator__body__melee__fast_01__n__6f__96.png
operator__weapon__melee__fast_01__n__6f__96.png
operator__fx__melee__fast_01__n__6f__96.png
enemy_grunt__body__reaction__stagger__s__5f__96.png
hit_spark__fx__impact__default__omni__4f__64.png
command_terminal__body__interaction__activate__omni__4f__48.png
```

Legacy names remain valid only as compatibility targets for existing scenes/resources. Do not use legacy names for
new source art unless a manifest also writes the canonical asset.

### Modular Operator Naming

Modular Operator source sheets specialize the canonical pattern as:

```text
operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png
```

Prefer `modular_lower_body`, `modular_upper_body`, `modular_upper_fx`, `modular_wardrobe_cape`,
`modular_combined_body`, `modular_sidearm`, or `modular_head` for the layer. Use an explicit loadout such as `unarmed`,
`sidearm`, or `ranged_2h`, followed by the action such as `block_loop_01`, `enter_block_01`, or `stance_01`.
Legacy short names and the earlier ranged token ordering remain accepted as compatibility input, but new art
should use the explicit loadout/action order.

`modular_head` specializes the loadout token as a cosmetic head profile, for example
`operator__modular_head__hooded__idle_01__s__5f__96.png`. Head profiles remain independent of combat loadout.

## Runtime Replacement Rule

Runtime asset folders represent the active mapped version of each sheet. If a corrected or retimed sheet replaces
the same owner/layer/action/variant/direction, the old runtime PNG and `.import` file should be removed after the
new sheet is ingested, imported, wired, and verified.

Do not remove `_pipeline/archive/`, source art, normalized previews, or logs during this cleanup. Those preserve
history and debugging context. Also do not remove intentional alternate variants such as `heavy_02`, `alt`, or
weapon-specific variants unless the mapping has explicitly superseded them.

## Duplicate Handling Rule

Exact duplicate bytes are a migration signal, not deletion approval. Before removing one side of a duplicate group,
identify the canonical runtime consumer and scan for all `res://` references.

Treat these duplicate classes as intentionally retained unless a task-specific migration says otherwise:

- `_pipeline/archive/` and `_pipeline/normalized/` copies kept for ingest history and debugging.
- `source/`, `masters/`, and `_aseprite/` files kept as authoring inputs.
- `legacy/` generated copies kept for reproduction or compatibility.
- Compatibility runtime paths still referenced by scenes, scripts, resources, or manifests.

Use the read-only audit before cleanup:

```sh
python3 custodian/tools/validation/content_asset_audit.py --limit 20
```

## Operator Runtime Assets (Linked)

These files are now the canonical runtime-linked operator animation textures:

```text
res://content/sprites/operator/runtime/attack/op_attack_combo_01.png
res://content/sprites/operator/runtime/attack/op_attack_combo_02.png
res://content/sprites/operator/runtime/attack/op_attack_combo_03.png
res://content/sprites/operator/runtime/attack/op_attack_combo_04.png
res://content/sprites/operator/runtime/attack/op_attack_combo_05.png
res://content/sprites/operator/runtime/attack/op_attack_combo_06.png
res://content/sprites/operator/runtime/attack/op_attack_combo_07.png
res://content/sprites/operator/runtime/attack/op_attack_combo_08.png
res://content/sprites/operator/runtime/attack/op_attack_combo_09.png
res://content/sprites/operator/runtime/attack/op_attack_combo_10.png
res://content/sprites/operator/runtime/attack/op_attack_combo_11.png
res://content/sprites/operator/runtime/attack/op_attack_combo_12.png
res://content/sprites/operator/runtime/attack/op_attack_combo_13.png
res://content/sprites/operator/runtime/idle/op_idle_right_sheet.png
res://content/sprites/operator/runtime/idle/op_idle_alt_sheet_a.png
res://content/sprites/operator/runtime/idle/op_idle_alt_sheet_b.png
res://content/sprites/operator/runtime/idle/op_idle_up_sheet_a.png
res://content/sprites/operator/runtime/idle/op_idle_up_sheet_b.png
res://content/sprites/operator/runtime/idle/op_idle_up_sheet_c.png
res://content/sprites/operator/runtime/move/op_dash_sheet.png
res://content/sprites/operator/runtime/move/op_walk_down_sheet.png
res://content/sprites/operator/runtime/move/op_walk_right_sheet.png
res://content/sprites/operator/runtime/move/op_walk_up_sheet_a.png
res://content/sprites/operator/runtime/move/op_walk_up_sheet_b.png
```

## Operator Source Files (Moved)

Moved to `res://content/sprites/operator/source/`:

- `Sprite-0001.aseprite`
- `Sprite-0003.aseprite`
- `Sprite-0003.gif`
- `custodian_idle_up.aseprite`
- `idle-alternative-spritemap.aseprite`
- `idle_up_alternative_spritesmap.aseprite`
- `walk_right_custodian.aseprite`
- `white-sprite-idle.aseprite`

## Notes

- Phase-2 cleanup completed: non-runtime/non-source operator files were moved to `res://content/sprites/operator/archive/`.
- One compatibility exception remains at top-level:
  - `res://content/sprites/operator/sprite-map-custodian-red.png`
  - Kept in place because it is referenced by `res://game/actors/custodian/custodian.tscn`.
- Intake assets staged in `res://content/sprites/_pipeline/` are not runtime authority and should be treated as
  temporary ingest inputs only.

## Effects Runtime Assets (Linked)

Combat impact effects now follow the same runtime/source split:

```text
res://content/sprites/effects/runtime/hit_spark/hit_spark_4f_64.png
res://content/sprites/effects/runtime/block_spark/block_spark_4f_128.png
res://content/sprites/effects/source/hit_spark/*
res://content/sprites/effects/source/block_spark/*
```

Runtime scenes:

- `res://game/actors/effects/impact_spark.tscn` (`AnimatedSprite2D` + `impact_spark_frames.tres`, uses all 4 hit-spark frames)
- `res://game/actors/effects/block_spark.tscn` (`AnimatedSprite2D` + `block_spark_frames.tres`, uses first 2 of 4 block-spark frames)

## Environment Prop Runtime Assets (Linked)

World props use the environment prop domain rather than loose files at `res://content/sprites/`:

```text
res://content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__activate__omni__4f__48.png
res://content/sprites/environment/props/portal_ring/runtime/fx/portal_ring__fx__interaction__activate_01__omni__12f__161.png
```

Runtime scenes/scripts:

- `res://game/actors/terminal/command_terminal.gd` prefers the canonical `command_terminal` asset names, falls back to the current `computer_terminal` compatibility sheets, and reuses the pickup sheet in reverse for redeploy.
- `res://game/world/procgen/portal_teleporter.gd` slices portal-ring idle, activation, and arrival FX strips from the prop-owned `portal_ring/runtime/fx/` directory.

## Enemy Drone Runtime Additions

Runtime-linked reaction/attack-readability strips:

```text
res://content/sprites/enemies/drone/runtime/idle/drone_idle.png
res://content/sprites/enemies/drone/runtime/attack/drone_firing.png
res://content/sprites/enemies/drone/runtime/reaction/drone_hit.png
res://content/sprites/enemies/drone/runtime/reaction/drone_stagger.png
res://content/sprites/enemies/drone/runtime/attack/drone_attack_windup.png
```

These are currently registered into drone `SpriteFrames` at runtime by:

- `res://game/actors/enemies/enemy.gd`

## Assets Directory Audit Snapshot

Current `res://content/` file counts:

- `png`: 118
- `import`: 118
- `aseprite`: 7
- `gif`: 1
- `xcf`: 2
- `tres`: 3

Immediate cleanup target:

- Operator legacy variants in `res://content/sprites/operator/` not referenced by runtime scenes can be moved to `archive/` after final animation lock.
