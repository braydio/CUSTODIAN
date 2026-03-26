# CUSTODIAN Command Terminal - Development Roadmap

Based on: `COMMAND_TERMINAL_UI.md`

---

## Phase 1: Core UI Layout (Priority: Critical)

### 1.1 Create Terminal Scene
- [ ] Create `custodian/ui/scenes/custodian_terminal.tscn` from provided .tscn
- [ ] Verify node hierarchy matches design
- [ ] Apply `custodian_theme.tres` theme

### 1.2 Top Bar Implementation
- [ ] System status label (left) - "CUSTODIAN NODE // CONTRACT ACTIVE"
- [ ] Planet name + contract ID (center)
- [ ] SIM: 60 TPS indicator (right)
- [ ] Threat level color-coded (green/yellow/red)
- [ ] Power utilization %

### 1.3 Activity Feed Panel (Left)
- [ ] ScrollContainer + RichTextLabel setup
- [ ] Color-coded logging: green (success), yellow (warning), red (critical)
- [ ] Timestamp formatting: [HH:MM:SS]
- [ ] Auto-scroll to newest entry
- [ ] Click-to-focus event → highlights map sector
- [ ] Periodic trimming for performance (keep last 1000 lines)

### 1.4 Planet View Panel (Center)
- [ ] SubViewportContainer setup
- [ ] Slowly rotating planet mesh
- [ ] Orbital markers (relays, satellites)
- [ ] Threat vectors (incoming assault trajectories)
- [ ] Contract zones highlighted
- [ ] Click → zoom into region → transitions to local map

### 1.5 Tactical Map Panel (Right)
- [ ] SubViewportContainer setup
- [ ] Tile-based grid (30-40 tile sectors)
- [ ] Entity rendering: turrets, enemies, operator
- [ ] Turret states: idle/firing/damaged
- [ ] Enemy pathing + targeting visualization
- [ ] Sector damage overlays

### 1.6 Overlay Layers (Toggleable)
- [ ] Power grid overlay
- [ ] Pathing/nav overlay
- [ ] Threat heatmap overlay
- [ ] Repair targets overlay

### 1.7 Command Bar (Bottom)
- [ ] LineEdit for command input
- [ ] Autocomplete system (from command tree)
- [ ] Inline validation
- [ ] Ghost preview on map before commit

---

## Phase 2: Command System (Priority: High)

### 2.1 Command Parser
- [ ] Parse command string into action + parameters
- [ ] Support: `allocate_defense sector=X weight=Y`
- [ ] Support: `deploy turret_sniper x=Y y=Z`
- [ ] Support: `focus relay_network priority=X`

### 2.2 Command Execution Mode
- [ ] **DECISION REQUIRED:** Immediate (arcade) vs Buffered (simulation)
- [ ] Given deterministic sim goals → Buffered execution
- [ ] Commands queue into tick system
- [ ] Visual feedback during queuing

### 2.3 Command Autocomplete
- [ ] Command tree lookup
- [ ] Parameter suggestions
- [ ] Syntax validation inline

---

## Phase 3: Integration (Priority: High)

### 3.1 Simulation Hookup
- [ ] Connect activity feed to simulation event system
- [ ] Real-time updates from game state
- [ ] Click events → simulation mutations

### 3.2 Planet ↔ Map Transitions
- [ ] Planet click → zoom to sector
- [ ] Map context → planet indicator
- [ ] Smooth transition animations

### 3.3 Game State Binding
- [ ] Bind SIM TPS to actual tick rate
- [ ] Bind threat level to enemy activity
- [ ] Bind power % to actual power system

---

## Phase 4: Polish (Priority: Medium)

### 4.1 Performance Optimization
- [ ] Activity feed line trimming
- [ ] Viewport render optimization
- [ ] Entity culling off-screen

### 4.2 Visual Polish
- [ ] Theme-consistent styling
- [ ] Smooth animations
- [ ] Hover states
- [ ] Focus indicators

### 4.3 Sound (Optional)
- [ ] Event sounds (warning, critical)
- [ ] Command submission sound

---

## Node Structure Reference

```
CustodianTerminal (Control)
└── RootMargin (MarginContainer)
    └── MainVBox (VBoxContainer)
        ├── TopBar (HBoxContainer)
        │   ├── SystemLabel
        │   └── StatusLabel
        ├── MainSplit (HBoxContainer)
        │   ├── ActivityPanel (PanelContainer)
        │   │   └── ActivityVBox
        │   │       ├── ActivityHeader
        │   │       └── ActivityScroll
        │   │           └── ActivityLog (RichTextLabel)
        │   ├── PlanetPanel (PanelContainer)
        │   │   └── PlanetVBox
        │   │       ├── PlanetHeader
        │   │       └── PlanetViewportContainer
        │   │           └── PlanetViewport (SubViewport)
        │   └── MapPanel (PanelContainer)
        │       └── MapVBox
        │           ├── MapHeader
        │           └── MapViewportContainer
        │               └── MapViewport (SubViewport)
        └── CommandBar (HBoxContainer)
            ├── Prompt
            └── CommandInput (LineEdit)
```

---

## Key Design Decisions Needed

### 1. Execution Mode (CRITICAL)
- **A. Immediate** - commands apply instantly (arcade feel)
- **B. Buffered** - commands queue into tick system (simulation feel)

*Recommendation: B (Buffered) per deterministic sim goals*

### 2. Activity Feed Source
- Direct simulation events?
- Centralized event bus?
- Existing logging system hookup?

### 3. Planet/Tactical Data
- Separate scenes or single scene with modes?
- Viewport communication method?

---

## Dependencies

- `custodian/ui/theme/custodian_theme.tres` - must exist
- Simulation layer command handlers
- Entity state system
- Power/Threat tracking systems

---

## Estimated Timeline

| Phase | Tasks | Effort |
|-------|-------|--------|
| Phase 1 | Core UI Layout | 2-3 days |
| Phase 2 | Command System | 1-2 days |
| Phase 3 | Integration | 2-3 days |
| Phase 4 | Polish | 1 day |

**Total: ~7-9 days**
