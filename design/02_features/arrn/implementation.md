# ARRN Implementation Roadmap

**Project:** CUSTODIAN  
**Feature:** Automated Relay Routing Network (ARRN)  
**Created:** 2026-03-27  
**Status:** Runtime V1 Implemented  
**Last Updated:** 2026-05-15
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

---

## Overview

The **Automated Relay Routing Network (ARRN)** is a strategic progression system where players discover, stabilize, and sync with remote relay stations to unlock gameplay benefits, interpretive leverage, and world-lore recovery.

In fiction, ARRN is not just a communications network. It is the surviving field-facing relay spine of the old continuity lattice: an array of **epistemic anchors** that helps the Hub restore context density, compare fragments, and recover confidence-bearing interpretation.

### Core Loop

```
1. SCAN RELAYS    → Discover relay network status (from COMMAND)
2. TRAVEL TO      → Move to relay sector in the world
3. STABILIZE     → Perform field task to stabilize relay
4. RETURN        → Return to COMMAND
5. SYNC          → Upload packets, gain knowledge index
6. UNLOCK        → Benefits unlocked based on knowledge level
```

### Player Experience

- **Pre-scan:** Relay locations unknown, no network benefits
- **Post-scan:** Relay status revealed in terminal (STABLE/WEAK/DORMANT/UNKNOWN)
- **Stabilize:** Player travels to relay sector, initiates stabilization task
- **Sync:** Return to COMMAND center, sync packets → knowledge progression
- **Benefits:** Each knowledge level unlocks permanent bonuses

### Fiction / Presentation Rules

- ARRN should be presented as restoring trusted linkage and comparison capacity, not merely “making the signal better.”
- Syncing packets should be framed as recovering context, not as generic XP conversion.
- Player-facing text should preserve the distinction between **signal recovery** and **truth recovery**.
- Weak or dormant relays should reduce confidence and fidelity, not just convenience.

---

## Architecture

### Data Model

```gdscript
# RelayNode - Individual relay station
class_name RelayNode
extends Node2D

enum Status { UNKNOWN, LOCATED, UNSTABLE, STABLE, WEAK, DORMANT }
enum RiskProfile { TRANSIT, FRINGE, CORE }

@export var relay_id: StringName  # "R_NORTH", "R_SOUTH", "R_ARCHIVE", "R_GATEWAY"
@export var sector_id: StringName # "T_NORTH", "T_SOUTH", "ARCHIVE", "GATEWAY"
@export var status: Status = Status.UNKNOWN
@export var stability: float = 40.0  # 0-100
@export var stability_ticks_required: int = 3
@export var risk_profile: RiskProfile = RiskProfile.TRANSIT
@export var last_stabilized_time: int = -1

# Visual state
@export var is_interactable: bool = false
@export var current_signal_strength: float = 0.0
```

```gdscript
# ARRNManager - Network controller (Autoload/Global)
class_name ARRNManager
extends Node

# Network state
var relay_nodes: Dictionary = {}
var knowledge_index: int = 0
var knowledge_track: String = "RELAY_RECOVERY"
var relay_packets_pending: int = 0
var dormancy_pressure: int = 0

# Knowledge benefits (unlocked at each level)
var benefits: Dictionary = {
    "signal_reconstruction_i": false,
    "maintenance_archive_i": false,
    "threat_forecast_i": false,
    "fab_blueprints_archive": false,
    "logistics_optimization": false,
    "signal_reconstruction_ii": false,
    "archival_synthesis": false,
}

# Constants (from Python)
const KNOWLEDGE_MAX: int = 7
const RELAY_STABLE_MIN: float = 70.0
const RELAY_WEAK_MIN: float = 30.0
const RELAY_STABILITY_MAX: float = 100.0
const WEAK_SYNC_FAIL_CHANCE: float = 0.10
const RELAY_DECAY_BASE: float = 0.5
const RELAY_DECAY_PER_ASSAULT: float = 0.2
const KNOWLEDGE_DRIFT_PERIOD: int = 40
```

