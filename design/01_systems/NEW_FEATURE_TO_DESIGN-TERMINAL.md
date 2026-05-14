
The active runtime is the Godot project under `custodian/`, while the old terminal prototype lives in the legacy Python branch and should be treated as reference rather than current runtime authority. The docs also say the implementation source of truth should now be the Godot-native `design/` specs first, then doctrine, then `custodian/docs/*`. 


## What the terminal needs to display

The terminal should not be a generic sci-fi dashboard. It needs to express the core game doctrine:

* information asymmetry between Command Center and field play
* power as a visible routing constraint
* sectorized static base defense
* deterministic status language
* knowledge preservation over raw combat spectacle
* loss of clarity as comms degrade

That doctrine is explicit in the project docs: the Command Center gives live tactical intelligence, power routing, defense timing, and target prioritization; outside it, the player gets only rough sector awareness and costly local intervention. 

So the terminal must display five categories of information:

### 1. Base-wide operational state

This is the always-visible top-level overview:

* time
* threat level
* assault state
* system posture
* archive loss or archive status
* global power budget summary
* current command mode

This matches the canonical `STATUS` structure, which already has fixed section order and fidelity-dependent wording. 

### 2. Sector status

Every screen that matters must preserve awareness of the sectorized base:

* sector name
* sector health/state
* power online/offline/degraded
* defense state
* hostile activity summary
* occupancy or operator presence
* alerts
* travel significance

The tutorial campaign is built around 10 sectors total with Command Center and Goal Sector as hard-critical sectors, plus 8 named peripherals. 

### 3. Intelligence and fidelity

The terminal should explicitly communicate that information quality changes with Comms condition:

* full
* degraded
* fragmented
* lost

This is not cosmetic. It is a core mechanic: “the system does not get weaker — the operator gets blinder.” Output wording and omission must reflect that. 

### 4. Power routing and command authority

Because command-center play is about smarter decisions rather than stronger actions, the terminal must expose:

* total generation
* total draw
* reserve
* per-sector allocation
* per-system draw
* priority tiers
* time-to-online for cold systems
* load shedding state

The docs are very explicit that power is global, insufficient, visible, and routable only from Command Center. 

### 5. Actionable command surface

The terminal is not just for flavor. It must directly support:

* status inspection
* focus posture changes
* hardening priorities
* power routing
* target priority
* sensor overlays
* scenario selection at hub
* campaign acceptance / abandonment later
* recon clarity improvements later

The hub and campaign architecture also implies that the terminal will eventually need scenario proposal browsing, accept/abandon flow, reward/history review, and hub knowledge display. 

---

# Ideal Custodian command terminal UI

This is the implementation-grade spec.

## Core layout model

Use a **four-zone command terminal**. Do not build it as a single fullscreen text feed.

### Zone A — Header bar

Always visible. One row high.

Contents, left to right:

* `CUSTODIAN // COMMAND LINK`
* current mode label
* info fidelity label
* simulation clock
* threat bucket
* assault state
* power reserve
* archive state
* pause/compression state

Example:
`CUSTODIAN // COMMAND LINK | MODE: COMMAND | FIDELITY: FULL | T: 18 | THREAT: HIGH | ASSAULT: PENDING | POWER: +2 RESERVE | ARCHIVE: 1/3 LOST | RATE: 1X`

Rules:

* All caps.
* No icons required for MVP.
* Colors: green/amber/red only as emphasis, never as sole information carrier.
* This bar never scrolls.

---

### Zone B — Left navigation rail

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
11. HISTORY
12. SETTINGS

Contextual button cluster below:

* WAIT
* WAIT 10X
* FOCUS
* HARDEN
* RESET
* REBOOT
* HELP

Rules:

* Keyboard-first. Up/down selects, Enter opens.
* Mouse support optional.
* Disabled buttons must remain visible, not disappear.
* `RECON` and `CONTRACTS` may be disabled in campaign mode if hub-only.
* `FOCUS` and `HARDEN` open modal submenus, not inline prompt-only actions.

Why this layout:
The project’s command vocabulary already expects short operational actions, and the terminal must support future hub/campaign state split without becoming a pure REPL.  

---

### Zone C — Main content pane

Large central panel. This changes by page.

This is the “page body” and should support:

* cards
* tables
* read-only text blocks
* tactical map
* split detail views
* modals for action confirmation

No page should depend on freeform text entry for routine interaction. Typed commands can exist, but Codex should implement button and keyboard navigation first.

---

### Zone D — Right-side transcript / event log

Fixed width, about 320–420 px.

Purpose:

* boot messages
* system responses
* command echo
* incident feed
* assault notifications
* archive losses
* power routing changes
* recon results
* scenario generation notes

Rules:

* scrollable
* newest at bottom
* timestamp every entry
* entries grouped by severity:

  * INFO
  * ALERT
  * CRITICAL
  * SYSTEM
* clicking an event opens linked page or sector

This preserves the prototype’s transcript identity while moving high-value state into stable panels. 

---

# Exact page spec

## 1. OVERVIEW page

This is the default post-boot landing page.

### Layout

Top row:

* Operational Summary card
* Power Summary card
* Assault Summary card

Middle row:

* Sector Tactical Map (largest panel)

Bottom row:

* Priority Sectors list
* Active Incidents list
* Recommended Attention list

