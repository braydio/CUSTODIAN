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

Use 64x64 or larger square item icons. Text remains live Godot `Label` text; do
not bake item names, counts, descriptions, or prompts into images.
