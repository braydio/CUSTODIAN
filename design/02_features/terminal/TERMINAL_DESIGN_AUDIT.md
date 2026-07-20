# Command Terminal — Design Audit

**Audit Date:** 2026-07-20
**Audited Commit:** `ed65c73e3215b816facd432b04cc44877fae639e`
**Source of Truth:** GitHub `braydio/CUSTODIAN` (freshest repository state)
**Terminal Authority:** `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
**Runtime Authority:** Godot files under `custodian/`

This was a source/design audit, not a rendered playtest.

---

## Overall Verdict

The terminal has a strong shell. Modal full-screen presentation, navigation rail, status chips, transcript, command input, tactical minimap, Overview hierarchy, Sectors page, and Fabrication page are substantially implemented. Layout and input containment at 1366x768 have focused automated coverage. Fabrication is the most complete page. Sectors is the most complete tactical page.

**The main problem is functional honesty.** The terminal visually presents itself as a mature thirteen-page command system, but several pages are currently static summaries, inferred data, hardcoded placeholders, or alternate views of the transcript. It looks more operational than it actually is.

---

## Page Maturity Matrix

```
SHELL            complete-v1
OVERVIEW         functional-partial
STATUS           readout-placeholder
SECTORS          functional-v1
POWER            readout-partial
DEFENSE          readout-scaffold
FABRICATION      functional-v1
SENSORS          readout-scaffold
INCIDENTS        transcript-scaffold
ARCHIVE          placeholder
RECON            placeholder
CONTRACTS        active-contract-only
HISTORY          transcript-mirror
SETTINGS         placeholder
```

---

## Required Changes

### 1. P0 — Authoritative Terminal Snapshot and Canonical STATUS

**Implementation status (2026-07-20): complete-v1.** The snapshot now uses physics frames and the configured physics tick rate, reports actual simulation rate, derives command/field mode from physical terminal authority, derives fidelity through a dedicated policy, reports unavailable archive authority honestly, and supplies the sole formatter used by both STATUS surfaces. `terminal_status_fidelity_smoke.gd` covers all four fidelity levels and omission rules.

**Problem:** The terminal hardcodes `MODE=COMMAND`, `FIDELITY=FULL`, `RATE=1X`, `ARCHIVE=NOMINAL`. The STATUS page prints these values regardless of actual state. The snapshot uses the OS clock (`Time.get_time_string_from_system()`) rather than a simulation clock.

**Why it matters:** Information asymmetry is foundational to the terminal design. Command mode must provide more exact information than degraded fidelity. Hardcoded values break that contract entirely.

**Required files:**

```
custodian/game/ui/terminal/terminal_status_formatter.gd
custodian/game/ui/terminal/terminal_fidelity_policy.gd
```

**Update:**

```
custodian/game/ui/terminal/terminal_snapshot.gd
custodian/game/ui/hud/ui.gd
```

**Snapshot should expose:**

```gdscript
{
    "simulation_tick": 0,
    "simulation_seconds": 0.0,
    "simulation_rate": 1.0,
    "terminal_mode": &"command",
    "fidelity": &"full",
    "archive_state": &"nominal",
    "operator_location": &"",
    "command_center_occupied": false,
}
```

**Formatter** should be the only component allowed to generate canonical STATUS text. Both the STATUS page and the typed `STATUS` command must consume it.

**Validation:**

```
custodian/tools/validation/terminal_status_fidelity_smoke.gd
```

Prove all four fidelity levels, omission rules, command/field mode differences, and non-wall-clock timestamps.

---

### 2. P0 — Finish Command-Router Extraction from the HUD

**Problem:** `terminal_command_router.gd` is a parser and validator only. Its execution method explicitly describes itself as a temporary compatibility bridge and sends every command back into `_execute_local_terminal_command_legacy()` in the HUD controller (`ui.gd`). Terminal commands are still owned by the enormous HUD script. Command schemas and page controls can drift independently. Help, completion, validation, and execution use different hardcoded lists. Testing a command requires instantiating the entire HUD.

**Required files:**

```
custodian/game/ui/terminal/terminal_command_registry.gd
custodian/game/ui/terminal/terminal_command_context.gd
custodian/game/ui/terminal/commands/
    terminal_navigation_commands.gd
    terminal_power_commands.gd
    terminal_defense_commands.gd
    terminal_fabrication_commands.gd
    terminal_arrn_commands.gd
    terminal_system_commands.gd