### Default Relay Configuration

| Relay ID | Sector | Initial Status | Initial Stability | Risk Profile | Ticks Required |
|----------|--------|---------------|-------------------|--------------|---------------|
| R_NORTH | T_NORTH | LOCATED | 80.0 | TRANSIT | 3 |
| R_SOUTH | T_SOUTH | LOCATED | 80.0 | TRANSIT | 3 |
| R_ARCHIVE | ARCHIVE | UNKNOWN | 40.0 | FRINGE | 4 |
| R_GATEWAY | GATEWAY | UNKNOWN | 40.0 | FRINGE | 4 |

---

## Knowledge Progression System

### Knowledge Levels & Unlocks

| Level | Unlock | Benefit Description |
|-------|--------|---------------------|
| 1 | SIGNAL_RECONSTRUCTION_I | Basic signal recovery, improves fidelity |
| 2 | MAINTENANCE_ARCHIVE_I | Remote repair cost -1 |
| 3 | THREAT_FORECAST_I | Enemy approach warning ticks bonus |
| 4 | FAB_BLUEPRINTS_I | Archive fabrication blueprints unlocked |
| 5 | LOGISTICS_OPTIMIZATION_I | Logistics penalty modifier (0.9x) |
| 6 | SIGNAL_RECONSTRUCTION_II | Advanced signal recovery (improves LOST/FRAGMENTED) |
| 7 | ARCHIVAL_SYNTHESIS | Full network mastery, halves dormancy pressure |

These unlocks should be treated fictionally as increased interpretive capability and continuity recovery, not as abstract level-ups.

### Fidelity Interaction

The ARRN directly affects the **comms fidelity** system:

| Fidelity | Relay Benefit | Effect |
|----------|---------------|--------|
| LOST | SIGNAL_RECONSTRUCTION_II | → DEGRADED |
| FRAGMENTED | SIGNAL_RECONSTRUCTION_II | → DEGRADED |
| DEGRADED | SIGNAL_RECONSTRUCTION_I | → FULL |
| FULL | — | No change |

Important fiction guardrail: improved fidelity does **not** mean the system becomes omniscient. It means the Hub can compare, correlate, and judge with higher confidence.

---

## Components

### 1. Relay Entities (`entities/relay/`)

```
entities/relay/
├── relay.gd                  # Main relay entity
├── relay.tscn                # Relay scene
├── relay_antenna.gd          # Animated antenna visual
├── signal_indicator.gd       # Signal strength visualizer
├── relay_interaction.gd      # Player interaction trigger
└── relay_scan_effect.gd      # Visual effect for scanning
```

**Relay Visual States:**