### Operational Summary card fields

* mode
* fidelity
* current phase
* command center occupancy
* operator location
* total hostiles detected
* sectors compromised count
* systems offline count

### Power Summary card fields

* generation
* draw
* reserve
* critical overload warning
* cold-start systems count
* current routing profile

### Assault Summary card fields

* assault state
* active wave/group count
* enemy archetypes present
* morale estimate if known
* likely ingress axes
* time since contact

### Sector Tactical Map

Not a decorative minimap. It must be interactive.

Display each sector as a labeled node/room block connected by corridors. Show:

* state color
* power state
* defense readiness
* hostile count bucket
* objective badge
* operator marker
* selected-sector highlight

For MVP, the map can be schematic rather than literal.

Clicking a sector opens the SECTORS page focused on that sector.

---

## 2. STATUS page

This page renders the canonical `STATUS` output exactly, plus structured mirrors.

### Layout

Left:

* raw status output block

Right:

* parsed status cards

Bottom:

* information fidelity explanation

### Raw block

Must preserve the exact canonical ordering and omission rules from `INFORMATION_DEGRADATION.md`. Do not paraphrase. 

### Parsed cards

* time
* threat
* assault
* posture
* archive
* sector statuses

### Fidelity explanation

Small non-diegetic helper:

* FULL: exact tactical truth
* DEGRADED: generalized counts and posture targets hidden
* FRAGMENTED: activity replaces certainty
* LOST: no usable network truth

This page is for debugging, testing, and player trust.

---

## 3. SECTORS page

Primary tactical management page.

### Layout

Left column:

* sector list table

Center:

* selected sector detail

Right:

* local incidents
* travel context
* linked systems

### Sector list columns

* sector
* category
* status
* power
* defense
* hostiles
* operator present
* priority

### Sector detail fields

* sector name
* critical/peripheral flag
* current status
* structural damage
* defense slots summary
* powered systems
* offline systems
* hostile estimate
* hostile activity states
* ingress routes
* egress routes
* travel time from command
* travel time from player location
* autopilot effectiveness
* notes

### Sector actions

Buttons:

* OPEN POWER VIEW
* OPEN DEFENSE VIEW
* PIN SECTOR
* SET PRIORITY
* TRACK INCIDENTS

If in Command Center and sector supports it:

* POWER TOGGLE
* PRIORITIZE DEFENSE
* PRIORITIZE SENSORS
* LOAD SHED
* TARGET PRIORITY

This page reflects the fact that sectorized base defense and movement opportunity cost are core design pillars. 

---

## 4. POWER page

This is one of the most important pages.

### Layout

Top:

* global power bar and reserve indicator

Left:

* source systems table

Center:

* sector allocation matrix

Right:

* selected system detail

Bottom:

* routing presets and action bar

### Global metrics

* total generation
* total draw
* reserve/deficit
* overload risk
* systems brownout count
* sectors unpowered count

### Source systems table

Columns:

* source
* output
* stability
* fuel/input
* status

### Sector allocation matrix

Rows = sectors
Columns = defense, sensors, utility, fabrication, reserve

Each cell shows:

* current allocation
* requested allocation
* priority tier
* online time

### Selected system detail

Fields:

* system name
* sector
* draw
* category
* online/offline
* warmup time
* importance tier
* command only / field patchable

### Routing presets

Buttons:

* BALANCED
* DEFENSE FIRST
* SENSORS FIRST
* FABRICATION FIRST
* EMERGENCY LOAD SHED

### Action bar

Buttons:

* APPLY ROUTE
* TOGGLE SYSTEM
* PRIORITIZE SECTOR
* RESTORE DEFAULTS

Rules:

* These are only enabled when player is in Command Center.
* Outside Command Center, page becomes read-only except for local field patch preview.
* Changes update immediately in transcript and map.

This page must exist because the docs treat routed power as the heart of command authority. 

---

## 5. DEFENSE page

For defense readiness and target logic.

### Layout

Top:

* readiness summary

Left:

* defense asset list

Center:

* selected asset detail

Right:

* target priority and engagement rules

Bottom:

* sector defense coverage preview

### Asset list columns

* asset
* sector
* type
* power
* readiness
* ammo/charge
* LOS state
* current target
* autopilot state

### Asset detail

* type
* sector
* slot
* current health
* ammo/charge
* cooldown
* target mode
* manual override availability
* linked power source
* linked sensor coverage

### Target priority panel

Buttons:

* FIRST CONTACT
* CLOSEST
* HEAVIEST
* SABOTEURS
* BREACHERS
* OBJECTIVE THREATS

MVP can support only 2–3 real modes under the hood, but the UI structure should be future-proof.

### Coverage preview

Schematic overlay of sectors with fields of fire and blind spots.

---

## 6. SENSORS page

For awareness asymmetry.

### Layout

Top:

* fidelity summary

Left:

* sensor asset list

Center:

* tactical intelligence map

Right:

* selected contact list

Bottom:

* prediction strip

### Sensor asset list

* sensor
* sector
* status
* power
* clarity contribution
* blind areas

### Tactical intelligence map

Display:

* hostile positions if Command Center + full clarity
* otherwise hostile activity tags by sector:

  * entering
  * moving through
  * vandalizing
  * stealing
  * indexing
  * idle / loitering