```

**Each command definition:**

```gdscript
{
    "id": &"reroute_power",
    "syntax": "REROUTE POWER sector=<sector> priority=<priority>",
    "aliases": ["REROUTE"],
    "parameters": {...},
    "required_mode": &"command",
    "danger_class": &"normal",
    "refresh_policy": &"power_and_sectors",
}
```

**Derived from the same registry:**
- Known verbs
- Help output
- Completion tokens
- Parameter suggestions
- Button enabled/disabled state
- Confirmation requirements
- Execution dispatch
- Snapshot refresh policy

The current completion list already contains duplicates and mixed legacy forms (`ALLOCATE DEFENSE` and `ALLOCATE_DEFENSE`, repeated FAB and DEPLOY entries).

**Validation:**

```
custodian/tools/validation/terminal_command_registry_smoke.gd
```

---

### 3. P1 — Replace Overview Placeholders with Authoritative Diagnosis

**Implementation status (2026-07-20): complete-v1.** `terminal_overview_view_model.gd` now applies the documented score weights, returns stable incident/recommendation IDs, reports actual Operator location plus offline/cold-start counts, and drives the existing Overview cards without changing their hierarchy. `terminal_overview_semantics_smoke.gd` proves that an alphabetically late critical sector ranks first.

**Problem:** Overview hardcodes `OPERATOR FIELD LINK` rather than an actual location. Priority sectors are taken from the first two entries of the alphabetically sorted sector array. Incidents are sourced from the last two warning-like transcript lines. Recommendations follow a small `if/elif` chain. This can recommend a healthy alphabetical sector while ignoring a later critical sector.

**Required file:**

```
custodian/game/ui/terminal/terminal_overview_view_model.gd
```

**Scoring system for candidate problems:**

```
+100  compromised/offline
 +80  active hostile objective
 +60  HP <= 30%
 +40  negative power margin
 +30  unresolved critical incident
 +20  Operator currently present
 +10  high strategic priority
