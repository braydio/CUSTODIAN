# CUSTODIAN Command Terminal — Full Implementation Spec

**Status:** superseded-reference
**Authority:** `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
**Last Updated:** 2026-04-08
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

> **Note:** This document is retained as reference material only. The canonical implementation authority is `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`. Do not use this file for implementation decisions.

---

## Purpose

This document defines the full implementation target for the CUSTODIAN command terminal UI in Godot. It is written so Codex can build the terminal shell, page framework, widgets, navigation, page contracts, and UI state integration without additional design interpretation.

This spec assumes:

- Active runtime is Godot under `custodian/`
- The command terminal is a persistent UI shell
- Simulation/game state remains deterministic and separate from presentation
- Raw status text remains canonical and reusable across transcript and status page

This file is the shell/interface authority. For archive tone, contract-fiction semantics, confidence language, and procedural machine phrasing, defer to `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`.

---

## What the Terminal Displays

The terminal expresses the core game doctrine:

- Information asymmetry between Command Center and field play
- Power as a visible routing constraint
- Sectorized static base defense
- Deterministic status language
- Knowledge preservation over raw combat spectacle
- Loss of clarity as comms degrade

### Player-Facing Language Rules

- The terminal should sound like wounded institutional procedure, not a chatty assistant.
- Contracts should read as bounded interventions, not casual quests.
- Archive/recon output should preserve uncertainty explicitly when certainty is not justified.
- Short denotative fragments are preferred over explanatory paragraphs.

### Five Information Categories

1. **Base-wide operational state** — Always-visible top-level overview (time, threat level, assault state, system posture, archive loss, global power budget, current command mode)

2. **Sector status** — Every screen preserves awareness of the sectorized base (sector name, health/state, power state, defense state, hostile activity, occupancy, alerts, travel significance)

3. **Intelligence and fidelity** — Information quality changes with Comms condition: full, degraded, fragmented, lost. This is a core mechanic: "the system does not get weaker — the operator gets blinder."

4. **Power routing and command authority** — Total generation, draw, reserve, per-sector allocation, per-system draw, priority tiers, time-to-online for cold systems, load shedding state

5. **Actionable command surface** — Status inspection, focus posture changes, hardening priorities, power routing, target priority, sensor overlays, scenario selection, campaign acceptance/abandonment, recon clarity

---

## High-Level Goals

The terminal must:

- Present command-center intelligence clearly
- Preserve information asymmetry between command mode and field mode
- Expose sector, power, defense, sensor, incident, archive, recon, and contract information
- Support both button-driven navigation and optional typed command entry
- Feel austere, legible, deterministic, and implementable with clean view-model boundaries

The terminal is not a decorative overlay. It is a command interface.

---

## Core Layout Model

Four-zone command terminal:

### Zone A — Header Bar

Always visible. One row high.

Contents, left to right:

- `CUSTODIAN // COMMAND LINK`
- Current mode label
- Info fidelity label
- Simulation clock
- Threat bucket
- Assault state
- Power reserve
- Archive state
- Pause/compression state

Example:

```
CUSTODIAN // COMMAND LINK | MODE: COMMAND | FIDELITY: FULL | T: 18 | THREAT: HIGH | ASSAULT: PENDING | POWER: +2 RESERVE | ARCHIVE: 1/3 LOST | RATE: 1X
```

Rules:

- All caps
- No icons required for MVP
- Colors: green/amber/red only as emphasis, never as sole information carrier
- This bar never scrolls
- Pixel-art terminal frames should be rendered as Godot `StyleBoxTexture` resources with margins that match the actual frame linework and per-family stretch policy. Large panel/map frames may tile-fit borders with `draw_center=false`; header bars, nav tabs, action buttons, and command inputs should stretch a single center rather than tiling interior motifs. Do not compensate for smeared or over-tiled terminal borders by redrawing assets until runtime stylebox margins, axis modes, and `draw_center` have been verified.

