# Operator Modular Head Pipeline

**Status:** Active first slice  
**Runtime owner:** Operator presentation only

## Contract

Modular head sheets use the canonical form:

```text
operator__modular_head__<head_profile>__<action>__<direction>__<frames>f__96.png
```

`<head_profile>` identifies interchangeable cosmetic art such as `hooded`; it is not a combat loadout. Source sheets route through `content/sprites/operator/new_operator/modular/`, then the modular builder normalizes them under:

```text
content/sprites/operator/runtime/modules/new_operator/head/actions/<head_profile>/<action>/
```

The curated resource builder registers available strips in `operator_modular_head_frames.tres`. `ModularHeadSprite` is presentation-only and follows the same authored frame origin, recoil, elevation, and charge-compression offsets as the upper body.

## Playback rules

- The configured `modular_head_profile` defaults to `hooded`.
- Head locomotion resolves independently by action and direction, then synchronizes its frame phase to `ModularUpperBodySprite`.
- Missing profile/action/direction art hides only the head layer. It must not invalidate body animation or change simulation.
- Full-body and action presentations hide the head until matching modular head coverage is explicitly wired.
- Initial coverage is `hooded / idle_01 / s / 5 frames` at 8 FPS.

## Validation

```bash
python3 custodian/tools/validation/operator_modular_pipeline_smoke.py
custodian/tools/operator/operator_ingest.sh --dry-run
godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd
```

The next art slice should add hooded idle directions before walk/run so direction changes never temporarily remove the head.