| Status | Visual Indicator | Color |
|--------|-----------------|-------|
| UNKNOWN | Hidden/dimmed | Gray (#666666) |
| LOCATED | Pulsing weak signal | Yellow (#FFCC00) |
| UNSTABLE | Flickering | Orange (#FF6600) |
| STABLE | Strong steady signal | Green (#00FF00) |
| WEAK | Dim stable | Amber (#FF9900) |
| DORMANT | No signal | Red (#FF0000) |

### 2. ARRN Manager (`core/systems/arrn/`)

```
core/systems/arrn/
├── arrn_manager.gd           # Main autoload
├── relay_network.gd          # Network state management
├── knowledge_system.gd        # Knowledge progression
├── stabilization_task.gd      # Field stabilization logic
├── sync_mechanic.gd          # Command sync logic
├── signal_decay.gd           # Tick-based decay
└── benefits_manager.gd        # Benefit activation
```

### 3. Terminal Integration (`entities/terminal/`)

Extend existing terminal commands:

```
# New/Modified Commands
SCAN RELAYS     → Reveals relay network status (command mode)
STABILIZE RELAY → Initiates field stabilization (field mode)
SYNC            → Uploads packets at command center
STATUS RELAY    → Detailed relay view (existing status command)
```

### 4. UI Components (`ui/arrn/`)

```
ui/arrn/
├── relay_network_hud.gd      # Mini-map relay overlay
├── knowledge_progress.gd      # Knowledge index display
├── relay_status_panel.gd     # In-terminal relay display
└── packet_indicator.gd       # Pending packets visual
```

---

## Implementation Phases

### Phase 1: Foundation (Priority: HIGH)

**Goal:** Core data model and basic relay entities

#### Tasks

- [ ] Create `ARRNManager` autoload singleton
- [ ] Define `RelayNode` class with all properties
- [ ] Initialize default relay configuration (4 relays)
- [ ] Create relay `.tscn` scenes with base visuals
- [ ] Place relay entities in procgen world at correct sectors
- [ ] Add relay visibility states (hidden until scanned)

**Files to Create:**
- `res://core/systems/arrn/arrn_manager.gd`
- `res://core/systems/arrn/relay_data.gd` (data definitions)
- `res://entities/relay/relay.tscn`
- `res://entities/relay/relay.gd`

**Dependencies:**
- GameState autoload (for time ticks)
- ProcGenRuntime (for sector positions)

---

### Phase 2: Scanning System (Priority: HIGH)

**Goal:** SCAN RELAYS reveals network status in terminal

#### Tasks

- [ ] Implement `scan_network()` in ARRNManager
- [ ] Connect to terminal command processor
- [ ] Display relay status with fidelity awareness (LOST/FRAGMENTED/DEGRADED/FULL)
- [ ] Add scan cooldown (if needed)
- [ ] Visual feedback for scan action

**Terminal Output (FULL fidelity):**
```
RELAY NETWORK:
- R_NORTH: STABLE | SECTOR T_NORTH | STABILITY 80 | STABILIZE 3 TICKS
- R_SOUTH: STABLE | SECTOR T_SOUTH | STABILITY 80 | STABILIZE 3 TICKS
- R_ARCHIVE: UNKNOWN | SECTOR ARCHIVE | STABILITY 40 | STABILIZE 4 TICKS
- R_GATEWAY: UNKNOWN | SECTOR GATEWAY | STABILITY 40 | STABILIZE 4 TICKS
PENDING PACKETS: 0
KNOWLEDGE INDEX: 0/7
DORMANCY PRESSURE: 0
```

**Files to Modify:**
- `res://entities/terminal/terminal.gd` - Add SCAN RELAYS handler
- `res://core/systems/arrn/arrn_manager.gd` - Add scan logic

---

### Phase 3: Stabilization (Priority: HIGH)

**Goal:** Player can travel to relay and initiate stabilization

#### Tasks

- [ ] Add player proximity detection to relay
- [ ] Implement interaction prompt (E key) when near relay
- [ ] Create stabilization task system (tick-based)
- [ ] Prevent combat movement during stabilization
- [ ] Visual progress indicator during stabilization
- [ ] Complete stabilization → packet generated

**Interaction Flow:**
1. Player approaches relay entity
2. Interaction prompt appears: "[E] Stabilize Relay"
3. Player presses E → stabilization begins
4. Progress bar fills over N ticks (3-4 depending on relay)
5. On complete: status → STABLE, stability → 100, packets_pending += 1
6. Player must return to COMMAND for sync

**Files to Create:**
- `res://entities/relay/relay_interaction.gd`
- `res://core/systems/arrn/stabilization_task.gd`

**Files to Modify:**
- `res://entities/operator/operator.gd` - Add task state
- `res://core/systems/arrn/arrn_manager.gd` - Task management

---

### Phase 4: Sync & Knowledge (Priority: HIGH)

**Goal:** SYNC command at COMMAND center unlocks benefits

#### Tasks

- [ ] Implement sync calculation (packet success rate based on weak relays)
- [ ] Knowledge index progression (0-7)
- [ ] Benefit activation based on level
- [ ] Dormancy pressure calculation
- [ ] Knowledge drift mechanic (lose progress if dormancy >= 3)

**Sync Algorithm:**
```
packets = relay_packets_pending
weak_count = count(relays where status == WEAK)
failed = 0
for each weak relay:
    if random() < 0.10: failed += 1
successful = packets - failed
active_relays = count(relays where status in [STABLE, WEAK])
weak_ratio = weak_count / active_relays
effective_gain = round(successful * (1.0 - 0.5 * weak_ratio))
new_level = min(KNOWLEDGE_MAX, current + effective_gain)
```

**Terminal Output:**
```
SYNC COMPLETE: 2 PACKETS.
KNOWLEDGE INDEX RELAY_RECOVERY=2.
BENEFIT ACTIVE: REMOTE REPAIR COST -1.
```

**Files to Modify:**
- `res://entities/terminal/terminal.gd` - Add SYNC handler
- `res://core/systems/arrn/arrn_manager.gd` - Add sync logic

---

### Phase 5: Tick System & Decay (Priority: MEDIUM)

**Goal:** Relays decay over time, especially during assaults

#### Tasks

- [ ] Implement `tick_relays()` called every game tick
- [ ] Decay rate increases during active assaults
- [ ] Active stabilization prevents decay for that relay
- [ ] Dormancy pressure calculation
- [ ] Knowledge drift (lose level if pressure >= 3 and time % 40 == 0)

**Decay Formula:**
```
decay_rate = RELAY_DECAY_BASE + (active_assaults * RELAY_DECAY_PER_ASSAULT)
stability = max(0, stability - decay_rate)
status = STABLE if stability >= 70
       = WEAK if stability >= 30
       = DORMANT if stability < 30
```

**Files to Modify:**
- `res://core/systems/arrn/arrn_manager.gd` - Add tick logic
- `res://core/game.gd` or `res://core/wave_manager.gd` - Hook into tick

---

### Phase 6: Benefit Integration (Priority: MEDIUM)

**Goal:** Active benefits affect gameplay systems

#### Tasks

- [ ] **SIGNAL_RECONSTRUCTION_I:** Pass to fidelity system (already in design)
- [ ] **MAINTENANCE_ARCHIVE_I:** Reduce repair costs by 1
- [ ] **THREAT_FORECAST_I:** Add warning ticks to assault approach
- [ ] **FAB_BLUEPRINTS_I:** Unlock Archive fabrication recipes
- [ ] **LOGISTICS_OPTIMIZATION_I:** Apply 0.9x penalty to logistics
- [ ] **SIGNAL_RECONSTRUCTION_II:** Enhanced fidelity improvement
- [   ] **ARCHIVAL_SYNTHESIS:** Halve dormancy pressure

**Implementation Approach:**

Each benefit is queried by the relevant system:
```gdscript
# Example: Repair cost reduction
func get_repair_cost(base_cost: int) -> int:
    if ARRNManager.benefits["maintenance_archive_i"]:
        return max(1, base_cost - 1)
    return base_cost
```

---

### Phase 7: Visuals & Polish (Priority: LOW)

**Goal:** Make ARRN visually compelling

#### Tasks

- [ ] Relay antenna rotation animation
- [ ] Signal strength particle effects
- [ ] Stabilization progress bar
- [ ] Sync upload visual effect
- [ ] Knowledge levelup celebration
- [ ] Mini-map relay markers
- [ ] Audio: relay hum, scan ping, sync complete

---

## Terminal Command Reference

### SCAN RELAYS

- **Mode:** COMMAND (only works at COMMAND center)
- **Fidelity Effect:** 
  - LOST: "RELAY SCAN: NO SIGNAL."
  - FRAGMENTED: "SIGNAL IRREGULAR. CONTACT REQUIRES FIELD VERIFICATION."
  - DEGRADED: Shows status names only (no stability values)
  - FULL: Full details with stability and ticks

### STABILIZE RELAY \<ID\>

- **Mode:** FIELD (must be at relay sector)
- **Preconditions:**
  - Not in COMMAND mode
  - No active task/repair
  - At correct relay sector
  - Relay not already STABLE
- **Action:** Starts stabilization task (3-4 ticks)

### SYNC

- **Mode:** COMMAND (only at COMMAND center)
- **Precondition:** relay_packets_pending > 0
- **Action:** Converts packets to knowledge index, applies benefits

---

## Integration Points

### Existing Systems

| System | Integration | Phase |
|--------|-------------|-------|
| Terminal | New commands | 2, 4 |
| GameState | Time/tick integration | 1 |
| WaveManager | Assault count for decay | 5 |
| Fidelity | Signal reconstruction benefits | 6 |
| Fabrication | Blueprint unlocking | 6 |
| Repairs | Cost reduction | 6 |
| Logistics | Penalty modifier | 6 |

### New Files Summary

```
custodian/
├── core/
│   └── systems/
│       └── arrn/
│           ├── arrn_manager.gd        # [NEW] Main autoload
│           ├── relay_data.gd          # [NEW] Data definitions
│           ├── knowledge_system.gd    # [NEW] Knowledge logic
│           ├── stabilization_task.gd   # [NEW] Field task
│           └── benefits_manager.gd     # [NEW] Benefit queries
│
├── entities/
│   └── relay/
│       ├── relay.gd                   # [NEW] Entity
│       ├── relay.tscn                 # [NEW] Scene
│       ├── relay_interaction.gd       # [NEW] Player interaction
│       └── signal_indicator.gd        # [NEW] Visual component
│
└── ui/
    └── arrn/
        ├── knowledge_progress.gd      # [NEW] HUD element
        └── relay_status_panel.gd      # [NEW] Terminal panel
```

---

## Testing Checklist

### Unit Tests

- [ ] Knowledge progression (0 → 7 → 0)
- [ ] Stabilization task completion
- [ ] Sync packet calculation
- [ ] Benefit activation at correct levels
- [ ] Decay during assault
- [ ] Knowledge drift at high dormancy

### Integration Tests

- [ ] SCAN RELAYS shows correct fidelity-aware output
- [ ] STABILIZE requires correct location
- [ ] SYNC requires COMMAND mode
- [ ] Benefits affect other systems (repairs, fabrication)
- [ ] Relays visible on map after scan

### Manual Tests

- [ ] Full player loop: scan → travel → stabilize → return → sync
- [ ] Decay during active assault
- [ ] Multiple relays stabilizing sequentially
- [ ] Knowledge drift prevention (ARCHIVAL_SYNTHESIS)

---

## Future Expansions

### Extended Features (Post-v1.0)

1. **Relay Signal Hijacking** - Enemies can temporarily disable relays
2. **Multi-Frequency Tuning** - Different relay frequencies for different benefits
3. **Emergency Override** - High-risk high-reward relay capture
4. **Relay Chain Routing** - Connect relays for bonus effects
5. **Historical Data** - View past relay network states

### Cross-System Expansions

1. **Power Grid Integration** - Relays route power to distant sectors
2. **Drone Network** - Drones use relay network for coordination
3. **Long-Range Sensors** - Relay network enables early warning

---

## Reference Files

### Python Source (Migration Reference)

- `python-sim/game/simulations/world_state/core/relays.py` - Core logic
- `python-sim/game/simulations/world_state/terminal/commands/relay.py` - Commands
- `python-sim/game/simulations/world_state/core/power.py` - Fidelity integration

---

## Status Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-03-27 | Created | Initial implementation plan |
| 2026-05-15 | Runtime V1 implemented | Added ARRNManager autoload, default relay state, relay world entities, procgen placement, terminal scan/status/stabilize/sync commands, tick decay/drift, knowledge benefits, repair/fabrication hooks, and minimap relay markers. Production relay art/audio, save/load, and richer relay UI remain future polish. |

---

*This document defines the complete ARRN implementation. Update MASTER_ROADMAP.md with task assignments.*