### Zone B — Left Navigation Rail

Fixed width, about 220–260 px. Always visible outside boot screen.

Top section: major pages
Bottom section: contextual quick actions

Primary menu buttons, in this exact order:

1. OVERVIEW
2. STATUS
3. SECTORS
4. POWER
5. DEFENSE
6. SENSORS
7. INCIDENTS
8. ARCHIVE
9. RECON
10. CONTRACTS
11. FABRICATION
12. HISTORY
13. SETTINGS

Contextual button cluster below:

- WAIT
- WAIT 10X
- FOCUS
- HARDEN
- RESET
- REBOOT
- HELP

Rules:

- Keyboard-first. Up/down selects, Enter opens.
- Mouse support optional.
- Disabled buttons must remain visible, not disappear.
- `RECON` and `CONTRACTS` may be disabled in campaign mode if hub-only.
- `FOCUS` and `HARDEN` open modal submenus.

### Zone C — Main Content Pane

Large central panel. Changes by page.

Supports:

- Cards
- Tables
- Read-only text blocks
- Tactical map
- Split detail views
- Modals for action confirmation

No page should depend on freeform text entry for routine interaction.

### Zone D — Right-Side Transcript / Event Log

Fixed width, about 320–420 px.

Purpose:

- Boot messages
- System responses
- Command echo
- Incident feed
- Assault notifications
- Archive losses
- Power routing changes
- Recon results
- Scenario generation notes

Rules:

- Scrollable
- Newest at bottom
- Timestamp every entry
- Entries grouped by severity: INFO, ALERT, CRITICAL, SYSTEM
- Clicking an event opens linked page or sector

---

## Page Specifications

### 1. OVERVIEW Page

Default post-boot landing page.

**Layout:**

- Top row: Operational Summary card, Power Summary card, Assault Summary card
- Middle row: Sector Tactical Map (largest panel)
- Bottom row: Priority Sectors list, Active Incidents list, Recommended Attention list

**Operational Summary card fields:**

- Mode, fidelity, current phase, command center occupancy, operator location, total hostiles detected, sectors compromised count, systems offline count

**Power Summary card fields:**

- Generation, draw, reserve, critical overload warning, cold-start systems count, current routing profile

**Assault Summary card fields:**

- Assault state, active wave/group count, enemy archetypes present, morale estimate, likely ingress axes, time since contact

**Sector Tactical Map:**

Interactive. Display each sector as a labeled node/room block connected by corridors. Show: state color, power state, defense readiness, hostile count bucket, objective badge, operator marker, selected-sector highlight.

Clicking a sector opens the SECTORS page focused on that sector.

### 2. STATUS Page

Renders the canonical `STATUS` output exactly, plus structured mirrors.

**Layout:**

- Left: raw status output block
- Right: parsed status cards
- Bottom: information fidelity explanation

**Raw block:**

Must preserve the exact canonical ordering and omission rules from `INFORMATION_DEGRADATION.md`. Do not paraphrase.

**Parsed cards:**

- Time, threat, assault, posture, archive, sector statuses

**Fidelity explanation:**

- FULL: exact tactical truth
- DEGRADED: generalized counts and posture targets hidden
- FRAGMENTED: activity replaces certainty
- LOST: no usable network truth

### 3. SECTORS Page

Primary tactical management page.

**Layout:**

- Left column: sector list table
- Center: selected sector detail
- Right: local incidents, travel context, linked systems

**Sector list columns:**

- Sector, category, status, power, defense, hostiles, operator present, priority

**Sector detail fields:**

- Sector name, critical/peripheral flag, current status, structural damage, defense slots summary, powered systems, offline systems, hostile estimate, hostile activity states, ingress routes, egress routes, travel time from command, travel time from player location, autopilot effectiveness, notes

**Sector actions:**

