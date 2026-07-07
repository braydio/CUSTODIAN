# Inventory UI System

Black Reliquary field-ledger inventory UI for CUSTODIAN.

The live game overlay reads `/root/InventoryManager`. The local `Inventory`
node/API is retained only for isolated test scenes or compatibility callers.

## Asset Files

Production replacement assets should be placed under
`content/ui/inventory/runtime/` using the canonical paths in
`runtime/inventory_ui_asset_manifest.json`. Runtime code uses those files
automatically when present and falls back to the existing Black Reliquary/legacy
textures while production art is missing.

### UI Textures
- `content/ui/inventory/frame_inventory.png` - 9-slice panel background (400x500)
- `content/ui/inventory/slot_empty.png` - Empty item slot (64x64)
- `content/ui/inventory/slot_highlighted.png` - Highlighted/hovered slot (64x64)

### Item Icons
- `content/ui/inventory/icons/icon_placeholder.png` - Generic item icon (48x48)
- `content/weapons/p9_custodian_sidearm/runtime/portrait/p9_custodian_sidearm__portrait__inventory__default__omni__1f__512.png` - P-9 sidearm inventory portrait used by the ledger and equipment detail cards
- `content/weapons/p9_custodian_sidearm/runtime/portrait/p9_custodian_sidearm__icon__hud__default__omni__1f__64.png` - Smaller P-9 sidearm HUD icon used in the loadout panel

## Script Files

### Core
- `game/ui/inventory/item_resource.gd` - Item data resource (extends Resource)
- `game/ui/inventory/inventory.gd` - Inventory logic (slot management, add/remove items)
- `game/ui/inventory/inventory_ui.gd` - UI controller (display, interaction)
- `game/ui/inventory/inventory_ui.tscn` - Inventory UI scene

## ItemResource Properties

```gdscript
@export var item_id: String = ""
@export var display_name: String = "Unknown Item"
@export var description: String = ""
@export var icon: Texture2D
@export var stack_size: int = 1
@export var rarity: String = "common"
@export var stackable: bool = false
@export var metadata: Dictionary = {}
```

## Inventory API

```gdscript
# Add items (returns true if all items were added)
var success: bool = inventory.add_item(item_resource, quantity)

# Remove items
inventory.remove_item(slot_index, quantity)

# Get item at slot
var slot_data: Dictionary = inventory.get_item_at(slot_index)
# Returns: {"item": ItemResource, "quantity": int}

# Check for empty slots
var has_space: bool = inventory.has_empty_slot()

# Signals
inventory.inventory_changed.connect(callback)
```

## InventoryUI Usage

```gdscript
# Open live inventory
inventory_ui.open()

# Open compatibility/local inventory
inventory_ui.open(my_inventory)

# Close inventory
inventory_ui.close()

# Toggle with I key (built-in)
# Signals
inventory_ui.closed.connect(callback)
```

## Visual Style

Uses the current Black Reliquary/CUSTODIAN style:
- darkened full-screen backdrop
- brass/gold reliquary frame
- compact category rail, fixed-layout carried-object cards, and structured detail inspector
- functional P-9 sidearm equip/unequip on the Equipment page
- live text for all item names, quantities, classifications, and descriptions
- production image assets resolved through `inventory_asset_catalog.gd`

## Future Enhancements (Not Implemented)

- Additional equipment slots beyond the live sidearm slot
- Drag-and-drop
- Item rarities with visual effects
- Scroll bar for more slots
- Context menu (drop and use; sidearm equip is already live)
- Item comparison tooltips
- Hotbar/quick slots
- Item stacking with max stack sizes
- Item filtering and sorting
