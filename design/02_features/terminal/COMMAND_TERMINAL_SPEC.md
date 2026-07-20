# CUSTODIAN Command Terminal - Implementation Specification

**Project:** CUSTODIAN
**Status:** design
**Created:** 2026-04-06
**Author:** PAI-OpenCode
**Last Updated:** 2026-07-20
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

---

## Overview

The Command Terminal is the player's primary interface for strategic decision-making, power routing, defense management, and campaign oversight. It embodies the core game doctrine: information asymmetry between Command Center and field play, power as a routing constraint, and knowledge preservation over raw combat spectacle.

This specification supersedes the earlier `COMMAND_TERMINAL_UI.md` concept and `ROADMAP_COMMAND_TERMINAL.md` roadmap, incorporating the full four-zone layout, thirteen-page structure, and mode-dependent behavior.

This file is the implementation authority for terminal structure. For player-facing lore tone, confidence language, archive semantics, and the rule that systems should speak in procedure rather than exposition, defer to `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`.

---

## Core Design Principles

| Principle | Implementation |
|-----------|----------------|
| Information asymmetry | Terminal fidelity degrades outside Command Center |
| Power as constraint | Global power routing visible only from Command |
| Sectorized defense | Every page preserves sector awareness |
| Deterministic language | STATUS output follows canonical format |
| Loss of clarity | Comms degradation shown as omission, not weakness |

### Runtime identity and unit contracts

- Terminal sector authority is the dedicated `sector` group, filtered to live `Sector` instances. The broader `structure` group includes turrets and other damageable structures and must never determine sector counts, Operator location, system health totals, or priority-sector candidates.
- Power telemetry is expressed in per-second rates: `generated_per_second`, `consumed_per_second`, and `net_per_second`. Terminal renderers consume those values directly and must not multiply them by an assumed frame rate.
- A zero-integrity defense sector is `DESTROYED` regardless of its textual status. Health is a hard lower bound for readiness classification.
- Unimplemented engagement-policy controls must render as unavailable/disabled rather than as apparently selectable mode lists.

### Lore / Language Rules

- The terminal should present **confidence-bearing interpretation**, not omniscient truth.
- Archive and recon surfaces should prefer terms like `Approximate`, `High Confidence`, `Contested`, `Corrupted`, and `Sealed`.
- Machine and transcript language should remain denotative and procedural.
- The terminal should reveal the world through operational evidence, not lore-dump prose.

---

## Four-Zone Layout Model

### Zone A — Header Bar (Always Visible)

**Height:** 1 row (~40px)

**Contents (left to right):**
- `CUSTODIAN // COMMAND LINK`
- Current mode label
- Info fidelity label
- Simulation clock
- Threat bucket
- Assault state
- Power reserve
- Archive state
- Pause/compression state

**Runtime composition:** container-based left identity, center page title, and compact right status chips. The default chip set is simulation time, threat, phase, and grid state; deeper fidelity/archive/rate detail belongs in page content rather than one concatenated header string.

```text
[ CUSTODIAN NODE ] [ OVERVIEW ] [ T+19:14 ] [ THREAT:STABLE ] [ PHASE:FREE ROAM ] [ GRID:STABLE ]
```

**Rules:**
- All caps
- Colors: green/amber/red for emphasis only
- Never scrolls

---

### Zone B — Left Navigation Rail (Always Visible)

**Width:** 220–260px

**Major pages (all reachable):**
1. OVERVIEW
2. STATUS
3. SECTORS
4. POWER
5. DEFENSE
6. FABRICATION
7. SENSORS
8. INCIDENTS
9. ARCHIVE
10. RECON
11. CONTRACTS
12. HISTORY
13. SETTINGS

At the `1366x768` safe-layout target, the default rail presents OVERVIEW, SECTORS, POWER, DEFENSE, FABRICATION, SENSORS, ARCHIVE, and RECON as the primary subset. STATUS, INCIDENTS, CONTRACTS, HISTORY, and SETTINGS live behind `MORE / SYSTEMS`; opening a secondary page keeps that group expanded. The page list is an explicit vertical `ScrollContainer`, while `MORE / SYSTEMS` and WAIT/FOCUS/HARDEN/HELP remain pinned outside it. Mouse-wheel input over the rail or any page button scrolls the page list, and keyboard focus skips hidden pages while keeping the newly focused page visible.

