# Active Features — Daily Driver

> ⚠️ **DEPRECATED:** This file is superseded by `design/00_meta/MASTER_ROADMAP.md` as the single source of truth for feature planning. All roadmap planning, milestone tracking, and priority queue management now lives there.
>
> **Process:** Before adding new features, check `MASTER_ROADMAP.md` first. Update `MASTER_ROADMAP.md` when status changes.
>
> This file is retained for reference and will be removed once all readers have migrated.

**Last Updated:** 2026-03-27 (DEPRECATED)
**Purpose:** Daily driver priority list — what's being worked on right now.

---

## Priority Queue

### P0 — Blocking Issues

| Feature | Status | Doc | Notes |
|---------|--------|-----|-------|
| Camera ProcGen Bounds | 🔴 In Progress | `01_systems/CAMERA_SYSTEM.md` | Camera uses legacy sector bounds |
| Camera Snap to Spawn | 🔴 In Progress | `01_systems/CAMERA_SYSTEM.md` | Camera not snapping to procgen spawn |
| Camera Group Registration | 🔴 In Progress | `01_systems/CAMERA_COMBAT_INTEGRATION.md` | Camera not in "camera" group — breaks screen shake |

### P1 — High Priority

| Feature | Status | Doc | Notes |
|---------|--------|-----|-------|
| Terminal ProcGen Reposition | 🔴 In Progress | `02_features/terminal/` | Terminal in wrong position |
| Ammo Cache Reposition | 🔴 In Progress | `02_features/procgen/` | Caches not at procgen coords |
| Mouse Aim Correction | 🟡 Pending | `01_systems/CAMERA_SYSTEM.md` | Firing direction wrong |

### P2 — In Progress

| Feature | Status | Doc | Notes |
|---------|--------|-----|-------|
| Resource Collection & Fabrication | 🧠 Design | `02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md` | Merged pipeline + plan brainstorms |
| Shadow System Integration | 🟡 Pending | `02_features/shadow/implementation.md` | - |
| Weapon Data System | ✅ Done | `02_features/weapon_data/implementation.md` | JSON weapon stats now load |

---

## Active Feature Docs

### Runtime World & Camera Stabilization (P0)
- `02_features/runtime_camera/spec.md`
- `02_features/runtime_camera/plan.md`
- `02_features/runtime_camera/tasks.md`

### Camera Fix (P0) — DEPRECATED, merged into Runtime Camera
- `01_systems/CAMERA_SYSTEM.md`
- `01_systems/CAMERA_COMBAT_INTEGRATION.md`

### ProcGen Handoff (P0-P1)
- `02_features/procgen/AUTHORED_TILED_ROOM_PIPELINE.md`

### Terminal System
- `01_systems/COMMAND_TERMINAL_UI.md`

### Shadow System
- `02_features/shadow/spec.md`
- `02_features/shadow/implementation.md`

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

*This file is the daily driver — update daily based on sprint priorities.*
