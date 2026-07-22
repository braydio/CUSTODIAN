# Sprite Pipeline

Repo-native sprite ingest for the active Godot runtime.

## Runtime-Ready Asset Drop

Already organized, runtime-ready assets that need no sprite slicing or rebuild hooks can
use the persistent generic intake:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
custodian/tools/pipelines/watch_runtime_ready_assets.sh
```

Drop them under `custodian/asset_drop/runtime_ready/inbox/`, mirroring the intended path
below `res://content/`. See `custodian/asset_drop/runtime_ready/README.md`.

Keep using the specialized sprite pipeline below for sheets requiring parsing,
compatibility outputs, or runtime resource rebuilds.

## Status

- Intake path is `res://content/sprites/_pipeline/`.
- Ingest script is `custodian/tools/pipelines/ingest.py`.
- Aseprite exports can be staged through `custodian/tools/pipelines/aseprite_inbox.py`.
- Operator curated body changes can trigger the live `SpriteFrames` rebuild through
  `custodian/tools/pipelines/update_operator_curated_resources.gd`.
- Modular Operator sheets use
  `operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png`;
  generic modular actions become stable runtime modules, while live playback wiring remains deliberate.
- The intake aliases `operator__cape__...` to the stable `wardrobe_cape` module layer and accepts
  `operator__modular_ranged_weapon__...`; `relaxed_carbine_mk1_01` normalizes to the live ranged `relaxed_01`
  action and outranks generic relaxed weapon art.
- Operator modular source sheets live under `content/sprites/operator/new_operator/modular/`; generated stable
  modules live under `content/sprites/operator/runtime/modules/new_operator/`. Runtime scenes should not read
  directly from `_pipeline/` or from QA preview output.
- Hover buggy vehicle sheets can trigger the live vehicle `SpriteFrames` rebuild through
  `custodian/tools/pipelines/update_vehicle_runtime_resources.gd`.
- Enemy, drone, and allied actor outputs use the canonical owner-first tree
  `content/sprites/<actor>/runtime/<layer>/<action_group>/`. Domain-prefixed enemy/allied
  copies are retained for current consumers during migration. Weapon, effects, vehicle,
  and turret outputs retain their specialized runtime domains.

## Why This Exists

The project already has multiple live sprite consumers:

- operator body and overlay strips feeding `operator_runtime_frames.tres`,
  `operator_weapon_frames.tres`, and `operator_melee_overlay_frames.tres`
- weapon-owned animation strips in `content/sprites/weapons/`
- non-Operator actor runtime strips in `content/sprites/<actor>/runtime/`, with temporary domain-prefixed compatibility copies
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
- matching source PNG `.import` sidecars are removed from the inbox

Do not keep inbox `.import` files around as source assets. They are editor metadata only and should be discarded once the PNG has been ingested.

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
operator__body__locomotion__dodge__n__4f__96.png
operator__body__locomotion__dodge_recovery__n__4f__96.png
operator__body__locomotion__dodge_backstep__s__4f__96.png
operator__body__locomotion__dodge_backstep_recovery__s__4f__96.png
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

Operator dodge is intentionally split into phase tracks. Use `dodge` for the impulse phase and `dodge_recovery` for the granular recovery/timing phase. The aim-hop fallback uses `dodge_backstep` and `dodge_backstep_recovery`; those should be authored as the Operator stepping or hopping backward away from the current aim direction.
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

Modular Operator runtime post-process:

```json
{
  "post_process": ["operator_modular_runtime"]
}
```

That hook runs `build_operator_modular_runtime.py`, which normalizes supported Operator modular source sheets
into stable runtime module strips and current action-runtime compatibility outputs. It does not register new
gameplay states by itself.

Enemy runtime import post-process:

```json
{
  "post_process": ["enemy_runtime_import"]
}
```

That hook runs a headless Godot import pass after writing enemy PNGs so dynamic enemy loaders can read the updated runtime sheets on the next boot. It does not yet build enemy `SpriteFrames` resources; current Shrumb and wolf loaders build those dynamically from their configured PNG paths.

Vehicle runtime import post-process:

```json
{
  "post_process": ["vehicle_runtime_import"]
}
```

That hook rebuilds the hover buggy `SpriteFrames` resource from canonical sheets in `res://content/sprites/vehicles/hover_buggy/runtime/`. Use inbox names such as `hover_buggy__body__idle__omni__1f__256.png`, `hover_buggy__body__idle_start__omni__7f__256.png`, `hover_buggy__body__idle_loop__omni__6f__256.png`, and `hover_buggy__body__move__e__6f__256.png`.

## Examples

Example manifests live in:

```text
custodian/tools/pipelines/examples/
```

- `drone_idle_manifest.json`
- `operator_fast_attack_manifest.json`

## Commands

Generate inbox manifests for staged canonical PNGs:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

Run ingest:

```bash
python custodian/tools/pipelines/ingest.py
```

Dry-run validation:

```bash
python custodian/tools/pipelines/ingest.py --dry-run
```

Preview and apply cleanup of superseded canonical animation siblings:

```bash
python custodian/tools/pipelines/ingest.py --dry-run --remove-superseded
python custodian/tools/pipelines/ingest.py --remove-superseded
```

For the normal generated-manifest workflow:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

`--remove-superseded` matches only canonical siblings in the exact output directory whose filename is identical
through direction and differs only by `__<frames>f__<frame_size>.png`. Their `.import` sidecars are removed too.
Modular Operator cleanup propagates into stable generated runtime modules after curated `SpriteFrames` resources
have been rebuilt. A generated sheet that is still referenced by a `.tres` or `.tscn` is retained, preventing a
frame-count replacement such as `6f` to `5f` from making the consumer unloadable between build phases.

Skip post-process hooks:

```bash
python custodian/tools/pipelines/ingest.py --skip-post
```

Rebuild operator curated resources directly:

```bash
python custodian/tools/pipelines/reload_assets.py
```

Validate modular Operator routing and generic action output:

```bash
python custodian/tools/validation/operator_modular_pipeline_smoke.py
```

Build Operator modular runtime strips directly from existing modular source sheets:

```bash
python custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded
python custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded
```

Report Operator modular production coverage:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
python custodian/tools/validation/operator_animation_contract_report.py --strict
```

Preview a modular/action runtime sequence for QA review:

```bash
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_windup_01,fast_strike_01,fast_recovery_01 --include-fx
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --action block_loop_01 --directions e,w --include-fx
```

Plan animation coverage for a new modular-compatible character without generating art:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py --owner enemy_ritualist --template humanoid_combat --frame-size 96 --directions s,se,e,ne,n,nw,w,sw
```

Run pure-Python smoke checks for the new production tools:

```bash
python custodian/tools/validation/operator_animation_contract_report_smoke.py
python custodian/tools/validation/operator_action_preview_smoke.py
python custodian/tools/validation/scaffold_character_contract_smoke.py
```

Rebuild vehicle runtime resources directly:

```bash
godot --headless --path custodian --script res://tools/pipelines/update_vehicle_runtime_resources.gd
```

Stage aseprite exports into the inbox and optionally run the current ingest:

```bash
python custodian/tools/pipelines/aseprite_inbox.py --run-ingest
```

## Design Rules

- Do not force a single sheet layout across all assets.
- Preserve source pixels by default.
- Only resize when the manifest explicitly requests it.
- Use the canonical `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png` naming pattern for new sheets.
- Treat source sheets, runtime strips, generated modules, curated `SpriteFrames`, and QA preview images as
  separate artifacts:
  - source sheets are intake or authored modular sheets
  - runtime strips are PNGs under the live `content/sprites/<domain>/runtime/` paths
  - generated modules are stable Operator layer strips under `operator/runtime/modules/new_operator/`
  - curated resources are Godot `.tres` `SpriteFrames` rebuilt by explicit scripts
  - QA previews are review-only composites under `custodian/animation_review/`
- Output into the live runtime domains:
  - `operator/`
  - `weapons/`
  - `enemies/`
  - `effects/`
  - `vehicles/`
  - `turrets/`
- Do not assume Godot auto-loads arbitrary files; target the specific paths the runtime already reads.
