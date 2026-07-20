# Terminal Design Audit — Verification Against Live Runtime

**Audit Date:** 2026-07-20
**Audited Document:** `design/02_features/terminal/TERMINAL_DESIGN_AUDIT.md`
**Runtime Files Verified:** `custodian/game/ui/hud/ui.gd` (6801 lines), `custodian/game/ui/terminal/*.gd` (12 files), `custodian/tools/validation/*terminal*.gd` (9 files)

This document corrects factual errors in the original audit by verifying claims against the actual Godot runtime code.

---

## Critical Corrections

### 1. FIDELITY POLICY — ALREADY IMPLEMENTED

**Audit claimed:** "Create `terminal_fidelity_policy.gd`" and "Create `terminal_status_formatter.gd`"

**Reality:** Both files exist and are fully functional:
- `custodian/game/ui/terminal/terminal_fidelity_policy.gd` (98 lines) — implements four fidelity levels (FULL/DEGRADED/FRAGMENTED/LOST), resolves fidelity from terminal mode + comms sector state + ARRN reconstruction, enforces field-mode degradation ceiling
- `custodian/game/ui/terminal/terminal_status_formatter.gd` (179 lines) — fidelity-aware STATUS output with per-level omission rules, bucketed counts, generalized archive state, simulation clock formatting

**The fidelity system is not missing. It is implemented and tested.**

### 2. SIMULATION CLOCK — ALREADY IMPLEMENTED

**Audit claimed:** "The snapshot uses `Time.get_time_string_from_system()` rather than a simulation clock"

**Reality:** `terminal_snapshot.gd` line 31 uses `_format_simulation_time(float(simulation_tick) / float(simulation_ticks_per_second))`. No reference to `Time.get_time_string_from_system()` exists anywhere in `ui.gd` or the terminal directory. The fidelity smoke (`terminal_status_fidelity_smoke.gd` line 56) explicitly asserts this: `"Terminal snapshot must not use the operating-system clock."`

### 3. OVERVIEW RANKING — ALREADY IMPLEMENTED

**Audit claimed:** "Create `terminal_overview_view_model.gd`" with a scoring system

**Reality:** `custodian/game/ui/terminal/terminal_overview_view_model.gd` (153 lines) already exists with the exact scoring system the audit recommended:
- +100 compromised/offline
- +80 active hostile objective
- +60 HP <= 30%
- +40 negative power margin
- +30 unresolved critical incident
- +20 operator present
- +10 strategic priority

Sectors are sorted by `diagnostic_score` (descending), not alphabetically. Alphabetical is only the tiebreaker (line 143).

**The overview scoring is not proposed — it is implemented.**

### 4. OVERVIEW SEMANTICS SMOKE — ALREADY EXISTS

**Audit claimed:** "Add `terminal_overview_semantics_smoke.gd`" to prove an alphabetically late critical sector ranks first

**Reality:** `custodian/tools/validation/terminal_overview_semantics_smoke.gd` (67 lines) already exists and does exactly this — it puts "ZETA KEEP" (alphabetically late) into critical state and asserts it ranks first with score 340.

### 5. STATUS FIDELITY SMOKE — ALREADY EXISTS

**Audit claimed:** "Add `terminal_status_fidelity_smoke.gd`" to prove all four fidelity levels

**Reality:** `custodian/tools/validation/terminal_status_fidelity_smoke.gd` (97 lines) already exists and tests all four fidelity levels, omission rules, command/field mode differences, and non-wall-clock timestamps.

### 6. SNAPSHOT DOES NOT HARDCODE FIDELITY=FULL

**Audit claimed:** "The runtime currently hardcodes `MODE=COMMAND`, `FIDELITY=FULL`, `RATE=1X`, `ARCHIVE=NOMINAL`"

**Reality:** `terminal_snapshot.gd` resolves all of these dynamically:
- `terminal_mode` = `&"command"` if `command_center_occupied` else `&"field"` (line 20)
- `fidelity` = resolved by `TerminalFidelityPolicy.resolve()` based on terminal mode + comms state + ARRN (lines 21-23)
- `simulation_rate` = `Engine.time_scale` (line 30)
- `archive_state` = resolved by `resolve_archive_state()` which queries `/root/ArchiveManager` (line 34)

The STATUS page then renders these resolved values through the formatter, which applies per-fidelity omission rules.

---

## Partially Correct Claims

### 7. OVERVIEW OPERATOR LOCATION — ALREADY REAL

**Audit claimed:** "A hardcoded `OPERATOR FIELD LINK` line rather than an actual location"

**Reality:** The Overview page renders `view_model.get("operator_location", "UNKNOWN")` (line 3995), which comes from `snapshot.get("operator_location")`, which is resolved by `collect_operator_context()` using `_nearest_sector_name()` — real spatial proximity to sectors.

