# Sprite Pipeline System

## Status

- **Type**: Infrastructure Architecture
- **Location**: `custodian/tools/pipelines/`
- **Status**: Active, repo-native intake pipeline
- **Last Updated**: 2026-04-25

## Purpose

The sprite pipeline is the intake layer for new or revised sprite sheets. Its job is not to invent a new
runtime asset tree. Its job is to transform incoming sheets into the exact runtime-owned paths already consumed
by the Godot project.

## Runtime Authority

The pipeline must target the live consumers that already exist:

1. Operator curated resources rebuilt into:
   - `res://game/actors/operator/operator_runtime_frames.tres`
   - `res://game/actors/operator/operator_weapon_frames.tres`
   - `res://game/actors/operator/operator_melee_overlay_frames.tres`
2. Weapon-owned animation strips in `res://content/sprites/weapons/`
3. Enemy runtime strips in `res://content/sprites/enemies/`
4. Effects runtime strips in `res://content/sprites/effects/runtime/`
5. Vehicle and turret runtime strips in their current sprite domains

Do not route new work through a synthetic `content/sprites/entities/` tree unless the runtime is explicitly
migrated to that structure first.

## Intake Structure

```text
content/sprites/_pipeline/
  inbox/
  normalized/
  logs/
  archive/
```

Rules:

- `inbox/` is for staged source PNG + JSON manifest pairs
- `normalized/` is only for debug previews of parsed frames
- `logs/` stores ingest results
- `archive/` stores processed intake files
- Godot runtime scenes do not read directly from `_pipeline/`

## Manifest-Driven Ingest

Every intake job is driven by explicit metadata. The ingest script must not assume a single universal grid.

Supported source modes:

- `copy`
- `strip`
- `grid`

Supported output layouts:

- `copy`
- `horizontal_strip`
- `vertical_strip`

Optional transforms are output-local and explicit. The pipeline must preserve source pixels by default.

## Canonical Runtime Naming

New sprite sheets should use this canonical filename pattern:

```text
<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png
```

Fields:

- `owner`: entity or asset owner, such as `operator`, `enemy_grunt`, `drone`, `fallen_star_katana`, `hit_spark`
- `layer`: render layer, usually `body`, `weapon`, `fx`, `shadow`, or `mask`
- `action_group`: broad semantic group, such as `locomotion`, `melee`, `defense`, `ranged`, `reaction`, `death`, `impact`
- `variant`: specific animation, such as `walk`, `sprint`, `roll`, `fast_01`, `heavy_01`, `block_enter`, `hit_light`
- `direction`: one of `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`, or `omni`
- `frames`: authored frame count, such as `6f` or `8f`
- `frame_size`: square frame size in pixels, such as `96`, `128`, or `64`

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

Compatibility rule:

- Legacy runtime paths may remain while current scenes and rebuild scripts still consume them.
- New source and pipeline intake work should use the canonical name.
- A manifest may write a canonical output and a compatibility copy in the same run.
- Do not create new naming families such as `fast_attack_north_base_*` unless they are temporary compatibility outputs for existing code.

## Standard Animation Set Target

Production character bodies should converge on a shared animation vocabulary:

```text
locomotion:
  idle, walk, sprint, dodge, roll

melee:
  light_01, light_02, fast_01, fast_02, heavy_01, heavy_charge, heavy_release

defense:
  block_enter, block_hold, block_hit, block_break, block_exit

ranged:
  aim, fire, fire_walk, reload, recoil

reaction:
  hit_light, hit_heavy, stagger, knockdown, recover

death:
  default, disintegrate
```

Direction rule:

- Prefer authored 8-direction body animation for `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, and `nw`.
- If only half the directions are authored, declare mirrored directions in the runtime/manifest metadata instead of hiding that assumption in filenames.
- Use `omni` only for non-directional effects.

## Current Implementation

Primary scripts:

- `custodian/tools/pipelines/ingest.py`
- `custodian/tools/pipelines/reload_assets.py`
- `custodian/tools/pipelines/update_operator_curated_resources.gd`

Current post-process support:

- `operator_curated_resources`

That hook rebuilds operator runtime `SpriteFrames` after curated body/overlay outputs are updated.

## Why The Earlier Proposal Was Rejected

The earlier draft proposed:

- a new `content/sprites/entities/` root
- a single hardcoded `2x4` ingest shape
- mandatory resize to `32x64` inside `96x96`
- dynamic runtime auto-loading as the main consumer contract

That conflicted with the live repo in four ways:

1. the runtime already consumes domain-specific paths under `operator/`, `weapons/`, `enemies/`, `effects/`, `vehicles/`, and `turrets/`
2. operator animation rebuilds already depend on curated and source master sheets
3. enemy runtime strips are still bound by explicit scene/script paths
4. blanket rescaling would damage authored pixel assets and break larger sprite classes

## Intended Workflow

1. Drop source PNG + sidecar manifest into `content/sprites/_pipeline/inbox/`
2. Run `python custodian/tools/pipelines/ingest.py`
3. Inspect outputs in the live runtime domain
4. If the manifest requested `operator_curated_resources`, let the post-process rebuild the operator runtime frames
5. Validate in Godot

## Non-Goals

- No universal auto-loader for every sprite class in the current pass
- No hidden rescale of all art into one character footprint
- No second runtime asset hierarchy beside the one the game already uses
- No docs claiming hot reload or implementation coverage that the runtime does not actually have
