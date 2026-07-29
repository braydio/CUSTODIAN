# Sundered Keep Backgrounds

Painterly presentation assets for Sundered Keep are grouped by runtime owner
and visual role. Runtime code may load PNGs from this tree; editable Aseprite
sources mirror it under `res://content/_aseprite/backgrounds/sundered_keep/`.

```text
sundered_keep/
├── shared/
│   ├── underlay/       # ocean and cliff bases shared by older route stages
│   ├── horizon/        # sky, far-sea, and fog horizon bands
│   └── landmarks/      # reusable distant Keep silhouettes
├── approach/
│   ├── underlay/       # persistent approach base and contact shadow
│   ├── fog/            # reveal veil and discrete fog strips
│   ├── light/          # runtime light-animation sheets
│   ├── occlusion/      # edge/final-gate concealment plates
│   ├── parallax/       # optional depth-rig plates
│   ├── playable/       # legacy approach blockout terrain/occluders
│   └── legacy/         # retained inactive compatibility plates
├── grand_vista/
│   ├── atmosphere/     # panorama, fog, spray, masks, and vignette
│   ├── fortress_components/
│   ├── landmarks/      # authored distant labyrinth plates
│   └── underlay/       # Grand Vista base-depth patches
├── world_vista/        # generated-world Vista-specific plates
└── causeway_approach/  # isolated causeway-stage plates
```

Rules:

- Keep runtime PNGs in the owning role folder; do not add new loose files at
  this directory root.
- Keep `.aseprite` and `.ase` files in the mirrored `_aseprite` tree.
- Preserve texture import UIDs when moving a live asset and update every
  `res://` consumer in the same change.
- `legacy/` assets are retained references, not production authority.
- These images are presentation-only. They do not create collision,
  navigation, terrain, or gameplay authority.