These activity-state labels come directly from CommandCenter doctrine and should not be replaced with generic “enemy active.” 

### Selected contact list

* contact id
* sector
* class if known
* health if known
* direction if known
* activity
* confidence

### Prediction strip

* likely next sector
* dwell prediction
* ingress trend
* certainty level

---

## 7. INCIDENTS page

Dedicated event triage screen.

### Layout

Table with filters above and detail pane below.

### Filters

* severity
* sector
* type
* unresolved only
* last 1/5/10 minutes

### Incident types

* breach
* sabotage
* theft
* power failure
* defense offline
* archive damage
* hostile sighting
* morale shift
* recon return
* command loss
* system reboot

### Table columns

* time
* severity
* sector
* type
* summary
* status
* linked page

### Detail pane

* full incident text
* related systems
* related hostiles
* suggested destination page
* acknowledge button

Acknowledge should mark it read, never clear history.

---

## 8. ARCHIVE page

This is where the game’s north star becomes visible.

### Layout

Top:

* archive integrity summary

Left:

* knowledge categories tree

Center:

* selected node detail

Right:

* implications / unlocks / losses

### Archive integrity summary

* integrity %
* losses count
* corrupted entries
* newly recovered entries
* unresolved hypotheses
* campaign relevance

### Knowledge categories

* governance
* propulsion
* cognition
* warfare
* biotech
* infrastructure
* unknown

These categories are aligned with the knowledge-node style outlined in hub docs. 

### Selected node detail

* title
* category
* origin
* confidence
* recovery source
* implications
* status: recovered / partial / lost / inferred

### Right panel

* unlocks future scenarios
* modifies status clarity
* unlocks doctrine
* unresolved contradictions

This page ensures the terminal is not only about combat pressure.

---

## 9. RECON page

Hub-side or meta-operational refinement page.

### Layout

Top:

* current hypothesis summary

Left:

* available recon targets

Center:

* target detail

Right:

* clarity gain preview

### Recon target fields

* hypothesis id
* domain
* current confidence
* risk of misread
* potential revelation type
* recon cost
* available after

### Detail panel

* known
* unknown
* hypothesis
* possible archetypes
* what recon can reveal
* what recon cannot reveal

The hub docs explicitly define recon as a clarity-refinement action, not a combat buff and not scouting in the world. This page should embody that exactly. 

---

## 10. CONTRACTS page

Hub-side scenario proposal browser.

### Layout

Top:

* available scenario count
* active scenario slot info

Left:

* scenario list

Center:

* selected scenario summary

Right:

* reward/risk/knowledge stake

Bottom:

* actions

### Scenario list columns

* id
* archetype
* setting
* difficulty
* core threat
* victory condition
* confidence

### Selected scenario summary

* title
* known
* unknown
* hypothesis driver
* biome/setting
* threat type
* primary condition
* modifiers
* failure risk
* abandonment penalty

### Right panel

* reward profile
* likely knowledge category
* potential concrete recovery
* potential contextual revelation
* archive relevance

### Actions

* ACCEPT
* RECON FIRST
* DEFER
* ARCHIVE NOTE

This structure follows the hub/campaign split described in `CONTRACTS_AND_HUB.md`. 

---

## 11. HISTORY page

Operational history and campaign log.

### Tabs

* COMMAND LOG
* ASSAULTS
* CAMPAIGNS
* LOSSES
* DISCOVERIES

Each tab shows stable chronological records. Nothing here should mutate or disappear except by explicit retention policy.

---

## 12. SETTINGS page

Keep minimal.

### Sections

* text scale
* log speed
* sound toggles
* accessibility colors
* status verbosity
* input mode
* confirm-destructive-actions

Do not bury gameplay systems here.

---

# Menu and interaction behavior

## Main navigation behavior

* `Tab` cycles major regions.
* `1–9` optionally jump to main pages.
* `Esc` closes modal or returns to previous page.
* `Space` acknowledges highlighted incident.
* `Enter` activates selected button.
* `/` focuses optional command palette.
* typed commands remain supported for advanced users.

## Command palette

Open with `/`.

Supported MVP commands:

* `status`
* `wait`
* `wait 10x`
* `focus <sector|power|defense|archive>`
* `harden <sector>`
* `help`
* `goto <page>`
* `sector <name>`
* `power preset <name>`
* `reboot`
* `reset`

The palette should not replace visible buttons. It mirrors them.

## Modal rules

Use modals only for:

* accept scenario
* reboot/reset
* destructive load shedding
* archive purge or confirmation
* abandon campaign

---

# Visual and UX style rules

## Aesthetic

* austere
* military-industrial
* archival
* legible
* no glossy hologram nonsense

## Typography

* monospaced for raw status and transcript
* condensed sans or mono for headers
* all caps for system strings
* sentence case allowed only in archive lore/detail panes if needed later

## Color logic

* neutral dark background
* muted green primary
* amber caution
* red critical
* blue only for selected/focused state, sparingly

## Motion

* boot typing animation
* subtle row highlight
* alert flash only on new critical incident
* no constant animated noise

## Sound

Keep the existing boot cue identity:

* hum
* relay
* beep
* alert
* power_cycle

But in normal play, sounds should be sparse and meaningful. The docs already define these audio motifs in the prototype. 

