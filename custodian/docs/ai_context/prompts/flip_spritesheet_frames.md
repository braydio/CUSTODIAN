# Flip Spritesheet Frames

Repository workflow defaults are inherited from `custodian/AGENTS.md`.

Use `custodian/tools/art/png_flip_frames.py` to produce a mirrored counterpart
while preserving each frame's grid cell.

## Required inputs

| Input | Meaning |
|---|---|
| `{{input_file}}` | Source sheet |
| `{{output_file}}` | Destination sheet |
| `{{rows}}`, `{{cols}}` | Frame grid |
| `{{flip_direction}}` | `--h`, `--v`, or both |
| `{{frames}}` | Optional frame count; defaults to rows × columns |
| `{{strict}}` | Optional `--strict` to require all grid cells |

Do not infer missing dimensions or frame count. Keep the semantic identity and
all filename fields except the mirrored direction token.

```bash
python3 custodian/tools/art/png_flip_frames.py \
    {{input_file}} {{output_file}} \
    --rows {{rows}} --cols {{cols}} \
    {{flip_direction}} {{frames}} {{strict}}
```

Confirm that the output exists, is non-empty, matches the input dimensions,
and reports the requested flip direction. If this resolves a tracked asset
requirement, update that requirement's owning tracker.