**Default contextual actions:**
- WAIT
- FOCUS
- HARDEN
- HELP

`WAIT 10X`, `RESET`, and danger-class `REBOOT` remain command-line/secondary actions instead of consuming permanent rail height. `REBOOT` requires the explicit protected form `REBOOT CONFIRM`.

**Rules:**
- Keyboard-first: Up/down selects, Enter opens
- Disabled buttons remain visible inside their active primary/secondary group
- FOCUS and HARDEN open modal submenus

---

### Zone C — Main Content Pane

**Behavior:** Changes by page. Supports cards, tables, text blocks, tactical map, split views, modals.

**Key rule:** No page should depend on freeform text entry for routine interaction.

---

### Zone D — Right-Side Transcript / Event Log

**Width:** 320–420px

**Purpose:**
- Boot messages
- System responses
- Command echo
- Incident feed
- Assault notifications
- Archive losses
- Power routing changes

**Entry format:**
```
[TIMESTAMP] [SEVERITY] Message
```

**Severity levels:** INFO, ALERT, CRITICAL, SYSTEM

**Rules:**
- Scrollable, newest at bottom
- Auto-follow newest entries while the transcript is already at the bottom
- Timestamps on every entry
- Clicking opens linked page/sector
- World interaction prompts should resolve the live `interact` binding at runtime rather than hardcoding a specific key label
- On OVERVIEW, the first entries are a synthesized attention feed: current system/link state, grid change, sensor/contact state, and recommended next page/command. After boot completes, boot/procedure chatter collapses into one `BOOT LOG // N PRIOR MESSAGES` entry before the bounded actionable transcript.

---

## Page Specifications

### 1. OVERVIEW

**Purpose:** Default post-boot landing page

**Layout:**
- Top row: Operational Summary, Power Summary, Assault Summary cards
- Middle row: Sector Tactical Map (largest panel)
- Bottom row: Priority Sectors, Active Incidents, Recommended Attention lists
- Bottom-row entries are direct `terminal_action:` links for sector focus and opening the relevant Power, Sectors, Incidents, or Defense page; routine Overview use does not require command-line entry.

**Operational Summary card:**
- Mode, fidelity, current phase
- Command center occupancy
- Operator location
- Total hostiles detected
- Sectors compromised count
- Systems offline count

**Power Summary card:**
- Generation, draw, reserve
- Critical overload warning
- Cold-start systems count
- Current routing profile

**Assault Summary card:**
- Assault state (PENDING, ACTIVE, COMPLETE)
- Active wave/group count
- Enemy archetypes present
- Morale estimate
- Likely ingress axes
- Time since contact

**Sector Tactical Map:**
- Live tactical minimap using the shared Godot `MinimapPanel` / `MinimapView` path; do not use the old placeholder contract-preview texture.
- In Overview mode, the live map draw rect targets 72% of the smaller preview dimension (acceptable range 65-80%); local-to-world conversion must consume that same rect.
- Display per sector: state color, power state, defense readiness, hostile count, objective badge, operator marker
- Click to open SECTORS page focused on sector

**Planet preview:**
- The globe is contextual rather than dominant. It is hidden on OVERVIEW and remains available on STATUS, CONTRACTS, and ARCHIVE.
- Contract body/planet identity is summarized compactly inside Overview operational data.

**Overview fit contract:**
- At a 1366×768 window using the project 1280×720 canvas-safe viewport, top summaries, the live map, all three diagnosis cards, transcript, and command input remain visible without page-level or horizontal scrolling.
- The terminal is modal: gameplay overlays are suppressed, a full-viewport dark scrim intercepts pointer input, and the terminal panel remains above it.
- Opening the terminal makes the system pointer visible and closing it restores the prior mouse mode. GUI input order keeps the scrim before the terminal panel so it blocks gameplay clicks outside the panel without intercepting terminal buttons, links, map interaction, or command input.
- `DEBUG_TERMINAL_LAYOUT_BOUNDS` may outline the safe rect, nav, tactical map, transcript, and command input. Opening the terminal emits their rects, visible nav count, and header-truncation state to `DevObservatory`.