---

# Exact boot flow

## Boot screen

Fullscreen. No nav rail yet.

Sequence:

1. Black screen
2. `CUSTODIAN LINK INITIALIZING`
3. hardware/system lines typed in
4. short audio cues per line cluster
5. comms check
6. archive check
7. topology sync
8. sector map projection online
9. command surface unlock
10. transition to OVERVIEW

At the end of boot, log automatically appends:

* `STATUS AVAILABLE`
* `WAIT AVAILABLE`
* `WAIT 10X AVAILABLE`
* `FOCUS AVAILABLE`
* `HARDEN AVAILABLE`
* `HELP AVAILABLE`

Then input unlocks, matching the legacy prototype behavior. 

---

# Information architecture by game mode

## Mode 1: Hub mode

Top pages emphasized:

* ARCHIVE
* RECON
* CONTRACTS
* HISTORY

Overview shows:

* scenario proposals
* unresolved hypotheses
* archive integrity
* recent discoveries

## Mode 2: Campaign command mode

Top pages emphasized:

* OVERVIEW
* STATUS
* SECTORS
* POWER
* DEFENSE
* SENSORS
* INCIDENTS

## Mode 3: On-foot / field mode

The terminal becomes degraded and narrower.

Changes:

* POWER actions disabled
* full SENSORS replaced by rough activity map
* map becomes “field overlay”
* transcript still receives events
* command buttons reduce to:

  * STATUS
  * SECTORS
  * INCIDENTS
  * RETURN TO COMMAND marker if applicable

This preserves the core asymmetry: command view is god’s-eye; field view is inferred and partial. 

---

# Concrete implementation rules for Codex

These are the hard rules Codex should follow.

## Structural rules

* Build terminal as persistent shell scene with swappable page components.
* Header, nav, transcript, and modal manager are global singleton UI regions.
* Main page content swaps via page controller.
* Never tie core game state to UI widgets directly; use view models derived from deterministic sim state.
* Raw `STATUS` output must be generated by one canonical formatter shared by transcript and STATUS page.
* Sector map widget must read from the same sector graph used by gameplay state.

## Data contracts

Codex should assume these view models exist:

* `TerminalShellViewModel`
* `HeaderStatusViewModel`
* `OverviewPageViewModel`
* `StatusPageViewModel`
* `SectorsPageViewModel`
* `PowerPageViewModel`
* `DefensePageViewModel`
* `SensorsPageViewModel`
* `IncidentsPageViewModel`
* `ArchivePageViewModel`
* `ReconPageViewModel`
* `ContractsPageViewModel`
* `HistoryPageViewModel`

## Core state required

* current mode
* current page
* info fidelity
* transcript entries
* sector graph
* sector states
* power network
* hostile contact summaries
* archive integrity
* active incidents
* available command actions
* campaign scenario proposals
* selected scenario
* current command-center occupancy

## UX rules

* never hide critical state behind hover
* every alert should link to a page or sector
* every page should preserve at least a mini operational summary
* no page should clear the transcript
* no page should fully obscure assault state
* destructive commands require confirmation
* unavailable commands explain why

## Text rules

* terse
* operational
* grounded
* no cute flavor chatter in core system UI
* transcript wording deterministic where possible
* canonical status wording unchanged across builds except through fidelity spec

These constraints are directly supported by the project’s conventions and information degradation spec.  

---

# Bottom line recommendation

The ideal terminal for CUSTODIAN is **not** a pure old-school text console and **not** a modern RTS HUD. It should be a **hybrid operational shell**:

* left rail for page navigation and command actions
* center pane for page-level tactical and archival content
* right transcript for diegetic system responses and event flow
* top status bar for always-visible operational truth
* schematic tactical map as the central anchor of command play

That structure fits the project’s current doctrine: sectorized base defense, command-center authority, imperfect field awareness, readable power routing, and archive-first progression.   

---
# IMPLEMENTATION SPEC
---

# CUSTODIAN Command Terminal — Codex Implementation Spec

## Purpose

This document defines the full implementation target for the CUSTODIAN command terminal UI in Godot. It is written so Codex can build the terminal shell, page framework, widgets, navigation, page contracts, and UI state integration without additional design interpretation.

This spec assumes:

* active runtime is Godot under `custodian/`
* the command terminal is a persistent UI shell
* simulation/game state remains deterministic and separate from presentation
* raw status text remains canonical and reusable across transcript and status page

---

# 1. High-level goals

The terminal must:

* present command-center intelligence clearly
* preserve information asymmetry between command mode and field mode
* expose sector, power, defense, sensor, incident, archive, recon, and contract information
* support both button-driven navigation and optional typed command entry
* feel austere, legible, deterministic, and implementable with clean view-model boundaries

The terminal is not a decorative overlay. It is a command interface.

---

# 2. Scene ownership and file layout

## Recommended file layout

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

# 3. Root scene tree

## `TerminalShell.tscn`

Use this exact structure unless runtime conventions force minor renaming.

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

### Root behavior

* `HeaderBar` always visible except optional fullscreen boot intro.
* `NavRail` always visible after boot.
* `MainStack` holds one page per child; switch pages by index or enum mapping.
* `TranscriptPanel` always persists across pages.
* `CommandLineDock` contains optional quick command prompt and current context hint.
* `OverlayLayer` owns transient UI.
* `ScreenFx` handles subtle scanline/noise/vignette only if desired; must be easy to disable.

