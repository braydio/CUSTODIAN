# Operator Animation Assets V2

Operator body motion is authored once per animation profile. Equipped weapons normally follow per-frame sockets; weapon-only overrides are reserved for silhouettes that static socketing cannot preserve.

## Authority

- Editable strips: `source/animations/<profile>/<group>/<action>/`
- Generated strips: `runtime/animations/<profile>/<group>/<action>/`
- Historical material: `source/legacy/`
- Weapon presentation: `content/sprites/weapons/<weapon_id>/operator/<profile>/`
- Catalog: `content/data/operator/generated/operator_animation_catalog.generated.json`

Filename grammar:

```text
<owner>__<layer>__<animation_profile>__<action_group>__<action>__<direction>__<frames>f__<frame_size>.png
```

`frame_size` may be square (`96`) or rectangular (`156x96`). Declared dimensions are preserved.

## Build

```bash
python3 tools/pipelines/build_operator_runtime.py --strict --remove-superseded
godot --headless --path . --script res://tools/pipelines/build_operator_animation_resources.gd
```

The catalog is the semantic filesystem boundary. Generated `SpriteFrames` remain compatibility consumers, not asset authority.

## Weapons

- `socketed_static`: directional held art plus socket data.
- `authored_overlay`: weapon-only animated strips.
- `hybrid`: socketed by default with selected overrides.

`weapon_type` is gameplay classification. `animation_profile` selects body motion. A normal sword adds held textures and reuses `melee_1h`; an unusual silhouette adds only an action override; a new profile is warranted only when handling mechanics change.

## Legacy migration

`migrate_operator_assets_v2.py` inventories hashes and references before moving assets. Exact duplicates are removed; masters and unclassified files remain under `source/legacy`. The former `new_operator`, `curated`, `modules/new_operator`, and layer-rooted runtime trees are not production paths.