---

### 2. STATUS

**Purpose:** Canonical STATUS output + structured mirrors

**Layout:**
- Left: Raw status output block (exact canonical format)
- Right: Parsed status cards
- Bottom: Information fidelity explanation

**Raw block:** Must preserve exact canonical ordering and omission rules per `INFORMATION_DEGRADATION.md`

**Fidelity explanation:**
- FULL: exact tactical truth
- DEGRADED: generalized counts, posture targets hidden
- FRAGMENTED: activity replaces certainty
- LOST: no usable network truth

When archive/recon/contract data is surfaced, fidelity and confidence should interact. A line can be structurally present but still marked as contested, approximate, or corrupted.

---

### 3. SECTORS

**Purpose:** Primary tactical management

**Layout:**
- Top center: large shared tactical minimap, sized as the page centerpiece rather than a debug preview.
- The minimap title should include the current sector focus (`TACTICAL MAP // FOCUS: <SECTOR>`) when on this page.
- Bottom/center: aligned sector table with stable columns: `NAME | STATE | HP | POWER | PRIORITY | THREAT`.
- Detail card: selected sector summary that answers what is selected, what is wrong, and what actions are available.
- Right shell region: transcript/event log remains available but visually secondary to tactical map/table/detail content.
- The full shell must fit inside a 1366x768 viewport with safe margins; nav labels, top status, bottom helper text, and scrollbars must remain inside their panels.

**Sector list columns:**
- Name, state, HP, power allocation/capacity or known tier, priority, threat.
- Rows must not wrap into each other; long names truncate with an ellipsis.
- Selected sector must be obvious via row marker/color and minimap marker highlight.
- Severity colors: operational/stable green-cyan, degraded/warning amber, damaged/critical/assault red, unknown gray-blue.

**Sector detail fields:**
- Strong header in the form `<NAME> // <STATE>`.
- HP numeric value plus compact bar, power draw/capacity, priority, threat state, active defenses, incidents/notes.
- Missing data should render as `UNKNOWN` or `NONE REPORTED`; do not fabricate tactical precision.

**Actions:**
- OPEN POWER VIEW, PIN SECTOR, SET PRIORITY, TRACK INCIDENTS.
- Actions render as command controls/links with aligned `READY`, `DISABLED`, or future `LOCKED` state labels.
- Clicking a sector table row or sector minimap marker should focus the SECTORS page on that sector when snapshot world positions are available.

**Event log and top status:**
- Event log colors follow severity categories: command/system cyan, power amber, threat/assault red, stable/accepted green.
- Repeated focus-shift messages should compress into a single `FOCUS SHIFTED: A → B` line where possible.
- Negative net grid power must not render as an ambiguous bare `POWER:-N`; label it as grid deficit or net grid value.

---

### 4. POWER

**Purpose:** Power routing and command authority (heart of command)

**Layout:**
- Top: Global power bar + reserve indicator
- Left: Source systems table
- Center: Sector allocation matrix
- Right: Selected system detail
- Bottom: Routing presets + action bar

**Global metrics:**
- Total generation, draw, reserve/deficit
- Overload risk, brownout count, unpowered sectors

**Source systems table columns:**
- Source, output, stability, fuel/input, status

**Sector allocation matrix:**
- Rows: Sectors
- Columns: Defense, sensors, utility, fabrication, reserve
- Each cell: current allocation, requested allocation, priority tier, online time

**Routing presets:**
- BALANCED, DEFENSE FIRST, SENSORS FIRST, FABRICATION FIRST, EMERGENCY LOAD SHED

**Action bar:**
- APPLY ROUTE, TOGGLE SYSTEM, PRIORITIZE SECTOR, RESTORE DEFAULTS

**Rules:**
- Actions only enabled in Command Center
- Outside Command Center: read-only except local field patch preview

---

### 5. DEFENSE

**Purpose:** Defense readiness and target logic

**Layout:**
- Top: Readiness summary
- Left: Defense asset list
- Center: Selected asset detail
- Right: Target priority + engagement rules
- Bottom: Sector defense coverage preview

**Asset list columns:**
- Asset, sector, type, power, readiness, ammo/charge, LOS state, current target, autopilot state