- OPEN POWER VIEW, OPEN DEFENSE VIEW, PIN SECTOR, SET PRIORITY, TRACK INCIDENTS

If in Command Center and sector supports it:

- POWER TOGGLE, PRIORITIZE DEFENSE, PRIORITIZE SENSORS, LOAD SHED, TARGET PRIORITY

### 4. POWER Page

One of the most important pages.

**Layout:**

- Top: global power bar and reserve indicator
- Left: source systems table
- Center: sector allocation matrix
- Right: selected system detail
- Bottom: routing presets and action bar

**Global metrics:**

- Total generation, total draw, reserve/deficit, overload risk, systems brownout count, sectors unpowered count

**Source systems table columns:**

- Source, output, stability, fuel/input, status

**Sector allocation matrix:**

- Rows = sectors
- Columns = defense, sensors, utility, fabrication, reserve
- Each cell shows: current allocation, requested allocation, priority tier, online time

**Routing presets:**

- BALANCED, DEFENSE FIRST, SENSORS FIRST, FABRICATION FIRST, EMERGENCY LOAD SHED

**Action bar:**

- APPLY ROUTE, TOGGLE SYSTEM, PRIORITIZE SECTOR, RESTORE DEFAULTS

Rules:

- Only enabled when player is in Command Center.
- Outside Command Center, page becomes read-only.
- Changes update immediately in transcript and map.

### 5. DEFENSE Page

For defense readiness and target logic.

**Layout:**

- Top: readiness summary
- Left: defense asset list
- Center: selected asset detail
- Right: target priority and engagement rules
- Bottom: sector defense coverage preview

**Asset list columns:**

- Asset, sector, type, power, readiness, ammo/charge, LOS state, current target, autopilot state

**Target priority modes:**

- FIRST CONTACT, CLOSEST, HEAVIEST, SABOTEURS, BREACHERS, OBJECTIVE THREATS

### 6. SENSORS Page

For awareness asymmetry.

**Layout:**

- Top: fidelity summary
- Left: sensor asset list
- Center: tactical intelligence map
- Right: selected contact list
- Bottom: prediction strip

**Sensor asset list:**

- Sensor, sector, status, power, clarity contribution, blind areas

**Tactical intelligence map:**

- Display hostile positions if Command Center + full clarity
- Otherwise hostile activity tags by sector: entering, moving through, vandalizing, stealing, indexing, idle / loitering

**Contact list:**

- Contact id, sector, class if known, health if known, direction if known, activity, confidence

### 7. INCIDENTS Page

Dedicated event triage screen.

**Layout:**

- Table with filters above and detail pane below

**Filters:**

- Severity, sector, type, unresolved only, last 1/5/10 minutes

**Incident types:**

- Breach, sabotage, theft, power failure, defense offline, archive damage, hostile sighting, morale shift, recon return, command loss, system reboot

**Table columns:**

- Time, severity, sector, type, summary, status, linked page

### 8. ARCHIVE Page

Where the game's north star becomes visible.

**Layout:**

- Top: archive integrity summary
- Left: knowledge categories tree
- Center: selected node detail
- Right: implications / unlocks / losses

**Knowledge categories:**

- Governance, propulsion, cognition, warfare, biotech, infrastructure, unknown

### 9. RECON Page

Hub-side or meta-operational refinement page.

**Layout:**

- Top: current hypothesis summary
- Left: available recon targets
- Center: target detail
- Right: clarity gain preview

### 10. CONTRACTS Page

Hub-side scenario proposal browser.

**Layout:**

- Top: available scenario count, active scenario slot info
- Left: scenario list
- Center: selected scenario summary
- Right: reward/risk/knowledge stake
- Bottom: actions

**Actions:**

- ACCEPT, RECON FIRST, DEFER, ARCHIVE NOTE

### 11. FABRICATION Page

Bounded terminal work-order surface for authored recipes. This is not a freeform survival-crafting menu.