The "OPERATOR FIELD LINK" string only appears in the DEGRADED fidelity formatter (line 102 of `terminal_status_formatter.gd`), which is correct behavior — degraded fidelity should hide exact location.

### 8. ARCHIVE PAGE — MIXED

**Audit claimed:** "ARCHIVE hardcodes `STATE NOMINAL`"

**Reality:** Partially true. Line 4309 of `ui.gd` does hardcode `_terminal_kv("STATE", "NOMINAL")`. However, the rest of the page renders real data:
- Planet key from contract
- World profile label from contract
- ARRN knowledge index/max from ARRNManager
- Benefit labels from ARRN snapshot
- World profile metrics (foliage, open layout, compound area)
- Knowledge track, pending packets, dormancy pressure

The STATE field should use `snapshot.get("archive_state", "NOMINAL")` instead of hardcoding.

### 9. RECON PAGE — CONFIRMED PLACEHOLDER

**Audit claimed:** "RECON hardcodes `HYP-01`, `HYP-02`, `HYP-03`"

**Reality:** Confirmed. Lines 4345-4347 hardcode:
```
"HYP-01  SURFACE PATTERNING"
"HYP-02  POWER DISTRIBUTION"
"HYP-03  BREACH LANES"
```

### 10. SETTINGS PAGE — CONFIRMED STATIC

**Audit claimed:** "SETTINGS displays static text"

**Reality:** Confirmed. Lines 4386-4402 render hardcoded strings like "TEXT SCALE STANDARD", "LOG SPEED LIVE", etc. The only dynamic field is `_terminal_policy_preset`.

### 11. HISTORY PAGE — CONFIRMED TRANSCRIPT MIRROR

**Audit claimed:** "HISTORY displays only the last 14 entries" and "CLEAR empties the same log data"

**Reality:** Confirmed. Line 4363: `_terminal_log_entries.slice(max(0, _terminal_log_entries.size() - 14), ...)`. Lines 1780, 5377, 6632 all call `_terminal_log_entries.clear()`.

### 12. COMMAND ROUTER — CONFIRMED COMPATIBILITY BRIDGE

**Audit claimed:** "The execution method explicitly describes itself as a temporary compatibility bridge"

**Reality:** Confirmed. Line 57-61 of `terminal_command_router.gd`:
```gdscript
func execute(ui: Node, parsed: Dictionary) -> bool:
    # Temporary compatibility bridge: command parsing/validation now lives here,
    # while the legacy command handlers are migrated command-by-command.
    if ui.has_method("_execute_local_terminal_command_legacy"):
        return bool(ui.call("_execute_local_terminal_command_legacy", parsed))
    return false
```

### 13. POWER PAGE — CONFIRMED READOUT-LEVEL

**Audit claimed:** "POWER renders four global values, four preset names as plain text, and a basic sector allocation table"

**Reality:** Confirmed. Lines 4166-4194 render:
- Global power stats (TOTAL, GEN, DRAW, RESERVE)
- Four preset names as static text (BALANCED, DEFENSE FIRST, SENSORS FIRST, EMERGENCY LOAD SHED)
- Sector allocation table (name, live/std, tier, priority)

No interactive controls, no preview, no APPLY ROUTE.

### 14. DEFENSE PAGE — CONFIRMED SCAFFOLD

**Audit claimed:** "Defense infers coverage from sector HP/state and counts turrets by walking their parent hierarchy"

**Reality:** Confirmed. Line 4228: `get_tree().get_nodes_in_group("turret").size()`. Target modes are static text (lines 4230-4235). Coverage is derived from sector status (lines 4197-4220).

### 15. INCIDENTS PAGE — CONFIRMED TRANSCRIPT-BASED

**Audit claimed:** "Incidents are primarily transcript entries"

**Reality:** Confirmed. Lines 4296-4303 render the last8 `_terminal_log_entries` as the incident table.

---

## What the Audit Got Wrong (Summary)

| Claim | Reality |
|-------|---------|
| "Create terminal_status_formatter.gd" | Already exists (179 lines) |
| "Create terminal_fidelity_policy.gd" | Already exists (98 lines) |
| "Create terminal_overview_view_model.gd" | Already exists (153 lines) |
| "Add terminal_status_fidelity_smoke.gd" | Already exists (97 lines) |
| "Add terminal_overview_semantics_smoke.gd" | Already exists (67 lines) |
| "Snapshot hardcodes FIDELITY=FULL" | Resolved dynamically by fidelity policy |
| "Snapshot uses OS clock" | Uses simulation tick/formatter |
| "Overview uses alphabetically sorted sectors" | Sorted by diagnostic_score |
| "Overview hardcodes OPERATOR FIELD LINK" | Real location from spatial proximity |
| "Create terminal_authority_policy.gd" | Not yet needed — authority is in fidelity policy |
| "Create power_terminal_view_model.gd" | Not yet needed — power data flows through snapshot |