**Target priority modes:**
- FIRST CONTACT, CLOSEST, HEAVIEST, SABOTEURS, BREACHERS, OBJECTIVE THREATS
- (MVP can support 2–3 modes under the hood)

---

### 6. SENSORS

**Purpose:** Awareness asymmetry

**Layout:**
- Top: Fidelity summary
- Left: Sensor asset list
- Center: Tactical intelligence map
- Right: Selected contact list
- Bottom: Prediction strip

**Tactical intelligence map display:**
- Full Command Center + full clarity: hostile positions
- Otherwise: activity tags by sector (entering, moving through, vandalizing, stealing, indexing, idle/loitering)

**Activity labels (canonical):**
- entering, moving through, vandalizing, stealing, indexing, idle, loitering

---

### 7. INCIDENTS

**Purpose:** Event triage

**Layout:** Table with filters above, detail pane below

**Filters:**
- Severity, sector, type, unresolved only, last 1/5/10 minutes

**Incident types:**
- breach, sabotage, theft, power failure, defense offline, archive damage, hostile sighting, morale shift, recon return, command loss, system reboot

**Table columns:**
- Time, severity, sector, type, summary, status, linked page

---

### 8. ARCHIVE

**Purpose:** Knowledge preservation (north star visible)

**Layout:**
- Top: Archive integrity summary
- Left: Knowledge categories tree
- Center: Selected node detail
- Right: Implications / unlocks / losses

**Archive integrity:**
- Integrity %, losses count, corrupted entries, recovered entries, unresolved hypotheses, campaign relevance

**Knowledge categories:**
- governance, propulsion, cognition, warfare, biotech, infrastructure, unknown

**Node detail:**
- Title, category, origin, confidence, recovery source, implications, status (recovered / partial / lost / inferred)

---

### 9. RECON

**Purpose:** Clarity refinement (hub-side meta-operational)

**Layout:**
- Top: Current hypothesis summary
- Left: Available recon targets
- Center: Target detail
- Right: Clarity gain preview

**Recon target fields:**
- Hypothesis ID, domain, current confidence, risk of misread, potential revelation type, recon cost, available after

---

### 10. CONTRACTS

**Purpose:** Hub-side scenario browser

**Layout:**
- Top: Available scenario count, active scenario slot info
- Left: Scenario list
- Center: Selected scenario summary
- Right: Reward/risk/knowledge stake
- Bottom: Actions

**Scenario list columns:**
- ID, archetype, setting, difficulty, core threat, victory condition, confidence

**Actions:**
- ACCEPT, RECON FIRST, DEFER, ARCHIVE NOTE

---

### 11. HISTORY

**Purpose:** Operational history

**Tabs:**
- COMMAND LOG, ASSAULTS, CAMPAIGNS, LOSSES, DISCOVERIES

Chronological records only. Nothing mutates or disappears.

---

### 12. SETTINGS

**Sections:**
- Text scale, log speed, sound toggles, accessibility colors, status verbosity, input mode, confirm-destructive-actions

Keep minimal. No gameplay systems buried here.

---

## Information Architecture by Game Mode

### Hub Mode

**Emphasized pages:** ARCHIVE, RECON, CONTRACTS, HISTORY
**Overview shows:** Scenario proposals, unresolved hypotheses, archive integrity, recent discoveries

### Campaign Command Mode

**Emphasized pages:** OVERVIEW, STATUS, SECTORS, POWER, DEFENSE, SENSORS, INCIDENTS
**All pages fully functional**

### Field/On-foot Mode

**Changes:**
- POWER actions disabled
- SENSORS replaced by rough activity map
- Map becomes "field overlay"
- Transcript still receives events
- Command buttons reduce to: STATUS, SECTORS, INCIDENTS, RETURN TO COMMAND

This preserves asymmetry: command = god's eye, field = inferred and partial.

---

## Boot Flow

1. Black screen
2. `CUSTODIAN LINK INITIALIZING`
3. Hardware/system lines typed in
4. Comms check
5. Archive check
6. Topology sync
7. Sector map projection online
8. Command surface unlock
9. Transition to OVERVIEW

