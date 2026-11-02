# Inventory UI Runtime Asset Contract

Drop production inventory UI assets into these folders using the canonical names
from `inventory_ui_asset_manifest.json`. Runtime code checks canonical paths
first, then falls back to existing Black Reliquary or legacy inventory assets.

```text
runtime/
├── panels/
│   ├── inventory_frame_9slice.png
│   └── inventory_panel_deep_9slice.png
├── slots/
│   ├── inventory_slot_empty.png
│   ├── inventory_slot_hover.png
│   └── inventory_slot_selected.png
├── icons/
│   ├── icon_unknown.png
│   └── icon_{item_id}.png
└── ornaments/
    ├── inventory_ornament_nw.png
    ├── inventory_ornament_ne.png
    ├── inventory_ornament_sw.png
    └── inventory_ornament_se.png
```

Canonical item icons use a transparent `128x128px` canvas with centered visible
art approximately `88-104px` across its longest edge and nearest-neighbor
filtering. Existing legacy art can be normalized without redrawing it:

```bash
python custodian/tools/ui/normalize_inventory_icons.py --apply
python custodian/tools/ui/normalize_inventory_icons.py --check
```

Text remains live Godot `Label` text; do not bake item names, counts,
descriptions, or prompts into images.