The FABRICATION page must fit inside the existing center content pane. It should use a compact dashboard layout with a status strip, compact filters, vertically scrolling work-order list, stacked selected-detail/cost panels, and a fixed action row. Do not use horizontal scrolling or spreadsheet-style side-by-side columns for fabrication; long recipe purpose/cost/result text belongs in the selected-detail area, not inline rows.

**Layout:**

- Top: fabricator state and selected work-order detail
- Left: category/filter summary
- Center: clickable work-order rows
- Right: selected recipe cost, owned materials, missing materials, and output
- Bottom: in-progress queue, ready builds, and action row

**Actions:**

- CRAFT 1
- CRAFT TO MAX
- PLACE READY BUILD
- CANCEL QUEUE

Typed fallback commands remain valid: `FAB START <work_order_id>`, `FAB QUEUE`, `FAB CANCEL`, and `BUILD PLACE <ready_build_id>`.

### 12. HISTORY Page

Operational history and campaign log.

**Tabs:**

- COMMAND LOG, ASSAULTS, CAMPAIGNS, LOSSES, DISCOVERIES

### 13. SETTINGS Page

Minimal.

**Sections:**

- Text scale, log speed, sound toggles, accessibility colors, status verbosity, input mode, confirm-destructive-actions

---

## Menu and Interaction Behavior

### Main Navigation

- `Tab` cycles major regions
- `1–9` optionally jump to main pages
- `Esc` closes modal or returns to previous page
- `Space` acknowledges highlighted incident
- `Enter` activates selected button
- `/` focuses optional command palette
- Typed commands remain supported for advanced users

### Command Palette

Open with `/`.

Supported MVP commands:

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

### Modal Rules

Use modals only for:

- Accept scenario
- Reboot/reset
- Destructive load shedding
- Archive purge or confirmation
- Abandon campaign

---

## Visual and UX Style Rules

### Aesthetic

- Austere
- Military-industrial
- Archival
- Legible
- No glossy hologram nonsense

### Typography

- Monospaced for raw status and transcript
- Condensed sans or mono for headers
- All caps for system strings
- Sentence case allowed only in archive lore/detail panes if needed later

### Color Logic

- Neutral dark background
- Muted green primary
- Amber caution
- Red critical
- Blue only for selected/focused state, sparingly

### Motion

- Boot typing animation
- Subtle row highlight
- Alert flash only on new critical incident
- No constant animated noise

### Sound

- Keep existing boot cue identity: hum, relay, beep, alert, power_cycle
- In normal play, sounds should be sparse and meaningful

---

## Boot Flow

### Boot Screen

Fullscreen. No nav rail yet.

Sequence:

1. Black screen
2. `CUSTODIAN LINK INITIALIZING`
3. Hardware/system lines typed in
4. Short audio cues per line cluster
5. Comms check
6. Archive check
7. Topology sync
8. Sector map projection online
9. Command surface unlock
10. Transition to OVERVIEW

At the end of boot, log automatically appends:

- `STATUS AVAILABLE`
- `WAIT AVAILABLE`
- `WAIT 10X AVAILABLE`
- `FOCUS AVAILABLE`
- `HARDEN AVAILABLE`
- `HELP AVAILABLE`

Then input unlocks.

---

## Information Architecture by Game Mode

### Mode 1: Hub Mode

Top pages emphasized:

- ARCHIVE, RECON, CONTRACTS, HISTORY

Overview shows: scenario proposals, unresolved hypotheses, archive integrity, recent discoveries

### Mode 2: Campaign Command Mode

Top pages emphasized:

- OVERVIEW, STATUS, SECTORS, POWER, DEFENSE, SENSORS, INCIDENTS

### Mode 3: On-Foot / Field Mode

The terminal becomes degraded and narrower.

Changes:

