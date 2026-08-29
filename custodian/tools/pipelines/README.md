# CUSTODIAN Sprite Pipeline

The sprite inbox routes validated assets into canonical source trees, then runs domain builders. Runtime output is generated; edit source art, never generated PNGs.

## Operator workflow

Use the V2 filename grammar:

```text
<owner>__<layer>__<animation_profile>__<action_group>__<action>__<direction>__<frames>f__<frame_size>.png
```

Examples:

```text
operator__upper_body__melee_1h__posture__idle_ready_01__e__4f__96.png
operator__fx__melee_1h__attack__fast_01__e__10f__156x96.png
fallen_star_katana__weapon__melee_1h__presentation__held_01__e__1f__96.png
```

Put the PNG in `content/sprites/_pipeline/inbox/`, then run:

```bash
python3 tools/pipelines/generate_inbox_manifests.py --dry-run
python3 tools/pipelines/generate_inbox_manifests.py --remove-superseded
```

The generator imports `operator_asset_schema.py`, validates identity/dimensions, routes canonical source, and requests `operator_runtime_build`. Legacy names pass only through explicit normalization and print `[LEGACY INPUT]`; output is always V2.

The Operator post-process runs:

```bash
python3 tools/pipelines/build_operator_runtime.py --strict --remove-superseded
python3 tools/pipelines/update_operator_compatibility_resources.py
godot --headless --path . --import --quit
godot --headless --path . --script res://tools/pipelines/build_operator_animation_resources.gd
python3 tools/pipelines/update_operator_compatibility_resources.py --check
```

The builder preserves declared canvases, validates synchronized lower/upper clocks, removes superseded semantic siblings when requested, and emits `content/data/operator/generated/operator_animation_catalog.generated.json`. It does not create gameplay states or dummy layers.

## Validation

```bash
python3 tools/validation/operator_asset_schema_smoke.py
python3 tools/validation/operator_modular_pipeline_smoke.py
python3 tools/validation/operator_asset_layout_smoke.py
python3 tools/validation/operator_runtime_path_audit.py
python3 tools/validation/operator_animation_contract_report.py --strict
```

Non-Operator assets continue through their domain-specific builders. Inputs are archived only after requested post-processing succeeds. `_pipeline/archive` is intake recovery material, not canonical art or version history.
