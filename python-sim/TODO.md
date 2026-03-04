# Unified TODO

*Last Updated: 2026-03-03*

## Legend

- `OPEN`: Not implemented.
- `PARTIAL`: Implemented in part; remaining requirements listed.
- `IN_PROGRESS`: Actively being worked on.

---

## Master Design Doctrine

All work must align with `design/MASTER_DESIGN_DOCTRINE.md` (LOCKED v2.0).

---

## Recommended Next Focus

### 1. `OPEN` Godot Project Foundation

- Set up Godot 4.x project structure
- Configure scene hierarchy (main → sectors → entities)
- Implement isometric camera (pan, zoom, fixed angle)
- Add Y-sort for isometric rendering

**Why this is next:** Core engine foundation must be established before any gameplay.

---

### 2. `OPEN` Operator Controller

- Implement WASD movement within sectors
- Add collision detection per sector
- Create weapon slots (melee, ranged, utility)
- Implement basic attack inputs

**Why this is next:** Player embodiment is core to the design identity.

---

### 3. `OPEN` Combat System Prototype

- Hitscan weapon implementation
- Projectile system for heavy weapons
- Damage pipeline (LOS → spread → hit → penetration → damage type)
- Melee attack with range check
- Utility tool (repair, relay interface)

**Why this is next:** Combat is the primary interaction layer.

---

### 4. `OPEN` Sector Base System

- Define sector layout (Command, Power, Defense, Archive, etc.)
- Implement sector navigation/transitions
- Add collision maps per sector
- Create static base structure

**Why this is next:** Base is the tactical playing field.

---

### 5. `OPEN` Assault Wave System

- Real-time enemy spawning at sector ingress
- Basic enemy AI (approach, engage)
- Damage propagation to structures
- Assault resolution and aftermath

**Why this is next:** Assaults are the core gameplay pressure.

---

### 6. `OPEN` Infrastructure Systems

- Power grid simulation
- Logistics throughput model
- Fabrication queue system
- Relay network management

**Why this is next:** Systemic depth distinguishes CUSTODIAN from action games.

---

### 7. `OPEN` Pause & Time Management

- FTL-style hard pause implementation
- Command issuing while paused
- Time scaling (1x, 2x, 4x)
- Projectile/AI freeze on pause

**Why this is next:** Tactical pause is a core design pillar.

---

### 8. `OPEN` Save System

- Full state serialization
- Mid-assault save capability
- Deterministic state reconstruction
- Ironman mode support

---

## Deprecated / Archived

The following are no longer active priorities (superseded by v2.0):

- Terminal-first Python backend development
- External simulation process architecture
- Backend-authoritative command contract
- Legacy terminal UI enhancements

See `design/archive/terminal-deprecated/` for legacy documentation.

---

## Completed (Pre-v2.0 Terminal Era)

These were completed in the Python terminal phase but are not directly carried forward:

- Command parser and processor
- Spatial assault with approach traversal
- Policy/doctrine/allocation/fabrication layers
- Comms fidelity-driven information degradation
- ARRN relay progression system

*These systems need reimplementation in Godot.*