- POWER actions disabled
- Full SENSORS replaced by rough activity map
- Map becomes "field overlay"
- Transcript still receives events
- Command buttons reduce to: STATUS, SECTORS, INCIDENTS, RETURN TO COMMAND marker

---

## Scene Ownership and File Layout

```text
custodian/
├── ui/
│   ├── terminal/
│   │   ├── TerminalShell.tscn
│   │   ├── TerminalShell.gd
│   │   ├── TerminalTheme.tres
│   │   ├── TerminalStyle.gd
│   │   ├── pages/
│   │   │   ├── TerminalOverviewPage.tscn
│   │   │   ├── TerminalOverviewPage.gd
│   │   │   ├── TerminalStatusPage.tscn
│   │   │   ├── TerminalStatusPage.gd
│   │   │   ├── TerminalSectorsPage.tscn
│   │   │   ├── TerminalSectorsPage.gd
│   │   │   ├── TerminalPowerPage.tscn
│   │   │   ├── TerminalPowerPage.gd
│   │   │   ├── TerminalDefensePage.tscn
│   │   │   ├── TerminalDefensePage.gd
│   │   │   ├── TerminalSensorsPage.tscn
│   │   │   ├── TerminalSensorsPage.gd
│   │   │   ├── TerminalIncidentsPage.tscn
│   │   │   ├── TerminalIncidentsPage.gd
│   │   │   ├── TerminalArchivePage.tscn
│   │   │   ├── TerminalArchivePage.gd
│   │   │   ├── TerminalReconPage.tscn
│   │   │   ├── TerminalReconPage.gd
│   │   │   ├── TerminalContractsPage.tscn
│   │   │   ├── TerminalContractsPage.gd
│   │   │   ├── TerminalHistoryPage.tscn
│   │   │   ├── TerminalHistoryPage.gd
│   │   │   ├── TerminalSettingsPage.tscn
│   │   │   └── TerminalSettingsPage.gd
│   │   ├── widgets/
│   │   │   ├── HeaderBar.tscn
│   │   │   ├── HeaderBar.gd
│   │   │   ├── NavRail.tscn
│   │   │   ├── NavRail.gd
│   │   │   ├── TranscriptPanel.tscn
│   │   │   ├── TranscriptPanel.gd
│   │   │   ├── CommandPalette.tscn
│   │   │   ├── CommandPalette.gd
│   │   │   ├── ConfirmModal.tscn
│   │   │   ├── ConfirmModal.gd
│   │   │   ├── SectorMapWidget.tscn
│   │   │   ├── SectorMapWidget.gd
│   │   │   ├── StatusRawBlock.tscn
│   │   │   ├── StatusRawBlock.gd
│   │   │   ├── SummaryCard.tscn
│   │   │   ├── SummaryCard.gd
│   │   │   ├── DataTable.tscn
│   │   │   ├── DataTable.gd
│   │   │   ├── DetailPanel.tscn
│   │   │   ├── DetailPanel.gd
│   │   │   ├── ActionBar.tscn
│   │   │   ├── ActionBar.gd
│   │   │   ├── FilterBar.tscn
│   │   │   ├── FilterBar.gd
│   │   │   ├── SeverityBadge.tscn
│   │   │   └── SeverityBadge.gd
│   │   ├── vm/
│   │   │   ├── TerminalShellViewModel.gd
│   │   │   ├── HeaderStatusViewModel.gd
│   │   │   ├── OverviewPageViewModel.gd
│   │   │   ├── StatusPageViewModel.gd
│   │   │   ├── SectorsPageViewModel.gd
│   │   │   ├── PowerPageViewModel.gd
│   │   │   ├── DefensePageViewModel.gd
│   │   │   ├── SensorsPageViewModel.gd
│   │   │   ├── IncidentsPageViewModel.gd
│   │   │   ├── ArchivePageViewModel.gd
│   │   │   ├── ReconPageViewModel.gd
│   │   │   ├── ContractsPageViewModel.gd
│   │   │   └── HistoryPageViewModel.gd
│   │   ├── data/
│   │   │   ├── TerminalEnums.gd
│   │   │   ├── TerminalCommand.gd
│   │   │   ├── TranscriptEntry.gd
│   │   │   ├── SectorMapNodeData.gd
│   │   │   ├── SectorRowData.gd
│   │   │   ├── IncidentRowData.gd
│   │   │   ├── PowerAllocationRowData.gd
│   │   │   ├── ContactRowData.gd
│   │   │   └── ArchiveNodeRowData.gd
│   │   └── services/
│   │       ├── TerminalUiController.gd
│   │       ├── TerminalCommandRouter.gd
│   │       ├── TerminalStatusFormatter.gd
│   │       ├── TerminalViewModelFactory.gd
│   │       └── TerminalAudioCueService.gd
```

