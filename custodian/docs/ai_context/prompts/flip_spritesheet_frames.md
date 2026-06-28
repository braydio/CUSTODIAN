# Flip Spritesheet Frames

Read `custodian/AGENTS.md` first.
Then read `CURRENT_STATE.md`, `FILE_INDEX.md`, and the relevant asset layout docs.

## Task

Use `custodian/tools/art/png_flip_frames.py` to generate a horizontally or vertically mirrored counterpart of a spritesheet, preserving the original frame grid layout.

## Rules

- Preserve deterministic fixed-step simulation.
- Keep rendering/UI separate from simulation authority.
- Follow `custodian/docs/ai_context/VALIDATION_RECIPES.md` for any follow-up validation.
- Update `CURRENT_STATE.md`, `FILE_INDEX.md`, or asset layout docs if the mirrored sheet changes runtime file ownership or entrypoints.

## Parameters

The caller must provide these values; do not guess them:

| Parameter | Description |
|---|---|
| **input** | Path to the source spritesheet PNG |
| **output** | Path for the output mirrored spritesheet PNG |
| **rows** | Number of frame rows in the sheet |
| **cols** | Number of frame columns in the sheet |
| **--h or --v** | Flip direction. `--h` flips each frame horizontally; `--v` flips vertically; pass both for both axes |
| **--frames** (optional) | Number of frames to process. Defaults to `rows * cols`. Pass a smaller value to process only the first N frames |
| **--strict** (optional) | Pass `--strict` to fail if `--frames` does not equal `rows * cols` |

## How to invoke

```bash
# Inside custodian/ (the Godot project root):
python3 tools/art/png_flip_frames.py \
    {{input_file}} {{output_file}} \
    --rows {{rows}} --cols {{cols}} \
    {{flip_direction}} \
    {{frames}} \
    {{strict}}
```

## Example

Flip a 2-column, 5-row unarmed idle sheet horizontally to produce its mirror counterpart:

```bash
python3 tools/art/png_flip_frames.py \
    content/sprites/operator/source/operator__modular_lower_body__unarmed__idle_01__e__5f__96.png \
    content/sprites/operator/source/operator__modular_lower_body__unarmed__idle_01__w__5f__96.png \
    --rows 5 --cols 1 --h
```

## Naming Convention

The repository follows the canonical file naming scheme:
`operator__<layer>__<loadout>__<action>__<direction>__<frames>f__<size>.png`

When generating a mirrored counterpart, preserve all fields except the direction token (mirror `e` → `w`, `ne` → `nw`, `se` → `sw`, etc.).

## Context Files

- `custodian/AGENTS.md` — Local routing and working rules
- `custodian/docs/ai_context/CURRENT_STATE.md` — Live runtime state
- `custodian/docs/ai_context/FILE_INDEX.md` — File ownership map
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md` — Asset layout conventions
- `custodian/tools/art/png_flip_frames.py` — The tool itself
- `custodian/content/sprites/operator/source/` — Example source sprite directory
- `custodian/tools/check_operator_modular_assets.py` — Post-flip validation reference

## Verification

After the tool runs successfully, confirm:
1. Output file exists and is non-empty.
2. Output dimensions match input dimensions.
3. The flip direction reported by the tool matches the intent (`hflip=True` for east→west, etc.).
4. If this completes a missing asset group, update the relevant tracking doc (e.g., `design/OperatorAnimatorTracker.md`) and the asset manifest.
