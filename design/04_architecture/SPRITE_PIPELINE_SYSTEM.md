# Sprite Pipeline System

## Status

- **Type**: Infrastructure Architecture
- **Location**: `custodian/tools/pipelines/`
- **Status**: Active, repo-native intake pipeline
- **Last Updated**: 2026-07-22

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
3. Enemy/drone runtime strips in `res://content/sprites/enemies/<actor>/runtime/<layer>/<action_group>/`; allied actors retain owner-first runtime strips plus domain-prefixed compatibility outputs while their consumers migrate
4. Effects runtime strips in `res://content/sprites/effects/runtime/`
5. Vehicle and turret runtime strips in their current sprite domains

Do not route new work through a synthetic `content/sprites/entities/` tree unless the runtime is explicitly
migrated to that structure first.

## Intake Structure

```text
content/sprites/_pipeline/
  aseprite/
  inbox/
  requests/
  normalized/
  logs/
  archive/
```

Rules:

- `inbox/` is for staged source PNG + JSON manifest pairs
- `requests/` is for generated production checklists/contracts for future art batches
- `normalized/` is only for debug previews of parsed frames
- `logs/` stores ingest results
- `archive/` stores processed intake files
- Godot runtime scenes do not read directly from `_pipeline/`

## Generic Runtime-Ready Intake

Assets that are already runtime-ready but do not need sprite frame parsing, compatibility
copies, or resource rebuild hooks use the persistent intake surface:

```text
custodian/asset_drop/runtime_ready/
  inbox/
  archive/
  logs/
  examples/
```

The drop area lives outside `res://` so unreviewed files do not become accidental Godot
runtime authority. Paths under `inbox/` mirror their intended destination below
`res://content/`; explicit `.runtime.json` sidecars can route ambiguous files. The router
rejects different existing targets unless replacement is explicitly requested, archives
processed inputs, writes JSON receipts, and can run a Godot import pass.

This generic intake complements rather than replaces `content/sprites/_pipeline/`.
Sprite sheets requiring normalization or post-process hooks must continue through the
specialized sprite pipeline.

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

Rectangular source frames use `<width>x<height>` in the final token, for example
`operator__body__melee_1h__e__8f__156x96.png`. Manifest generation validates that the source strip is
`frames * width` by `height` and writes the inferred `[width, height]` frame size automatically.

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

Modular Operator sheets use a deliberate specialization:

```text
operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png
```

The inbox routes all supported modular layers through `operator_modular_runtime`. Purpose-built actions keep
their existing builders; other modular actions are normalized into stable runtime modules below
`operator/runtime/modules/new_operator/<layer>/actions/<loadout>/<action>/`. This does not automatically add
new Operator gameplay states or playback mappings.

Composited Operator reaction pairs are a supported authored alias: `full_body_combat` routes to the live body domain and `combat_fx` routes to the synchronized overlay domain. Runtime playback remains an explicit gameplay/presentation wiring step.

Compatibility rule:

- Legacy runtime paths may remain while current scenes and rebuild scripts still consume them.
- New source and pipeline intake work should use the canonical name.
- A manifest may write a canonical output and a compatibility copy in the same run.
- Do not create new naming families such as `fast_attack_north_base_*` unless they are temporary compatibility outputs for existing code.

Non-Operator actor rule:

- Enemy and drone sheets use the canonical domain-owned shape `content/sprites/enemies/<actor>/runtime/<layer>/<action_group>/<canonical_filename>.png`. Do not emit loose `content/sprites/<enemy>/` trees.
- Allied actor sheets retain the owner-first shape `content/sprites/<actor>/runtime/<layer>/<action_group>/<canonical_filename>.png`; `allies/<actor>/runtime/<layer>/` remains a compatibility surface.
- The generic actor `SpriteFrames` builder reads enemy domain paths recursively without a loose-root fallback. Allied builds may merge their compatibility root, with the canonical root winning.

Replacement rule:

- Runtime folders are current-state authority, not version history.
- If a corrected sheet replaces the same mapped owner/layer/action/variant/direction, remove the superseded runtime PNG and `.import` after the new sheet is imported, wired, and validated.
- Keep `_pipeline/archive/`, source files, normalized previews, and logs as provenance/history.
- Do not remove intentional alternate variants such as `heavy_02`, `alt`, or weapon-specific variants unless they are explicitly unmapped and superseded.
- `--remove-superseded` is the opt-in automated cleanup. It removes only canonical sibling PNGs in the exact
  output directory with the same semantic identity through direction and a different frame-count or frame-size
  suffix, plus matching `.import` sidecars. Modular Operator cleanup also applies to generated stable modules.

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
- Ingest automatically writes horizontal counterparts for `e↔w`, `ne↔nw`, and `se↔sw`, flipping every selected frame independently. This applies across Operator, enemy, allied, vehicle, effect, prop, and other owner domains when the output filename carries a supported directional token.
- A counterpart output explicitly declared anywhere in the selected ingest batch always wins and is never replaced by an automatic mirror, including when the two authored directions use separate manifests.
- Use CLI `--no-mirror` for a selected ingest run or manifest-level `"auto_mirror": false` when a source must remain one-sided. `n`, `s`, and `omni` never generate counterparts.
- Use `omni` only for non-directional effects.

## Current Implementation

Primary scripts:

- `custodian/tools/pipelines/generate_inbox_manifests.py`
- `custodian/tools/pipelines/ingest.py`
- `custodian/tools/pipelines/ingest_runtime.gd`
- `custodian/tools/pipelines/build_operator_modular_runtime.py`
- `custodian/tools/pipelines/operator_action_preview.py`
- `custodian/tools/pipelines/scaffold_character_contract.py`
- `custodian/tools/pipelines/reload_assets.py`
- `custodian/tools/pipelines/update_operator_curated_resources.gd`
- `custodian/tools/pipelines/update_vehicle_runtime_resources.gd`
- `custodian/tools/validation/operator_animation_contract_report.py`

Current post-process support:

- `operator_curated_resources`
- `operator_modular_runtime`
- `enemy_runtime_import`
- `vehicle_runtime_import`

`operator_curated_resources` rebuilds operator runtime `SpriteFrames` after curated body/overlay outputs are
updated. `operator_modular_runtime` normalizes supported modular Operator source sheets from
`res://content/sprites/operator/new_operator/modular/` into generated runtime modules below
`res://content/sprites/operator/runtime/modules/new_operator/` and current action-runtime compatibility strips.
`enemy_runtime_import` and `vehicle_runtime_import` run import/resource refresh steps for the active enemy and
vehicle runtime domains.

Current production QA helpers:

- `operator_animation_contract_report.py` reports required, optional, extra, and suspicious Operator modular
  animation coverage from source sheets, generated modules, and action-runtime strips.
- `operator_action_preview.py` composites existing generated modules or action-runtime strips into review-only
  images under `custodian/animation_review/`.
- `scaffold_character_contract.py` writes checklist, suggested contract, and expected filename files under
  `content/sprites/_pipeline/requests/<owner>/` without generating art.

Artifact distinction:

- source sheets are intake PNGs or authored modular PNGs
- runtime strips are PNGs under the live `content/sprites/<domain>/runtime/` paths
- generated modules are Operator layer strips under `operator/runtime/modules/new_operator/`
- curated resources are Godot `.tres` `SpriteFrames` rebuilt by explicit scripts
- QA preview images are inspection artifacts and must not become runtime dependencies

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
2. Run `python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run` when manifests need to be generated
3. Run `python custodian/tools/pipelines/ingest.py`
4. Inspect outputs in the live runtime domain
5. If the manifest requested a post-process hook, let it run the matching resource/import refresh
6. Validate in Godot or with the narrow Python smoke/report tool for the changed surface

When Operator modular source already exists outside the inbox, pass
`--build-operator-runtime` to `ingest.py` to rebuild the stable Operator runtime after a successful ingest.
The flag respects `--dry-run` and `--remove-superseded`. Modular Operator manifests continue to request the
same build automatically through their `operator_modular_runtime` post-process hook.

For already-authored Operator modular source sheets in `content/sprites/operator/new_operator/modular/`:

1. Run `python custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded`
2. Run `python custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded`
3. Run `python custodian/tools/validation/operator_animation_contract_report.py`
4. Generate QA previews with `operator_action_preview.py` when visual inspection is needed
5. Register any new gameplay playback deliberately in runtime/state-machine code and curated resources

For already runtime-ready non-specialized assets:

1. Drop the file under `custodian/asset_drop/runtime_ready/inbox/<content-domain>/...`
2. Run `python custodian/tools/pipelines/runtime_ready_assets.py --dry-run`
3. Run `python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import`
4. Inspect the routed `content/` target and JSON receipt

## Non-Goals

- No universal auto-loader for every sprite class in the current pass
- No hidden rescale of all art into one character footprint
- No second runtime asset hierarchy beside the one the game already uses
- No docs claiming hot reload or implementation coverage that the runtime does not actually have