---

## Core Singleton/Controller Responsibilities

### TerminalUiController.gd

Responsible for:

- Opening/closing terminal shell
- Switching current page
- Routing selection state between pages
- Opening modals and command palette
- Applying view models to shell and pages
- Handling global hotkeys
- Syncing transcript and header refreshes

### TerminalCommandRouter.gd

Responsible for:

- Parsing typed commands
- Validating command availability against game state
- Mapping commands to game actions or UI navigation
- Returning success/failure/result transcript text

### TerminalStatusFormatter.gd

Responsible for:

- Generating the canonical raw status block
- Preserving fidelity-dependent omission rules
- Returning pure text only

### TerminalViewModelFactory.gd

Responsible for:

- Reading simulation/game state
- Constructing all page view models
- Isolating transformation logic from UI widgets

### TerminalAudioCueService.gd

Responsible for:

- Boot cues
- Alert cues
- Command confirm/reject cues
- Optional page-switch audio

---

## Root Scene Tree

```text
TerminalShell (CanvasLayer)
└── RootMargin (MarginContainer)
    └── RootVBox (VBoxContainer)
        ├── HeaderBar (Control)
        └── BodyHBox (HBoxContainer)
            ├── NavRail (Control)
            ├── MainArea (MarginContainer)
            │   └── MainStack (StackContainer)
            │       ├── OverviewPage (Control)
            │       ├── StatusPage (Control)
            │       ├── SectorsPage (Control)
            │       ├── PowerPage (Control)
            │       ├── DefensePage (Control)
            │       ├── SensorsPage (Control)
            │       ├── IncidentsPage (Control)
            │       ├── ArchivePage (Control)
            │       ├── ReconPage (Control)
            │       ├── ContractsPage (Control)
            │       ├── HistoryPage (Control)
            │       └── SettingsPage (Control)
            └── RightRail (MarginContainer)
                └── RightRailVBox (VBoxContainer)
                    ├── TranscriptHeader (Label)
                    ├── TranscriptPanel (Control)
                    └── CommandLineDock (Control)
        ├── OverlayLayer (Control)
        │   ├── CommandPalette (Control)
        │   ├── ConfirmModal (Control)
        │   ├── ContextModal (Control)
        │   └── BootSequenceOverlay (Control)
        └── ScreenFx (Control)
```

---

## Terminal Shell State Contract

### TerminalShellViewModel

Fields:

- `current_mode: String` — values: `HUB`, `CAMPAIGN_COMMAND`, `FIELD`, `BOOT`, `LOCKED`
- `current_page: String`
- `info_fidelity: String` — values: `FULL`, `DEGRADED`, `FRAGMENTED`, `LOST`
- `sim_time_label: String`
- `threat_label: String`
- `assault_state_label: String`
- `power_reserve_label: String`
- `archive_state_label: String`
- `time_rate_label: String`
- `transcript_entries: Array`
- `available_pages: Array[String]`
- `available_actions: Array[String]`
- `is_command_palette_enabled: bool`
- `is_boot_sequence_complete: bool`
- `is_input_locked: bool`
- `operator_location_label: String`
- `command_center_occupied: bool`

