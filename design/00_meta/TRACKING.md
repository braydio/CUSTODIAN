# CUSTODIAN Task Tracking

**Last Updated:** 2026-03-27  
**Sprint:** 2026-03-27

---

## Sprint Backlog

### This Sprint (2026-03-27)

| ID | Task | Priority | Status | Assignee |
|----|------|----------|--------|----------|
| S-001 | Fix camera procgen bounds | P0 | 🔴 In Progress | - |
| S-002 | Fix camera snap to player spawn | P0 | 🔴 In Progress | - |
| S-003 | Move terminal to procgen coords | P1 | 🔴 In Progress | - |
| S-004 | Move ammo caches to procgen coords | P1 | 🔴 In Progress | - |
| S-005 | Register camera to "camera" group | P0 | 🔴 In Progress | - |
| S-006 | Verify mouse aim correction | P1 | 🟡 Pending | - |
| S-007 | Integrate shadow system | P2 | 🟡 Pending | - |
| S-008 | Weapon data system integration | P2 | 🟡 Pending | - |

---

## Issue Tracker

### Critical Issues

| ID | Issue | Impact | Status | Notes |
|----|-------|--------|--------|-------|
| C-001 | Camera uses legacy sector bounds | Can't aim correctly | 🔴 Open | HIGH priority |
| C-002 | Firing direction wrong | Bullets miss target | 🔴 Open | Related to C-001 |
| C-003 | Screen shake not working | No game feel | 🔴 Open | Camera not in group |

### Medium Issues

| ID | Issue | Impact | Status | Notes |
|----|-------|--------|--------|-------|
| M-001 | Terminal in wrong position | Unreachable in procgen | 🔴 Open | Need coords update |
| M-002 | Ammo caches not repositioned | Can't access ammo | 🔴 Open | Need coords update |
| M-003 | Compound sectors not entities | No prep gameplay | 🟡 In Progress | Design exists |

### Low Issues

| ID | Issue | Impact | Status | Notes |
|----|-------|--------|--------|-------|
| L-001 | Animation states incomplete | Limited visuals | 🟡 In Progress | Reload/interact pending |
| L-002 | Procgen layout tuning | Map variety | 🟡 In Progress | Open/cave balance |

---

## Feature Progress

### Procgen Handoff (v0.3.0)

- [ ] Camera derives bounds from `World/ProcGenRuntime` tilemaps
- [ ] Camera snaps to procgen player spawn on load
- [ ] Terminal repositioned to procgen coords
- [ ] Ammo caches repositioned to procgen coords
- [ ] Camera joins "camera" group
- [ ] Mouse aim uses correct world position

### Mission Flow

- [ ] GameState has phase enum
- [ ] Phase transitions work correctly
- [ ] WaveManager only active during ASSAULT_ACTIVE
- [ ] Phase indicator in HUD

### Free-Roam Pre-Assault

- [ ] Player can traverse procgen compound
- [ ] Scavenge/pickup system
- [ ] Power routing between structures
- [ ] Fortification placement
- [ ] Terminal has prep commands
- [ ] Manual assault trigger works

### ARRN (Relay Network)

**Doc:** `02_features/arrn/implementation.md`

### World Expansion & The Hub

**Doc:** `02_features/world_expansion/implementation.md`

#### World Manager
- [ ] Create world_manager.gd autoload
- [ ] Implement world state enum (COMPOUND, REGION, TRANSIT)
- [ ] World transition system

#### Hub System
- [ ] Hub data classes (Region, Difficulty, Setting, ThreatProfile, etc.)
- [ ] Scenario generator (deterministic seed-based)
- [ ] Knowledge system (outcome processing)
- [ ] Terminal Hub UI
- [ ] Campaign history tracking

#### Compound Tiles
- [ ] Wall tile entity system
- [ ] Tile types (standard, reinforced, destructible, power conduit)
- [ ] Sector building from tiles
- [ ] Power routing through walls
- [ ] Door/gate systems

#### Region Worlds
- [ ] Biome-based tilesets
- [ ] Objective placement system
- [ ] Threat zone generation
- [ ] Environmental hazards

#### Phase 1: Foundation
- [ ] Create ARRNManager autoload
- [ ] Define RelayNode class
- [ ] Initialize 4 default relays
- [ ] Create relay scenes with visuals
- [ ] Place relays in procgen sectors

#### Phase 2: Scanning
- [ ] Implement scan_network() 
- [ ] Add SCAN RELAYS terminal command
- [ ] Fidelity-aware output (LOST/FRAGMENTED/DEGRADED/FULL)

#### Phase 3: Stabilization
- [ ] Player proximity detection
- [ ] Interaction prompt (E key)
- [ ] Stabilization task (tick-based)
- [ ] Packet generation on complete

#### Phase 4: Sync & Knowledge
- [ ] SYNC command at COMMAND
- [ ] Knowledge index 0-7 progression
- [ ] Benefit activation system
- [ ] Dormancy pressure calculation

#### Phase 5: Tick & Decay
- [ ] tick_relays() every game tick
- [ ] Assault-aware decay rate
- [ ] Knowledge drift mechanic

#### Phase 6: Benefits
- [ ] SIGNAL_RECONSTRUCTION_I (fidelity)
- [ ] MAINTENANCE_ARCHIVE_I (repair cost)
- [ ] THREAT_FORECAST_I (warning)
- [ ] FAB_BLUEPRINTS_I (fab recipes)
- [ ] LOGISTICS_OPTIMIZATION_I (penalty)
- [ ] SIGNAL_RECONSTRUCTION_II (fidelity)
- [ ] ARCHIVAL_SYNTHESIS (dormancy)

---

## Completed This Week

| Date | Task | Notes |
|------|------|-------|
| 2026-03-27 | Shadow system implementation | In progress |
| 2026-03-27 | Weapon data integration | In progress |
| 2026-03-26 | Camera combat integration | Complete |
| 2026-03-26 | Camera system redesign | Complete |

---

## Notes & Context

### Camera Fix Context

The procgen handoff was partially completed but camera integration was not finished. The camera still references `/root/GameRoot/World/Sectors` which are hidden after procgen promotion.

**Files to check:**
- `res://scenes/camera.gd` - camera limits and group registration
- `res://scripts/core/contract_world_loader.gd` - procgen repositioning

### Game Feel Context

Screen shake, hit-stop, knockback, and damage flash all use:
```gdscript
get_tree().get_first_node_in_group("camera")
```

Camera must be in "camera" group for these to work.

---

## Quick Commands

```bash
# Open Godot project
cd ~/Projects/CUSTODIAN/custodian && godot --headless --script-check .

# Run in debug
cd ~/Projects/CUSTODIAN/custodian && godot -d

# Check for .gd file changes
cd ~/Projects/CUSTODIAN && find custodian -name "*.gd" -mtime -1
```

---

*Update this file at the start of each sprint and as issues are resolved.*
