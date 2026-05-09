# Inventory UI System

Bare-minimum inventory UI system for CUSTODIAN.

## Asset Files

### UI Textures
- `content/ui/inventory/frame_inventory.png` - 9-slice panel background (400x500)
- `content/ui/inventory/slot_empty.png` - Empty item slot (64x64)
- `content/ui/inventory/slot_highlighted.png` - Highlighted/hovered slot (64x64)

### Item Icons
- `content/ui/inventory/icons/icon_placeholder.png` - Generic item icon (48x48)

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
# Open inventory
inventory_ui.open(my_inventory)

# Close inventory
inventory_ui.close()

# Toggle with I key (built-in)
# Signals
inventory_ui.closed.connect(callback)
```

## Visual Style

Matches existing terminal UI:
- Dark grey background (40, 44, 52)
- Blue-grey bracket borders (80, 90, 110)
- Highlight blue for selection (100, 180, 255)
- 64x64 item slots in 5-column grid
- 20 slot capacity (configurable)

## Future Enhancements (Not Implemented)

- Equipment slots (armor, weapons)
- Drag-and-drop
- Item rarities with visual effects
- Inventory categories/tabs
- Scroll bar for more slots
- Context menu (drop, use, equip)
- Item comparison tooltips
- Hotbar/quick slots
- Item stacking with max stack sizes
- Item filtering and sorting