---

## Input Map and Controls

### Required Actions

Create input actions for:

- `terminal_toggle`
- `terminal_nav_up`
- `terminal_nav_down`
- `terminal_nav_left`
- `terminal_nav_right`
- `terminal_accept`
- `terminal_back`
- `terminal_command_palette`
- `terminal_acknowledge`
- `terminal_page_overview` through `terminal_page_settings`

### Recommended Defaults

- `Tab` — cycle focus regions
- `Esc` — close modal/back
- `Enter` — accept
- `/` — open command palette
- `Space` — acknowledge highlighted incident
- Optional number keys for page shortcuts

---

## UI State Machine

### Terminal Modes

- `BOOT`
- `HUB`
- `CAMPAIGN_COMMAND`
- `FIELD`
- `LOCKED`

### Transition Rules

- `BOOT -> HUB` on hub load
- `BOOT -> CAMPAIGN_COMMAND` on active campaign command context
- `CAMPAIGN_COMMAND -> FIELD` when player leaves command-capable context
- `FIELD -> CAMPAIGN_COMMAND` when player re-enters command center
- `any -> LOCKED` if terminal unavailable due to scenario or damage state

---

## Data Integration Rules

### Hard Rule

The UI must read derived view models, not direct runtime nodes or raw simulation structures scattered throughout widgets.

### Recommended Source Integration Pattern

1. Simulation state updates
2. `TerminalViewModelFactory` builds fresh page VMs
3. `TerminalUiController` binds VM data into shell and active page
4. Transcript receives append-only event updates
5. Header refreshes independently

### Avoid

- Page widget directly querying combat managers
- Page widget directly mutating simulation objects
- Duplicate status text generation logic in multiple files

---

## Raw Status Formatter Requirements

`TerminalStatusFormatter.gd` must be the only system producing canonical `STATUS` text.

It must accept:

- Sim time
- Fidelity state
- Threat state
- Assault state
- Archive state
- Posture
- Sector snapshot list

It must output one deterministic text block with fidelity-dependent omissions/generalizations.

Use this same output in:

- Transcript `STATUS` responses
- Status page raw block
- Debug snapshots if needed

---

## Implementation Order

Implement in this order:

1. Terminal shell scene and layout scaffolding
2. Header bar + nav rail + transcript panel
3. Page switching controller
4. Boot sequence overlay
5. Command palette + confirm modal
6. Overview page
7. Status page + canonical status formatter
8. Sectors page + sector map widget
9. Incidents page
10. Power page
11. Defense page
12. Sensors page
13. Archive page
14. Recon page
15. Contracts page
16. History page
17. Settings page
18. Keyboard polish + mode restrictions + persistence

---

## Acceptance Criteria

Codex implementation is acceptable when:

- Terminal opens into a persistent shell
- Header remains stable across all page switches
- Nav rail routes correctly between all pages
- Transcript persists and appends entries
- Overview page displays summary cards, map, incidents, and recommendations
- Status page shows canonical raw status plus parsed mirrors
- Sectors page supports selection and linked actions
- Power page clearly renders sources, allocations, and actions
- Defense and sensors pages support asset/contact inspection
- Archive, recon, contracts, and history pages exist as structured interfaces
- Command palette executes supported commands and logs results
- Mode restrictions work between hub/command/field
- No page directly owns simulation logic
- Data flows through view models/services cleanly

---

## Final Implementation Note

If runtime naming conventions in the project differ, preserve the architecture and data flow even if individual filenames change. The non-negotiable parts are:

- Persistent four-zone shell
- Canonical status formatter
- Page-based command UI
- Transcript persistence
- View-model isolation from deterministic game logic
- Command vs field information asymmetry

---

*Document source: design/NEW_FEATURE_TO_DESIGN-TERMINAL.md*
