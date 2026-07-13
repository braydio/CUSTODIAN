# GAMEPLAY NOTES

> ⚠️ **IMPORTANT:** These notes have been incorporated into the design docs. See links in each entry.
> 
> **Master Roadmap:** [`00_meta/MASTER_ROADMAP.md`](00_meta/MASTER_ROADMAP.md)
> **Tracking:** Archived to `00_meta/archived/TRACKING.md` — superseded by MASTER_ROADMAP.md

---

## Run 001 Notes (Incorporated)

### ✅ Incorporated

| Note | Design Doc | Action |
|------|------------|--------|
| Need to have the custodian movement speed slowed when reloading | [`02_features/operator/implementation.md`](02_features/operator/implementation.md) | Added to RELOAD state design - slow movement during reload |
| For testing, let's do fewer waves during an assault. 3-5 then we can decide the loop is locked and build from there | [`02_features/wave_spawning/WAVE_SPAWNING_SYSTEM.md`](02_features/wave_spawning/WAVE_SPAWNING_SYSTEM.md) | Update wave_manager config to 3-5 waves for testing |
| The command terminal needs an actual live minimap of the current procgen world, not whatever janky instance they have currently | [`01_systems/COMMAND_TERMINAL_UI.md`](01_systems/COMMAND_TERMINAL_UI.md) | Add to COMMAND TERMINAL UI design |
| The walk northwest animation has a weird bounce/glitch on the first frame | [`02_features/operator/implementation.md`](02_features/operator/implementation.md) | Added to animation states - needs fix |
| Other than that, all default locomotion is perfect | — | Confirmed - no action needed |

### Animation Needs (from Run 001)

**Doc:** [`02_features/operator/implementation.md`](02_features/operator/implementation.md)

| Animation | Status | Priority |
|-----------|--------|----------|
| Reloading while moving | Design exists | P2 |
| animation_base_idle | Needs creation | P2 |
| animation_base_stance (melee and ranged) | Needs creation | P2 |

---

## Run 002 Notes (Incorporated)

### ✅ Incorporated

| Note | Design Doc | Action |
|------|------------|--------|
| A bug happened where I spawned stuck between the terminal and a wall corner in the command building | [`03_architecture/COMPOUND_TILE_SYSTEM.md`](03_architecture/COMPOUND_TILE_SYSTEM.md) | Add spawn point validation to procgen |
| Also, we need a way to differentiate the different sector buildings? | [`03_architecture/COMPOUND_TILE_SYSTEM.md`](03_architecture/COMPOUND_TILE_SYSTEM.md) | Add sector visual differentiation system |

---

## Action Items Added to Roadmap

The following items were added to [`MASTER_ROADMAP.md`](00_meta/MASTER_ROADMAP.md) based on gameplay notes:

### New v0.9.1 (Animation & Polish Fixes)

| Feature | Priority | Notes |
|---------|----------|-------|
| Reload state with movement speed penalty | P1 | From gameplay note - slows movement |
| 3-5 wave testing config | P2 | Reduce waves for testing loop |
| Command terminal live minimap | P1 | Replace janky minimap |
| Walk animation bounce fix | P2 | Northwest animation glitch |
| Spawn collision prevention | P1 | Prevent stuck spawning |
| Sector visual differentiation | P2 | Different building types |

---

## Original Notes (Archive)

```
Notes I took while running a live playthough
  - Need to have the custodian movement speed slowed when reloading
  - For testing, let's do fewer waves during an assault. 3-5 then we can decide the loop is locked and build from there
  - The command terminal needs an actual live minimap of the current procgen world, not whatever janky instance they have currently
  - The walk northwest animation has a weird bounce/glitch on the first frame
  - Otherthan that, all default locomotion is perfect

Animation Needs:
  - Reloading while moving
  - animation_base_idle
  - animation_base_stance (melee and ranged)
  - 

# Run 002
  - A bug happened where I spawned stuck between the terminal and a wall corner in the command building (I beleive)
  - Also, we need a way to differentiate the different sector buildings?
```

---

*This file is now an archive. All actionable items are in MASTER_ROADMAP.md*