---

# 4. Core singleton/controller responsibilities

## `TerminalUiController.gd`

Responsible for:

* opening/closing terminal shell
* switching current page
* routing selection state between pages
* opening modals and command palette
* applying view models to shell and pages
* handling global hotkeys
* syncing transcript and header refreshes

## `TerminalCommandRouter.gd`

Responsible for:

* parsing typed commands
* validating command availability against game state
* mapping commands to game actions or UI navigation
* returning success/failure/result transcript text

## `TerminalStatusFormatter.gd`

Responsible for:

* generating the canonical raw status block
* preserving fidelity-dependent omission rules
* returning pure text only

## `TerminalViewModelFactory.gd`

Responsible for:

* reading simulation/game state
* constructing all page view models
* isolating transformation logic from UI widgets

## `TerminalAudioCueService.gd`

Responsible for:

* boot cues
* alert cues
* command confirm/reject cues
* optional page-switch audio

---

# 5. Terminal shell state contract

## `TerminalShellViewModel`

Fields:

* `current_mode: String`
  values: `HUB`, `CAMPAIGN_COMMAND`, `FIELD`, `BOOT`, `LOCKED`
* `current_page: String`
* `info_fidelity: String`
  values: `FULL`, `DEGRADED`, `FRAGMENTED`, `LOST`
* `sim_time_label: String`
* `threat_label: String`
* `assault_state_label: String`
* `power_reserve_label: String`
* `archive_state_label: String`
* `time_rate_label: String`
* `transcript_entries: Array`
* `available_pages: Array[String]`
* `available_actions: Array[String]`
* `is_command_palette_enabled: bool`
* `is_boot_sequence_complete: bool`
* `is_input_locked: bool`
* `operator_location_label: String`
* `command_center_occupied: bool`

---

# 6. Header bar spec

## Node tree

```text
HeaderBar
└── HeaderHBox (HBoxContainer)
    ├── AppMarkLabel
    ├── SpacerA
    ├── ModeValueLabel
    ├── FidelityValueLabel
    ├── TimeValueLabel
    ├── ThreatValueLabel
    ├── AssaultValueLabel
    ├── PowerValueLabel
    ├── ArchiveValueLabel
    ├── RateValueLabel
    └── SpacerB
```

## Responsibilities

* render one-line operational truth
* never scroll
* always reflect active simulation state
* update independently of page changes

## Example final text style

`CUSTODIAN // COMMAND LINK | MODE: COMMAND | FIDELITY: FULL | T: 18 | THREAT: HIGH | ASSAULT: PENDING | POWER: +2 RESERVE | ARCHIVE: 1/3 LOST | RATE: 1X`

---

# 7. Left navigation rail spec

## Node tree

```text
NavRail
└── NavVBox
    ├── PagesLabel
    ├── PageButtonsList
    │   ├── BtnOverview
    │   ├── BtnStatus
    │   ├── BtnSectors
    │   ├── BtnPower
    │   ├── BtnDefense
    │   ├── BtnSensors
    │   ├── BtnIncidents
    │   ├── BtnArchive
    │   ├── BtnRecon
    │   ├── BtnContracts
    │   ├── BtnHistory
    │   └── BtnSettings
    ├── Spacer
    ├── ActionsLabel
    └── ActionButtonsList
        ├── BtnWait
        ├── BtnWait10x
        ├── BtnFocus
        ├── BtnHarden
        ├── BtnReset
        ├── BtnReboot
        └── BtnHelp
```

## Behavior

* one selected page at a time
* page buttons visible even when disabled
* contextual enable/disable by mode and state
* tooltips explain disabled reasons
* keyboard navigation required

---

# 8. Right transcript panel spec

## Node tree

```text
TranscriptPanel
└── TranscriptVBox
    ├── FilterRow
    │   ├── ToggleInfo
    │   ├── ToggleAlert
    │   ├── ToggleCritical
    │   └── ToggleSystem
    └── ScrollContainer
        └── EntriesVBox
            ├── TranscriptEntryRow
            ├── TranscriptEntryRow
            └── ...
```

## Entry row structure

```text
TranscriptEntryRow
└── EntryVBox
    ├── EntryHeaderHBox
    │   ├── TimestampLabel
    │   ├── SeverityBadge
    │   └── LinkButtonOptional
    └── MessageLabel
```

## Transcript entry contract

* `timestamp_label`
* `severity`
* `message`
* `linked_page`
* `linked_sector_id`
* `linked_incident_id`
* `is_clickable`

## Rules

* newest entries append to bottom
* transcript never clears on page changes
* clicking an entry navigates to relevant page/sector when link data exists
* transcript filters are local visual filters only

---

# 9. Boot sequence overlay spec

## Node tree

```text
BootSequenceOverlay
└── BootCenter
    └── BootVBox
        ├── BootTitleLabel
        ├── BootProgressLabel
        └── BootTranscriptScroll
            └── BootLinesVBox
```

## Sequence requirements

1. black screen
2. title line appears
3. boot lines type in progressively
4. audio cues at line clusters
5. final system command availability lines printed
6. shell fades in or overlay retracts
7. overview page becomes active

