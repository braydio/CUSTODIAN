# Sprite Pipeline

Repo-native sprite ingest for the active Godot runtime.

## Status

- Intake path is `res://content/sprites/_pipeline/`.
- Ingest script is `custodian/tools/pipelines/ingest.py`.
- Operator curated body changes can trigger the live `SpriteFrames` rebuild through
  `custodian/tools/pipelines/update_operator_curated_resources.gd`.
- Enemy, weapon, effects, vehicle, and turret outputs are written directly into the
  runtime-owned sprite domains already used by the game.

## Why This Exists

The project already has multiple live sprite consumers:

- operator body and overlay strips feeding `operator_runtime_frames.tres`,
  `operator_weapon_frames.tres`, and `operator_melee_overlay_frames.tres`
- weapon-owned animation strips in `content/sprites/weapons/`
- enemy runtime strips in `content/sprites/enemies/`
- direct effect strips in `content/sprites/effects/runtime/`

The pipeline should feed those consumers directly instead of creating a second asset tree.

## Intake Contract

Drop a `PNG` plus a sidecar `JSON` manifest with the same basename into:

```text
custodian/content/sprites/_pipeline/inbox/
```

After a successful ingest:

- debug previews land in `_pipeline/normalized/`
- result logs land in `_pipeline/logs/`
- processed inputs move to `_pipeline/archive/`

## Manifest Schema

Required fields:

```json
{
  "source": "sheet.png",
  "mode": "copy | strip | grid",
  "outputs": [
    {
      "path": "weapons/fallen_star_katana/animations/example.png",
      "layout": "copy | horizontal_strip | vertical_strip"
    }
  ]
}
```

Mode rules:

- `copy`: pass the source image through as a single-frame output
- `strip`: source is a horizontal strip; requires `frame_size`
- `grid`: source is a grid; requires `frame_size`, `columns`, and `rows`

Output rules:

- `path` is always relative to `res://content/sprites/`
- `select` may be omitted to use all parsed frames
- `select.type = "range"` uses `start` and `count`
- `select.type = "indices"` uses an explicit `indices` array
- `transform` is optional and only used when a specific asset recipe really needs resize/canvas work

## Canonical Naming

New sprite sheets should use the canonical filename pattern:

```text
<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png
```

Examples:

```text
operator__body__locomotion__walk__n__8f__96.png
operator__body__locomotion__sprint__se__8f__96.png
operator__body__locomotion__dodge__w__6f__96.png
operator__body__locomotion__roll__nw__8f__96.png
operator__body__melee__fast_01__n__6f__96.png
operator__weapon__melee__fast_01__n__6f__96.png
operator__fx__melee__fast_01__n__6f__96.png
enemy_grunt__body__reaction__stagger__s__5f__96.png
hit_spark__fx__impact__default__omni__4f__64.png
```

Fields:

- `owner`: asset owner, such as `operator`, `enemy_grunt`, `drone`, `fallen_star_katana`, `hit_spark`
- `layer`: `body`, `weapon`, `fx`, `shadow`, or `mask`
- `action_group`: `locomotion`, `melee`, `defense`, `ranged`, `reaction`, `death`, `impact`
- `variant`: specific animation, such as `walk`, `fast_01`, `block_enter`, `hit_light`
- `direction`: `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`, or `omni`
- `frames`: authored frame count, such as `6f`
- `frame_size`: square frame size in pixels, such as `96`

Compatibility outputs are allowed while runtime scripts still expect older paths. Prefer manifests that write
both the canonical file and the current compatibility file instead of naming new source art after legacy paths.

## Replacement Policy

Runtime directories are current-state authority, not history. When a newly ingested sheet replaces the same
mapped owner/layer/action/variant/direction with a different frame count or corrected art, update the consumer
mapping and remove the superseded runtime PNG plus its `.import` file after the new output is imported and
verified.

Keep `_pipeline/archive/`, source files, normalized previews, and logs. Those locations preserve provenance and
debug history. Do not delete intentionally distinct alternates such as `heavy_02`, `alt`, or weapon-specific
variants unless they are no longer mapped and have been explicitly superseded.

Optional post-process:

```json
{
  "post_process": ["operator_curated_resources"]
}
```

That hook runs the Godot-side rebuild script for operator curated resources.

Enemy runtime import post-process:

```json
{
  "post_process": ["enemy_runtime_import"]
}
```

That hook runs a headless Godot import pass after writing enemy PNGs so dynamic enemy loaders can read the updated runtime sheets on the next boot. It does not yet build enemy `SpriteFrames` resources; current Shrumb and wolf loaders build those dynamically from their configured PNG paths.

## Examples

Example manifests live in:

```text
custodian/tools/pipelines/examples/
```

- `drone_idle_manifest.json`
- `operator_fast_attack_manifest.json`

## Commands

Run ingest:

```bash
python custodian/tools/pipelines/ingest.py
```

Dry-run validation:

```bash
python custodian/tools/pipelines/ingest.py --dry-run
```

Skip post-process hooks:

```bash
python custodian/tools/pipelines/ingest.py --skip-post
```

Rebuild operator curated resources directly:

```bash
python custodian/tools/pipelines/reload_assets.py
```

## Design Rules

- Do not force a single sheet layout across all assets.
- Preserve source pixels by default.
- Only resize when the manifest explicitly requests it.
- Use the canonical `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png` naming pattern for new sheets.
- Output into the live runtime domains:
  - `operator/`
  - `weapons/`
  - `enemies/`
  - `effects/`
  - `vehicles/`
  - `turrets/`
- Do not assume Godot auto-loads arbitrary files; target the specific paths the runtime already reads.
