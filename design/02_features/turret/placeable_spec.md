# Placeable Turrets System

**Project:** CUSTODIAN
**Status:** Implementation
**Created:** 2026-03-24

---

## Overview

Allow players to place defense turrets from the command terminal on any walkable floor, consuming materials dropped by passive shrumbs.

---

## Flow

1. Player presses B → enters placement mode with the next available turret type OR opens terminal → FABRICATION section
2. UI panel shows available turret types with costs
3. Player selects turret type → enters placement mode (if not already)
4. Click on walkable floor → turret placed if enough materials, materials deducted
5. Press B on placed turret → dismantle for partial refund
6. Press E on a movable world-placed turret → pick it up and redeploy it without spending materials again

---

## Turret Costs

| Turret | Materials Cost | Dismantle Refund | Power Bank Usage |
|--------|----------------|-------------------|------------------|
| Gunner | 10 | 5 | 1 |
| Blaster | 15 | 8 | 1 |
| Repeater | 20 | 10 | 1 |
| Sniper | 25 | 12 | 1 |

---

## Placement Rules

- **Valid locations:** Any walkable floor tile (not walls, not occupied)
- **Max turrets:** Equal to available power banks (start: 10, can increase)
- **Placement preview:** Show ghost sprite at cursor before confirming
- **Dismantle:** Press B on placed turret → dismantle for partial refund
- **Pickup / redeploy:** Press E on a movable turret to enter placement mode carrying that turret; the redeploy keeps the turret and does not charge materials again
- **Build hotkey:** Press B when not in terminal to enter placement mode with the next turret type in the build cycle
- **Cycle type:** Press B again during placement mode to rotate through turret types
- **Cancel:** Press ESC or Q to exit placement mode

---

## Input Mapping

| Input | Action |
|-------|--------|
| B (world mode, not terminal) | Enter placement mode / cycle turret type |
| Left Click (placement mode) | Place turret at cursor |
| E (near movable turret) | Pick up turret for redeploy |
| ESC or Q (placement mode) | Exit placement mode |
| B (over placed turret) | Dismantle turret |

---

## UI Components

### Build Panel (Terminal)

- Shows 4 turret buttons in 2x2 grid
- Each shows: icon, name, cost
- Grayed out if insufficient materials
- Clicking selects that turret type for placement

### Ghost Preview

- Semi-transparent turret sprite at cursor
- Green when valid placement
- Red when invalid placement

---

## Implementation Tasks

### Phase 1: Core System

- [x] `turret_placement.gd` - Core logic
- [x] Add `TurretPlacement` node to `game.tscn` under World
- [x] Wire input in `turret_placement.gd` for B key and mouse

### Phase 2: UI Integration

- [x] Connect terminal command flow to placement mode (`TURRET <TYPE>`)
- [x] Allow tactical minimap click-to-place while terminal is open
- [ ] Create richer build panel UI with explicit buttons/cards
- [ ] Show materials count

### Phase 3: Dismantle

- [x] Add dismantle detection (player near turret + B pressed)
- [x] Refund materials
- [x] Remove turret from scene

---

## Node Hierarchy

```
GameRoot (game.tscn)
├── World
│   ├── TurretPlacement (NEW - turret_placement.gd)
│   ├── Operator
│   ├── Sectors
│   └── ...
└── UI
    ├── TerminalPanel
    └── BuildPanel (NEW - optional, via terminal)
```

---

## Data Flow

```
[Player Input B or terminal command TURRET <TYPE>]
    → TurretPlacement.enter_placement_mode(type)
    → UI updates to show ghost preview
    → Player clicks world OR tactical minimap
    → TurretPlacement._attempt_place_turret()
    → Deduct materials from GameState
    → Instantiate turret scene
    → Add to world
    → Emit turret_placed signal
```

---

## Edge Cases

| Case | Handling |
|------|----------|
| Insufficient materials | Button disabled, tooltip shows cost |
| Max turrets reached | Button disabled, "Power banks full" message |
| Invalid placement (wall) | Ghost turns red, click does nothing |
| Placement on enemy | Ghost turns red, click does nothing |
| Dismantle last turret | Works normally, frees power bank |
| Pick up placed turret | Enters placement mode with carried turret, no extra material cost |

---

## Related Systems

- **GameState.materials** — Currency for turrets
- **Shrumb kills** — Source of materials
- **Power system** — Max turret count (later)

---

## Questions (ANSWERED)

- [x] Max turrets per contract? → 10 (power banks)
- [x] Can turrets be sold/removed? → Yes, dismantle with B key for 50% refund
- [x] Turret placement hotkey binding? → B key