## Minimum lines to include

* link initialization
* comms integrity check
* archive integrity check
* topology sync
* sector map projection online
* command surface unlocked
* status available
* wait available
* wait 10x available
* focus available
* harden available
* help available

---

# 10. Page scene contracts

All pages should inherit from a common base script if convenient.

## Suggested base script

`TerminalPageBase.gd`

Methods:

* `bind_view_model(vm)`
* `on_page_selected()`
* `on_page_deselected()`
* `refresh_from_state(vm)`
* `get_default_focus_node()`

Each page should be self-contained and not directly reach into simulation state.

---

# 11. OVERVIEW page

## Scene tree

```text
OverviewPage
└── OverviewVBox
    ├── TopCardsRow
    │   ├── OperationalSummaryCard
    │   ├── PowerSummaryCard
    │   └── AssaultSummaryCard
    ├── MapSection
    │   └── SectorMapWidget
    └── BottomRow
        ├── PrioritySectorsPanel
        ├── ActiveIncidentsPanel
        └── RecommendedAttentionPanel
```

## View model

`OverviewPageViewModel`

Fields:

* `operational_summary`
* `power_summary`
* `assault_summary`
* `sector_map_nodes`
* `priority_sector_rows`
* `active_incident_rows`
* `recommended_attention_rows`

## Interaction

* clicking map node -> open sectors page focused on that sector
* clicking incident -> open incidents page with detail selected
* clicking recommendation -> open related page/sector

---

# 12. STATUS page

## Scene tree

```text
StatusPage
└── StatusHBox
    ├── LeftRawPane
    │   └── StatusRawBlock
    └── RightVBox
        ├── ParsedSummaryCardsRow
        ├── SectorStatusCardsPanel
        └── FidelityExplanationPanel
```

## View model

`StatusPageViewModel`

Fields:

* `raw_status_text`
* `parsed_header_rows`
* `parsed_sector_rows`
* `fidelity_state`
* `fidelity_explanation_text`

## Critical rule

`raw_status_text` must come only from `TerminalStatusFormatter.gd`.

---

# 13. SECTORS page

## Scene tree

```text
SectorsPage
└── SectorsHBox
    ├── SectorTablePanel
    │   └── SectorTable
    ├── SectorDetailPanel
    │   └── SectorDetailVBox
    └── SectorSideInfoPanel
        ├── LocalIncidentsPanel
        ├── TravelContextPanel
        └── LinkedSystemsPanel
```

## Sector table columns

* sector
* category
* status
* power
* defense
* hostiles
* operator_present
* priority

## Detail action buttons

* OpenPowerView
* OpenDefenseView
* PinSector
* SetPriority
* TrackIncidents
* PowerToggle
* PrioritizeDefense
* PrioritizeSensors
* LoadShed
* TargetPriority

## View model

`SectorsPageViewModel`

Fields:

* `sector_rows`
* `selected_sector_id`
* `selected_sector_detail`
* `selected_sector_local_incidents`
* `selected_sector_travel_context`
* `selected_sector_linked_systems`
* `selected_sector_actions`

---

# 14. POWER page

## Scene tree

```text
PowerPage
└── PowerVBox
    ├── GlobalPowerSummaryBar
    ├── MainPowerRow
    │   ├── PowerSourcesPanel
    │   ├── SectorAllocationMatrixPanel
    │   └── SelectedSystemDetailPanel
    └── BottomPowerActionRow
        ├── RoutingPresetsPanel
        └── PowerActionBar
```

## Matrix rules

* rows are sectors
* columns are power categories
* each cell renders current allocation, requested allocation, priority tier, and online state indicator

## View model

`PowerPageViewModel`

Fields:

* `global_power_summary`
* `source_rows`
* `allocation_matrix_rows`
* `selected_system_detail`
* `routing_preset_buttons`
* `power_action_buttons`
* `is_read_only`

---

# 15. DEFENSE page

## Scene tree

```text
DefensePage
└── DefenseVBox
    ├── DefenseReadinessSummary
    ├── DefenseMainRow
    │   ├── DefenseAssetsTablePanel
    │   ├── DefenseAssetDetailPanel
    │   └── TargetPriorityPanel
    └── CoveragePreviewPanel
```

## View model

`DefensePageViewModel`

Fields:

* `readiness_summary`
* `asset_rows`
* `selected_asset_detail`
* `target_priority_modes`
* `coverage_preview_data`
* `manual_override_available`

---

# 16. SENSORS page

## Scene tree

```text
SensorsPage
└── SensorsVBox
    ├── FidelitySummaryBar
    ├── SensorsMainRow
    │   ├── SensorAssetsPanel
    │   ├── TacticalIntelMapPanel
    │   └── ContactListPanel
    └── PredictionStripPanel
```

## View model

`SensorsPageViewModel`

Fields:

* `fidelity_summary`
* `sensor_rows`
* `tactical_map_nodes`
* `contact_rows`
* `prediction_rows`
* `is_precise_tracking_available`

## Rules

* when fidelity is degraded, map substitutes activity-state tags for exact positions
* activity labels should be represented explicitly as gameplay states, not generic flavor text

---

# 17. INCIDENTS page

## Scene tree