The audit wrote a design document as if it were reading the code for the first time, without verifying whether the files it recommended creating already existed. This is a significant methodological failure.

---

## What the Audit Got Right

| Claim | Verified |
|-------|----------|
| Command router is a compatibility bridge | ✅ Lines 57-61 |
| ARCHIVE hardcodes STATE NOMINAL | ✅ Line 4309 |
| RECON hardcodes HYP-01/02/03 | ✅ Lines 4345-4347 |
| SETTINGS is static text | ✅ Lines 4386-4402 |
| HISTORY is transcript mirror (last14) | ✅ Line 4363 |
| CLEAR empties shared log | ✅ Lines 1780, 5377, 6632 |
| POWER is readout-level | ✅ Lines 4166-4194 |
| DEFENSE is scaffold | ✅ Lines 4223-4236 |
| INCIDENTS uses transcript | ✅ Lines 4296-4303 |
| No commands/ subdirectory | ✅ Confirmed |
| No incident/history/architecture view models | ✅ Confirmed |
| TERMINAL_LOG_LIMIT is 1,000 | ✅ Line 368 |
| Completion list has duplicates | Not verified (would need full list audit) |

---

## Corrected Page Maturity Matrix

```
PAGE             STATUS                NOTES
─────────────────────────────────────────────────────────────
SHELL            complete-v1           Modal, nav rail, status chips, transcript, command input
OVERVIEW         functional-v1         Scored ranking, real operator location, real incidents, recommendations
STATUS           functional-v1         Fidelity-aware formatter, simulation clock, four-level omission
SECTORS          functional-v1         Sector cards, damage overlays, minimap integration
POWER            readout-partial       Four globals + basic table — needs routing controls, presets, preview
DEFENSE          readout-scaffold      Turret count + coverage inference — needs asset list, LOS, targeting
FABRICATION      functional-v1         Most complete page — recipe browse, queue, build progress
SENSORS          functional-partial    ARRN relay network + threat/hostile data — needs contact model
INCIDENTS        transcript-scaffold   Last8 transcript entries — needs incident registry + lifecycle
ARCHIVE          functional-partial    Real ARRN/contract data — STATE field should use snapshot
RECON            placeholder           Hardcoded HYP-01/02/03
CONTRACTS        functional-partial    Real contract data — needs proposal browser
HISTORY          transcript-mirror     Last14 transcript entries — needs append-only operational history
SETTINGS         placeholder           Static text — needs real controls
```

---

## Corrected Implementation Sequence

The original audit's sequence assumed files needed to be created from scratch. Since the fidelity policy, status formatter, snapshot, and overview view model already exist, the actual work is:

1. **Fix ARCHIVE STATE** — use `snapshot.get("archive_state")` instead of hardcoded "NOMINAL"
2. **Extract command router** — migrate commands from `_execute_local_terminal_command_legacy()` into registry-based dispatch
3. **Build incident registry** — `incident_record.gd`, `incident_registry.gd`, `incidents_terminal_view_model.gd`
4. **Build operational history** — `operational_history.gd`, `history_terminal_view_model.gd` (append-only, filterable)
5. **Deepen POWER page** — routing controls, preset preview, APPLY ROUTE
6. **Deepen DEFENSE page** — asset list, LOS, targeting
7. **Deepen SENSORS page** — contact model with confidence, age, source
8. **Build RECON system** — real hypothesis generation from contract/world data
9. **Build SETTINGS controls** — actual interactive settings
10. **Build CONTRACTS browser** — proposal browsing beyond active contract

---

## Validation Gap (Confirmed)

The existing validation smokes are stronger than the audit suggested:
- `terminal_status_fidelity_smoke.gd` — tests all four fidelity levels, omission rules, command/field mode, simulation clock
- `terminal_overview_semantics_smoke.gd` — tests scoring, alphabetical-late priority, stable IDs, determinism

Still missing:
- Command registry/help/completion consistency smoke
- POWER route preview/commit smoke
- Incident lifecycle smoke
- Immutable history smoke
- Sensor field omission smoke
- Fidelity-dependent page rendering smoke (does each page actually omit fields at lower fidelity?)

---

## Recommendation

The original audit should be updated with a `## Corrections` section or replaced with this verified version. The page maturity matrix and implementation sequence in the original are partially wrong because they assume implementation gaps that have already been closed.