**Post-boot log appends:**
```
STATUS AVAILABLE
WAIT AVAILABLE
WAIT 10X AVAILABLE
FOCUS AVAILABLE
HARDEN AVAILABLE
HELP AVAILABLE
```

---

## Command Vocabulary

**MVP Commands:**
- `status`
- `wait`
- `wait 10x`
- `focus <sector|power|defense|archive>`
- `harden <sector>`
- `help`
- `goto <page>`
- `sector <name>`
- `power preset <name>`
- `reboot`
- `reset`

Command palette opens with `/`. Mirrors visible buttons.

---

## Visual Style Rules

### Aesthetic
- Austere, military-industrial, archival, legible
- No glossy hologram nonsense

### Typography
- Monospaced for raw status and transcript
- Condensed sans or mono for headers
- All caps for system strings

### Color
- Neutral dark background
- Muted green primary
- Amber caution
- Red critical
- Blue only for selected/focused (sparingly)

### Motion
- Boot typing animation
- Subtle row highlight
- Alert flash only on new critical incident
- No constant animated noise

---

## Structural Implementation Rules

1. Build terminal as persistent shell scene with swappable page components
2. Header, nav, transcript, and modal manager are global singleton UI regions
3. Main page content swaps via page controller
4. Never tie core game state to UI widgets — use view models derived from deterministic sim state
5. Raw STATUS output generated by one canonical formatter shared by transcript and STATUS page
6. Sector map widget reads from same sector graph used by gameplay

### Active Godot Split

The current HUD-hosted implementation is being decursified without replacing the existing scene tree in one pass:

- `res://scenes/game.tscn` owns the current terminal Control-node structure.
- `res://game/ui/hud/ui.gd` owns HUD integration, page switching, node binding, and rendering orchestration.
- `res://game/ui/terminal/terminal_command_router.gd` owns command parsing, validation, refresh policy, and the command dispatch boundary.
- `res://game/ui/terminal/terminal_snapshot.gd` owns read-only game-state snapshot aggregation, deterministic `GameState.tick` clock projection (with physics-frame fallback before GameState exists), physical-terminal command authority, Operator location, and sector diagnostic signals.
- `res://game/ui/terminal/terminal_fidelity_policy.gd` derives FULL/DEGRADED/FRAGMENTED/LOST information quality from command-versus-field authority and communications condition.
- `res://game/ui/terminal/terminal_status_formatter.gd` is the sole canonical STATUS text owner used by the STATUS page and typed `STATUS`/`STATUS FULL` commands.
- `res://game/ui/terminal/terminal_overview_view_model.gd` owns deterministic sector ranking, derived active incidents, stable recommendation IDs, offline/cold-start counts, and Overview diagnosis ordering.
- The live terminal map uses `res://game/ui/minimap/minimap_controller.gd` and `minimap_view.gd` for rendering and click-to-world conversion. `res://game/ui/terminal/terminal_map_preview.gd` remains the compatibility texture boundary and uses a 448px Overview fallback instead of the ordinary 256px fallback.
- `res://game/ui/terminal/terminal_planet_preview.gd` owns globe preview viewport state, rotation, zoom, and preview input behavior.

PNG assets belong under `res://content/ui/terminal/` and should be consumed as `TextureRect`, `NinePatchRect`, `TextureButton`, or `StyleBoxTexture` skins/overlays. PNGs must not replace the Control-node layout or absorb command/simulation logic.

### Required View Models
- `TerminalShellViewModel`
- `HeaderStatusViewModel`
- `OverviewPageViewModel`
- `StatusPageViewModel`
- `SectorsPageViewModel`
- `PowerPageViewModel`
- `DefensePageViewModel`
- `SensorsPageViewModel`
- `IncidentsPageViewModel`
- `ArchivePageViewModel`
- `ReconPageViewModel`
- `ContractsPageViewModel`
- `HistoryPageViewModel`
- `FabricationPageViewModel`

---

## Node Structure