```text
IncidentsPage
└── IncidentsVBox
    ├── FilterBar
    ├── IncidentTablePanel
    │   └── IncidentTable
    └── IncidentDetailPanel
```

## Filters

* severity
* sector
* type
* unresolved only
* recent window

## View model

`IncidentsPageViewModel`

Fields:

* `available_filters`
* `selected_filters`
* `incident_rows`
* `selected_incident_detail`
* `suggested_page_link`
* `can_acknowledge`

---

# 18. ARCHIVE page

## Scene tree

```text
ArchivePage
└── ArchiveVBox
    ├── ArchiveIntegritySummaryBar
    ├── ArchiveMainRow
    │   ├── CategoryTreePanel
    │   ├── ArchiveNodeDetailPanel
    │   └── ArchiveImplicationsPanel
```

## View model

`ArchivePageViewModel`

Fields:

* `archive_integrity_summary`
* `category_tree_rows`
* `selected_node_detail`
* `selected_node_implications`
* `selected_node_unlocks`
* `selected_node_conflicts`

---

# 19. RECON page

## Scene tree

```text
ReconPage
└── ReconVBox
    ├── ReconHypothesisSummaryBar
    ├── ReconMainRow
    │   ├── ReconTargetListPanel
    │   ├── ReconTargetDetailPanel
    │   └── ClarityGainPreviewPanel
```

## View model

`ReconPageViewModel`

Fields:

* `hypothesis_summary`
* `recon_target_rows`
* `selected_target_detail`
* `clarity_gain_preview`
* `recon_action_buttons`

---

# 20. CONTRACTS page

## Scene tree

```text
ContractsPage
└── ContractsVBox
    ├── ContractsSummaryBar
    ├── ContractsMainRow
    │   ├── ScenarioListPanel
    │   ├── ScenarioSummaryPanel
    │   └── RewardRiskPanel
    └── ContractActionBar
```

## View model

`ContractsPageViewModel`

Fields:

* `scenario_rows`
* `selected_scenario_detail`
* `selected_scenario_reward_risk`
* `available_actions`
* `active_scenario_slot_info`

---

# 21. HISTORY page

## Scene tree

```text
HistoryPage
└── HistoryVBox
    ├── HistoryTabBar
    └── HistoryStack
        ├── CommandLogTab
        ├── AssaultsTab
        ├── CampaignsTab
        ├── LossesTab
        └── DiscoveriesTab
```

## View model

`HistoryPageViewModel`

Fields:

* `active_tab`
* `tab_rows_by_name`
* `selected_history_detail`

---

# 22. SETTINGS page

## Scene tree

```text
SettingsPage
└── SettingsVBox
    ├── TextScaleSection
    ├── LogSpeedSection
    ├── AudioSection
    ├── AccessibilitySection
    ├── VerbositySection
    └── InputSection
```

## View model

`SettingsPageViewModel`

Fields:

* `text_scale_options`
* `log_speed_options`
* `audio_toggle_options`
* `accessibility_color_options`
* `verbosity_options`
* `input_mode_options`

---

# 23. Command palette spec

## Scene tree

```text
CommandPalette
└── PaletteCenter
    └── PaletteVBox
        ├── PromptLabel
        ├── InputLineEdit
        ├── SuggestionsList
        └── ValidationLabel
```

## Supported commands for MVP

* `status`
* `wait`
* `wait 10x`
* `focus <target>`
* `harden <sector>`
* `help`
* `goto <page>`
* `sector <name>`
* `power preset <name>`
* `reboot`
* `reset`

## Validation rules

* invalid commands produce explicit reject reason
* unavailable commands explain why they are unavailable
* successful commands append transcript entry
* state-changing commands request confirm modal when appropriate

---

# 24. Confirm modal spec

## Scene tree

```text
ConfirmModal
└── ModalCenter
    └── ModalPanel
        └── ModalVBox
            ├── TitleLabel
            ├── BodyLabel
            └── ButtonsRow
                ├── ConfirmButton
                └── CancelButton
```

Use for:

* reset
* reboot
* scenario accept/abandon
* destructive power changes
* archive-affecting actions

---

# 25. Shared widget contracts

## `SummaryCard`

Inputs:

* title
* rows array of key/value pairs
* optional severity accent
* optional action button

## `DataTable`

Inputs:

* columns
* rows
* selected_row_id
* sort state
* filter state
* row click callback

## `DetailPanel`

Inputs:

* section title
* grouped fields
* action buttons
* empty state text

## `ActionBar`

Inputs:

* button definitions
* enabled states
* callbacks

## `FilterBar`

Inputs:

* filter dropdown configs
* toggle configs
* callbacks

## `SectorMapWidget`

Inputs:

* node list
* edge list
* selected node id
* status styling info
* click callback
* hover callback optional

---

# 26. Input map and controls

## Required actions

Create input actions for:

* `terminal_toggle`
* `terminal_nav_up`
* `terminal_nav_down`
* `terminal_nav_left`
* `terminal_nav_right`
* `terminal_accept`
* `terminal_back`
* `terminal_command_palette`
* `terminal_acknowledge`
* `terminal_page_overview`
* `terminal_page_status`
* `terminal_page_sectors`
* `terminal_page_power`
* `terminal_page_defense`
* `terminal_page_sensors`
* `terminal_page_incidents`
* `terminal_page_archive`
* `terminal_page_recon`
* `terminal_page_contracts`
* `terminal_page_history`
* `terminal_page_settings`

