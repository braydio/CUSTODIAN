# Sprite Pipeline Cheatsheet

Use this when you need to answer:

1. What assets are still needed?
2. Is this new asset valid?
3. How do I ingest or build it into the runtime?
4. How do I prove the runtime sees the result?

The existing sprite pipeline is the authority. Do not create a second asset tree. `_pipeline/` is intake,
debug, archive, and request planning only; runtime scenes should consume files under the normal
`content/sprites/<domain>/...` runtime paths.

## 1. Check What Assets Are Needed

For Operator modular animation coverage:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
```

Use strict mode only when you want missing or suspicious required coverage to fail:

```bash
python custodian/tools/validation/operator_animation_contract_report.py --strict
```

Read the report in this order:

- `Missing required assets`: must be produced before the core contract is complete.
- `Missing optional assets`: useful next production targets, not blockers.
- `Suspicious assets`: filenames, dimensions, frame counts, layers, loadouts, or source/runtime drift to inspect.
- `Suggested next production batch`: grouped next art batch when required items are absent.

For a new character or enemy, scaffold a checklist instead of guessing coverage:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py \
  --owner enemy_ritualist \
  --template humanoid_combat \
  --frame-size 96 \
  --directions s,se,e,ne,n,nw,w,sw
```

Outputs land in:

```text
custodian/content/sprites/_pipeline/requests/<owner>/
```

## 2. Validate A Candidate Asset Before Ingest

Check the filename contract first.

General sprite intake names:

```text
<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png
```

Operator modular names:

```text
operator__<modular_layer>__<loadout>__<action>__<direction>__<frames>f__<frame_size>.png
```

Common Operator modular layers:

```text
modular_lower_body
modular_upper_body
modular_upper_fx
modular_wardrobe_cape
modular_combined_body
modular_sidearm
```

Direction codes:

```text
s,se,e,ne,n,nw,w,sw
```

For Operator modular drops, the report tool catches most mistakes:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
```

For visual QA of an already-built Operator action:

```bash
python custodian/tools/pipelines/operator_action_preview.py \
  --loadout unarmed \
  --action block_loop_01 \
  --directions e,w \
  --include-fx
```

For fast attack sequence review:

```bash
python custodian/tools/pipelines/operator_action_preview.py \
  --loadout unarmed \
  --sequence fast_windup_01,fast_strike_01,fast_recovery_01 \
  --include-fx
```

Preview output is review-only:

```text
custodian/animation_review/
```

Do not wire gameplay to preview images.

## 3. Ingest A New PNG Through The Inbox

Use this path for new staged source PNGs that need manifest-driven routing:

```text
custodian/content/sprites/_pipeline/inbox/
```

Drop the PNG there, then generate/check manifests:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run
```

If the dry run looks correct, generate manifests:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py
```

Dry-run ingest:

```bash
python custodian/tools/pipelines/ingest.py --dry-run
```

Apply ingest:

```bash
python custodian/tools/pipelines/ingest.py
```

Use superseded cleanup only when replacing the same semantic asset with a corrected frame count or frame size:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run --remove-superseded
python custodian/tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

## 4. Build Operator Modular Runtime Directly

If Operator modular source PNGs already live here:

```text
custodian/content/sprites/operator/new_operator/modular/
```

do not move them back through the inbox. Build the generated runtime modules directly:

```bash
python custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded
python custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded
```

Generated stable modules land under:

```text
custodian/content/sprites/operator/runtime/modules/new_operator/
```

Some action-runtime compatibility outputs land under:

```text
custodian/content/sprites/operator/runtime/actions/
```

Runtime playback still requires deliberate state-machine and resource registration. A generated PNG is not
automatically a new gameplay animation.

## 5. Build A Simple Actor From Inbox PNGs

Use this for non-Operator actors such as allied infantry droids, combat droids, and routebreaker-style mechs.
Do not use the Operator modular upper/lower/weapon path unless the actor actually needs swappable equipment.

Drop canonical strips into:

```text
custodian/content/sprites/_pipeline/inbox/
```

Name them with `body` and `fx` layers:

```text
allied_infantry_droid__body__locomotion__idle__e__5f__96.png
allied_infantry_droid__body__locomotion__run__w__6f__96.png
allied_infantry_droid__body__ranged__fire__e__5f__96.png
allied_infantry_droid__fx__ranged__muzzle_flash__e__5f__96.png
```

For quick iteration, simple allied names also work:

```text
allied_infantry_droid__idle__e__5f__96.png
allied_infantry_droid__fx_muzzle_flash__e__5f__96.png
```

Use the canonical form for production batches.

Then run:

```bash
python custodian/tools/pipelines/generate_inbox_manifests.py --dry-run
python custodian/tools/pipelines/generate_inbox_manifests.py
```

The ingest routes sheets into:

```text
custodian/content/sprites/allies/<actor_slug>/runtime/body/
custodian/content/sprites/allies/<actor_slug>/runtime/fx/
```

and rebuilds:

```text
custodian/game/actors/allies/<actor_slug>/<actor_slug>_body_frames.tres
custodian/game/actors/allies/<actor_slug>/<actor_slug>_fx_frames.tres
```

The generated `SpriteFrames` animation names are `<animation>_<direction>`, for example `idle_e`, `run_w`,
`fire_e`, and `muzzle_flash_e`.

You can rebuild resources from existing runtime strips without ingesting new PNGs:

```bash
python custodian/tools/pipelines/build_actor_spriteframes.py --domain allies --owner allied_infantry_droid
```

## 6. Refresh Godot Runtime Resources

For Operator curated SpriteFrames:

```bash
python custodian/tools/pipelines/reload_assets.py
```

or directly:

```bash
cd custodian
godot --headless --script res://tools/pipelines/update_operator_curated_resources.gd
```

For vehicle runtime resources:

```bash
cd custodian
godot --headless --script res://tools/pipelines/update_vehicle_runtime_resources.gd
```

When assets/resources changed, a Godot import pass is often useful:

```bash
cd custodian
godot --headless --import --quit
```

## 7. Prove The Pipeline Still Works

Run the focused Python smokes:

```bash
python custodian/tools/validation/operator_modular_pipeline_smoke.py
python custodian/tools/validation/operator_animation_contract_report_smoke.py
python custodian/tools/validation/operator_action_preview_smoke.py
python custodian/tools/validation/scaffold_character_contract_smoke.py
```

Then rerun the real coverage report:

```bash
python custodian/tools/validation/operator_animation_contract_report.py
```

For live Operator presentation changes, run the Godot smoke:

```bash
cd custodian
godot --headless --script tools/validation/operator_modular_layers_smoke.gd
```

## Quick Decision Table

| Ask | Tool |
|---|---|
| What Operator modular assets are needed? | `operator_animation_contract_report.py` |
| Is a required Operator modular suite complete? | `operator_animation_contract_report.py --strict` |
| Preview a built Operator action or sequence | `operator_action_preview.py` |
| Plan a new character's first animation batch | `scaffold_character_contract.py` |
| Route new inbox PNGs | `generate_inbox_manifests.py`, then `ingest.py` |
| Rebuild existing Operator modular source sheets | `build_operator_modular_runtime.py` |
| Refresh Operator SpriteFrames | `reload_assets.py` or `update_operator_curated_resources.gd` |
| Validate pure Python tooling | the three new `*_smoke.py` scripts |