```

**Expose:**

```gdscript
"priority_sectors": [...]
"active_incidents": [...]
"recommendations": [...]
"operator_location": ...
"systems_offline_count": ...
"cold_start_systems_count": ...
```

Recommendations should produce stable recommendation IDs, not already-formatted prose.

**Validation:**

```
custodian/tools/validation/terminal_overview_semantics_smoke.gd
```

Put an alphabetically late sector into a critical state and prove it becomes the first recommendation.

---

### 4. P1 — Turn POWER into the Terminal's Principal Command Surface

**Problem:** The design calls POWER the heart of command (source-system table, allocation matrix, selected-system detail, routing presets, action bar, Command Center authority restrictions). The runtime page currently renders four global values, four preset names as plain text, and a basic sector allocation table. Typed commands can mutate sector priority, but routine page interaction does not expose it.

**Required files:**

```
custodian/game/ui/terminal/power_terminal_view_model.gd
custodian/game/ui/terminal/terminal_authority_policy.gd
```

**Page needs:**
- Clickable preset buttons with current preset highlighted
- Preview of allocation changes before applying
- Per-sector priority controls
- Source status and stability
- Brownout and cold-start states
- Time-to-online
- Explicit reserve versus deficit
- `APPLY ROUTE`, `RESTORE DEFAULTS`, and protected emergency shedding
- Read-only presentation outside Command Center
- Transcript entry showing before/after values

**Rule:** Do not silently apply a preset by selecting it. Selection stages a route; `APPLY ROUTE` commits it.

---

### 5. P1 — Build Actual Defense, Sensors, and Incident Models

#### DEFENSE

Current page infers coverage from sector HP/state and counts turrets by walking their parent hierarchy at render time. Target-mode list is static text.

**Still needs:** Defense asset list, power/readiness/ammunition, LOS state, current target, engagement rule, selected-asset detail, coverage gaps, real target-priority controls.

```
custodian/game/ui/terminal/defense_terminal_view_model.gd
```

#### SENSORS

**Needs:** Dedicated contact model with stable contact IDs, last-known position, activity, confidence, information age, source sensor, fields hidden by current fidelity, sector activity aggregation when exact positions are unavailable.

```
custodian/game/ui/terminal/sensors_terminal_view_model.gd
```

#### INCIDENTS

Current incidents are primarily transcript entries. Design calls for a filterable event-triage system with status and linked pages.

```
custodian/game/systems/incidents/incident_record.gd
custodian/game/systems/incidents/incident_registry.gd
custodian/game/ui/terminal/incidents_terminal_view_model.gd
```

**Incident identity and lifecycle:**

```gdscript
{
    "incident_id": &"",
    "created_tick": 0,
    "resolved_tick": -1,
    "severity": &"alert",
    "type": &"power_failure",
    "sector_id": &"",
    "status": &"open",
    "linked_page": &"power",
}
```

The transcript may mirror incidents but should not be their authority.

---

### 6. P1 — Stop Presenting Placeholder Meta-Pages as Finished Systems

Several pages fabricate completeness:
- ARCHIVE hardcodes `STATE NOMINAL`
- RECON hardcodes `HYP-01`, `HYP-02`, `HYP-03`
- CONTRACTS only presents the active contract
- SETTINGS displays static text
- STATUS hardcodes fidelity and archive state

Until associated systems exist, pages should either:
1. Display an explicit bounded state such as `SYSTEM NOT YET RESTORED` with genuinely available evidence beneath it
2. Be disabled with a clear unlock or implementation-state reason

Do not display `NOMINAL`, `FULL`, fake hypotheses, or apparent selectable policies unless those states are authoritative.

```
custodian/game/ui/terminal/archive_terminal_view_model.gd
custodian/game/ui/terminal/recon_terminal_view_model.gd
custodian/game/ui/terminal/contracts_terminal_view_model.gd
custodian/game/ui/terminal/settings_terminal_view_model.gd
```

---

### 7. P1 — Separate Operational History from the Bounded Transcript

**Problem:** Design states HISTORY is chronological and nothing mutates or disappears. Runtime conflicts: terminal log storage is capped at 1,000 entries, HISTORY displays only the last 14 entries, `CLEAR` empties the same log data used by HISTORY.

**Required model:**

```
custodian/game/systems/history/operational_history.gd
custodian/game/ui/terminal/history_terminal_view_model.gd
```

The terminal transcript can remain bounded and clearable. Operational history should be append-only for the current run, with tabs/filters for: commands, assaults, losses, discoveries, archive changes, system changes. `CLEAR` should clear only the visible transcript buffer.

---

### 8. P2 — Complete Command Usability

The specification calls for a `/` command palette and parameter suggestions. Current input has command history, tab completion, inline verb validation, and keyboard focus handling.

**Next improvements:**
- `/` palette
- Argument-aware suggestions
- Sector-name completion
- Preset and recipe completion
- Quoted arguments
- Visible syntax/error segment highlighting
- Command examples based on current page
- Destructive-command confirmation modal
- Staged tactical preview for deployment and routing

Driven from the proposed command registry, not another completion-token array.

---

### 9. P2 — Continue Decomposing `ui.gd`

The terminal still lives inside a HUD script that also controls the regular HUD, debug UI, weapons, health, camera status, crosshair, minimap, fabrication interactions, terminal rendering, command execution, and placement integration.

**Target structure:**

```
custodian/game/ui/terminal/
    terminal_shell_controller.gd
    terminal_snapshot.gd
    terminal_command_registry.gd
    terminal_command_router.gd
    terminal_status_formatter.gd
    terminal_authority_policy.gd
    terminal_overview_view_model.gd
    power_terminal_view_model.gd
    defense_terminal_view_model.gd
    sensors_terminal_view_model.gd
    incidents_terminal_view_model.gd
    archive_terminal_view_model.gd
    recon_terminal_view_model.gd
    contracts_terminal_view_model.gd
    history_terminal_view_model.gd
    settings_terminal_view_model.gd