## Recommended defaults

* `Tab` cycle focus regions
* `Esc` close modal/back
* `Enter` accept
* `/` open command palette
* `Space` acknowledge highlighted incident
* optional number keys for page shortcuts

---

# 27. UI state machine

## Terminal modes

Use an enum:

* `BOOT`
* `HUB`
* `CAMPAIGN_COMMAND`
* `FIELD`
* `LOCKED`

## Transition rules

* `BOOT -> HUB` on hub load
* `BOOT -> CAMPAIGN_COMMAND` on active campaign command context
* `CAMPAIGN_COMMAND -> FIELD` when player leaves command-capable context
* `FIELD -> CAMPAIGN_COMMAND` when player re-enters command center
* `any -> LOCKED` if terminal unavailable due to scenario or damage state

## Per-mode restrictions

### HUB

* emphasize archive, recon, contracts, history
* no live assault panels unless active scenario preparation needs it

### CAMPAIGN_COMMAND

* all command pages available
* power and defense controls active
* full or degraded fidelity depending on comms

### FIELD

* read-only or reduced command actions
* power/defense action buttons disabled
* sensors precision reduced
* command shell remains partially available

### LOCKED

* shell may show unavailable state with reason

---

# 28. Styling rules

## Visual rules

* dark matte background
* muted green primary text
* amber for caution
* red for critical
* avoid saturated neon overload
* no decorative holographic chrome

## Typography rules

* mono font for transcript and raw status
* mono or condensed sans for headings
* all caps for operational labels
* sentence case only for longer archive/recon descriptions if needed

## Layout rules

* preserve margin spacing consistency
* no cramped tables
* major page sections should align to a shared grid
* transcript width should remain large enough for readable lines

## Motion rules

* subtle only
* no continuous noisy animation
* alert flash should be brief and event-driven
* page transitions should be minimal and fast

---

# 29. Data integration rules

## Hard rule

The UI must read derived view models, not direct runtime nodes or raw simulation structures scattered throughout widgets.

## Recommended source integration pattern

1. simulation state updates
2. `TerminalViewModelFactory` builds fresh page VMs
3. `TerminalUiController` binds VM data into shell and active page
4. transcript receives append-only event updates
5. header refreshes independently

## Avoid

* page widget directly querying combat managers
* page widget directly mutating simulation objects
* duplicate status text generation logic in multiple files

---

# 30. Raw status formatter requirements

`TerminalStatusFormatter.gd` must be the only system producing canonical `STATUS` text.

It must accept:

* sim time
* fidelity state
* threat state
* assault state
* archive state
* posture
* sector snapshot list

It must output one deterministic text block with fidelity-dependent omissions/generalizations.

Use this same output in:

* transcript `STATUS` responses
* status page raw block
* debug snapshots if needed

---

# 31. Page-specific selection persistence

The shell should preserve recent selection context:

* last selected sector id
* last selected incident id
* last selected defense asset id
* last selected sensor contact id
* last selected archive node id
* last selected scenario id

When revisiting a page, restore last valid selection if still present.

---

# 32. Empty and degraded states

Each page must define an empty state.

Examples:

* no active incidents
* no visible contacts
* no available contracts
* no archive node selected
* no command access from field mode

Degraded-state examples:

* `Exact hostile positions unavailable under current comms fidelity.`
* `Power routing is read-only outside Command mode.`
* `No scenario proposals available.`

---

# 33. Accessibility and usability requirements

* text scale setting required
* color should not be only signal for severity
* all tables navigable by keyboard
* selected rows must have clear non-color indication
* disabled buttons require tooltip/help text
* transcript clickable links need focusable keyboard targets

---

# 34. Codex implementation order

Implement in this order:

1. terminal shell scene and layout scaffolding
2. header bar + nav rail + transcript panel
3. page switching controller
4. boot sequence overlay
5. command palette + confirm modal
6. overview page
7. status page + canonical status formatter
8. sectors page + sector map widget
9. incidents page
10. power page
11. defense page
12. sensors page
13. archive page
14. recon page
15. contracts page
16. history page
17. settings page
18. keyboard polish + mode restrictions + persistence

This order ensures the shell becomes useful early while preserving the architecture.

---

# 35. Acceptance criteria

Codex implementation is acceptable when:

* terminal opens into a persistent shell
* header remains stable across all page switches
* nav rail routes correctly between all pages
* transcript persists and appends entries
* overview page displays summary cards, map, incidents, and recommendations
* status page shows canonical raw status plus parsed mirrors
* sectors page supports selection and linked actions
* power page clearly renders sources, allocations, and actions
* defense and sensors pages support asset/contact inspection
* archive, recon, contracts, and history pages exist as structured interfaces
* command palette executes supported commands and logs results
* mode restrictions work between hub/command/field
* no page directly owns simulation logic
* data flows through view models/services cleanly

---

# 36. Final implementation note

If runtime naming conventions in the project differ, preserve the architecture and data flow even if individual filenames change. The non-negotiable parts are:

* persistent four-zone shell
* canonical status formatter
* page-based command UI
* transcript persistence
* view-model isolation from deterministic game logic
* command vs field information asymmetry