```
CustodianTerminal (Control)
├── HeaderBar (HBoxContainer)
│   ├── SystemLabel
│   ├── ModeLabel
│   ├── FidelityLabel
│   ├── ClockLabel
│   ├── ThreatLabel
│   ├── AssaultLabel
│   ├── PowerLabel
│   ├── ArchiveLabel
│   └── RateLabel
├── MainHSplit (HSplitContainer)
│   ├── NavRail (VBoxContainer)
│   │   ├── PageButtons (VBoxContainer)
│   │   │   ├── OverviewButton
│   │   │   ├── StatusButton
│   │   │   ├── SectorsButton
│   │   │   ├── PowerButton
│   │   │   ├── DefenseButton
│   │   │   ├── FabricationButton
│   │   │   ├── SensorsButton
│   │   │   ├── IncidentsButton
│   │   │   ├── ArchiveButton
│   │   │   ├── ReconButton
│   │   │   ├── ContractsButton
│   │   │   ├── HistoryButton
│   │   │   └── SettingsButton
│   │   └── CommandButtons (VBoxContainer)
│   │       ├── WaitButton
│   │       ├── Wait10XButton
│   │       ├── FocusButton
│   │       ├── HardeningButton
│   │       ├── ResetButton
│   │       ├── RebootButton
│   │       └── HelpButton
│   ├── ContentArea (Control)
│   │   └── PageContainer (Container)
│   │       ├── OverviewPage
│   │       ├── StatusPage
│   │       ├── SectorsPage
│   │       ├── PowerPage
│   │       ├── DefensePage
│   │       ├── FabricationPage
│   │       ├── SensorsPage
│   │       ├── IncidentsPage
│   │       ├── ArchivePage
│   │       ├── ReconPage
│   │       ├── ContractsPage
│   │       ├── HistoryPage
│   │       └── SettingsPage
│   └── TranscriptPanel (VBoxContainer)
│       ├── TranscriptHeader
│       ├── TranscriptScroll
│       │   └── TranscriptLog (RichTextLabel)
│       └── CommandInput (LineEdit)
└── ModalOverlay (Control)
    ├── ConfirmDialog
    ├── FocusModal
    ├── HardeningModal
    └── ScenarioDetailModal
```

---

## Dependencies

| Dependency | Source |
|------------|--------|
| Sector graph | Gameplay state |
| Power network | Power system |
| Hostile contacts | Enemy director |
| Archive integrity | Archive system |
| Active incidents | Event system |
| Campaign scenarios | Hub system |
| Fidelity state | Communications system |

---

## World Deployable Terminal Slice

The in-world command terminal prop family is also treated as a deployable interaction surface.

Implementation notes:

- The world prop reuses the existing terminal source sheets and the same HUD shell entrypoint.
- The current prop family is `command_terminal`; `fabricator_terminal` is reserved for the future separate sprite family.
- The prop can be picked up and redeployed in world space through the runtime placement flow.
- While carried, the terminal should not remain in the interactable or terminal-marker groups.
- Build/placement input should prefer terminal pickup or redeploy before falling back to wall/turret placement behavior.
- The original authority-granting terminal provides command mode only while the Operator is within interaction range. Picking up and redeploying that terminal permanently revokes command authority for that instance, so the same shell truthfully enters field mode instead of using screen visibility as authority.

---

## Related Documents

- `01_systems/COMMAND_TERMINAL_UI.md` — Superseded by this spec
- `01_systems/ROADMAP_COMMAND_TERMINAL.md` — Superseded by this spec
- `02_features/terminal/TERMINAL_PLANET_GLOBE_PREVIEW.md` — Planet view implementation

## Next Agent Slice

Goal: extract command definitions and execution from the HUD compatibility bridge into one registry-driven command architecture.

Files: `custodian/game/ui/terminal/terminal_command_registry.gd`, `terminal_command_context.gd`, `terminal_command_router.gd`, command-family scripts, `custodian/game/ui/hud/ui.gd`, and focused terminal validation.

Constraints: preserve buffered command execution, existing command spellings as aliases, the read-only snapshot boundary, and the current HUD shell while making registry definitions authoritative for help, completion, validation, dispatch, confirmation, authority, and refresh policy.

Acceptance: no command executes through `_execute_local_terminal_command_legacy()`, duplicate completion entries are eliminated, help/completion/execution agree, and `terminal_command_registry_smoke.gd` plus the existing terminal regression suite pass.

---

*This document aligns with MASTER_ROADMAP.md for milestone tracking.*