```

`ui.gd` should eventually be reduced to:
- Open/close integration
- HUD suppression/restoration
- Passing game dependencies into the terminal shell
- Receiving high-level terminal events

---

## Validation Gap

The existing Overview smoke is strong for containment, navigation, scrolling, pointer behavior, map size, card visibility, and action-link routing. The documented validation set is primarily layout, typography, stylebox, modal, and Fabrication-focused.

It does not prove:
- Correct priority ranking
- Real Operator location
- Fidelity degradation
- Command Center authority
- Power route preview/commit
- Incident lifecycle
- Immutable history
- Archive uncertainty
- Sensor field omission
- Command registry/help/completion consistency

This explains how visually complete but semantically shallow pages pass the current suite.

---

## Documentation Drift Fixed

### Conflicting authority claims

`COMMAND_TERMINAL_SPEC.md` supersedes the older concept and roadmap. `TERMINAL_COMMAND_INTERFACE.md` still called itself the shell/interface authority and was marked implementation-ready.

**Fixed:** `TERMINAL_COMMAND_INTERFACE.md` marked as superseded-reference with authority pointing to `COMMAND_TERMINAL_SPEC.md`.

### Twelve versus thirteen pages

`COMMAND_TERMINAL_SPEC.md` listed twelve pages and omitted Fabrication from the numbered list, while its safe-layout paragraph included Fabrication.

**Fixed:** Canonical count normalized to thirteen. Fabrication added to the numbered page list.

### Roadmap stale state

`ROADMAP_COMMAND_TERMINAL.md` carried checkboxes suggesting slices were fully implemented and pointed at the stale path `custodian/scenes/ui.gd`.

**Fixed:** Roadmap replaced with page maturity matrix. Stale paths corrected.

---

## Recommended Implementation Sequence

1. **Semantic integrity — complete-v1:** Snapshot, simulation clock, fidelity policy, canonical STATUS, Overview ranking.
2. **Command architecture:** Registry, schemas, router extraction, shared help/completion.
3. **Operational command pages:** Power first, then Defense, Sensors, and Incidents.
4. **Persistent records:** Incident registry and operational history.
5. **Meta systems:** Archive, Recon, Contracts, and real Settings.
6. **Visual polish:** Transitions, globe markers, threat vectors, sounds, and map command previews.

No new terminal art assets are necessary for the first four stages. Existing assets under `custodian/content/ui/terminal/` are sufficient. Functionality and semantic accuracy should precede another visual pass.

---

## One-Time Audit Command

```bash
rg -n \
  'FIDELITY=FULL|ARCHIVE=NOMINAL|OPERATOR FIELD LINK|HYP-0[123]|slice\(0, min\(2|_execute_local_terminal_command_legacy|Time\.get_time_string_from_system|_terminal_log_entries\.clear' \
  custodian/game/ui/hud/ui.gd \
  custodian/game/ui/terminal \
  design/02_features/terminal \
  design/01_systems
```

---

## Context Pack Generation

```bash
npx repomix@latest \
  --include "AGENTS.md,custodian/AGENTS.md,custodian/scenes/game.tscn,custodian/game/ui/hud/ui.gd,custodian/game/ui/terminal/**,custodian/game/ui/minimap/**,custodian/game/systems/power/**,custodian/tools/validation/*terminal*.gd,custodian/tools/validation/fabrication_terminal_*.gd,design/02_features/terminal/**,design/01_systems/TERMINAL_COMMAND_INTERFACE.md,design/01_systems/ROADMAP_COMMAND_TERMINAL.md,custodian/docs/ai_context/{CURRENT_STATE.md,CONTEXT.md,FILE_INDEX.md,VALIDATION_RECIPES.md}" \
  --include-diffs \
  --include-logs \
  --include-logs-count 20 \
  --output-show-line-numbers \
  --style xml \
  --output reports/terminal_design_audit_context.xml
```
