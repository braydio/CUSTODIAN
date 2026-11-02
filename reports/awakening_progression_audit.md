# CUSTODIAN — AWAKENING PROGRESSION + SEMANTIC COMPLETENESS AUDIT

**MODE:** AUDIT ONLY
**TARGET:** live repository / current working tree
**AREA:** Awakening / The First Return, Sections 01-10
**COMMIT AUDITED:** `de51e097d`

---

## 1. AUDITED STATE

- **Commit SHA:** `de51e097d`
- **Working tree:** Uncommitted changes are operator animation pipeline artifacts (catalog, frames, manifest, sprite deletions, fast_04 art, VFX tools, reports) — unrelated to Awakening. No Awakening source files modified.
- **Tests run:** Cannot execute headless Godot in this environment. Validation by code tracing only.

---

## 2. ACTUAL CURRENT PROGRESSION GRAPH

```
WAKE (0,160) ──► Zone01 Crèche ──► Zone02 Ambulatory ──► Zone03 Attestation
     │                    │                    │               │
     │              Console ACK?            Walk through      Walk through
     │              (one-shot flag)         (no gating)       (no gating)
     │                    │                    │               │
     │                    ▼                    ▼               ▼
     │              Zone04 Locker ──► Zone05 Dust Lung ──► Zone06 Undergate
     │                    │                    │               │
     │              P-9 GRANT?             Lift (reusable)    Walk through
     │              (one-shot flag)        (no gating)       (no gating)
     │                    │                    │               │
     │                    ▼                    ▼               ▼
     │              Zone07 Gate ──► Zone08 Approach ──► Zone09 Chapel (optional)
     │                    │                    │               │
     │                    ▼                    ▼               ▼
     │              Zone10 Road South Reach ──► SOUTH_REACH_COMPLETION_CENTER
     │                    │                    (pure coordinate trigger)
     │                    ▼                    ──► completed=true
     └──────────── South Reach barrier (visual block)

COMPLETION = Operator enters Layout.SOUTH_REACH_COMPLETION_CENTER
             NO console check, NO P-9 check, NO zone-gating
```

---

## 3. SKIP-PATH MATRIX

| Scenario | Console | P-9 | Chapel | Completion reachable | Final objective/state | Defect? |
|---|---|---|---|---|---|---|
| **A** Expected route | Used | Recovered | Skipped | YES | completed=true, HUD: ROAD OF WITNESSES // SOUTH REACH | No |
| **B** Skip console | Skipped | Recovered | Skipped | YES | completed=true, HUD stuck: Wake and read the crèche console | YES — stale objective |
| **C** Skip P-9 | Used | Skipped | Skipped | YES | completed=true, p9_recovered=false, no weapon | YES — no sidearm, no P-9 feedback line |
| **D** Skip both | Skipped | Skipped | Skipped | YES | completed=true, console=false, P-9=false | YES — entire opening bypassable |
| **E** Chapel detour | Used | Recovered | Visited | YES | No state change from Chapel | YES — zero payoff |
| **F** Backtrack | Used | Recovered | Skipped | YES | Flags stable, P-9 no dup, lift reusable | No |

---

## 4. COMPLETION CONTRACT

### RUNTIME FACT

- **Trigger:** `_on_south_reach_reached()` at `awakening_first_return.gd:680-686`
- **Condition checked:** `completed` (guard), `_is_operator(body)` (identity)
- **Conditions NOT checked:**
  - `opening_console_acknowledged` — not checked
  - `p9_recovered` — not checked
  - `current_zone_index` — not checked
  - `visited_zones` — not checked
- **Result:** `completed = true`, HUD shows "AWAKENING BLOCKOUT COMPLETE" (debug build only), emits `blockout_completed` signal
- **Downstream gameplay effect:** None

### DESIGN REQUIREMENT

- Design doc: Console "locks the opening state to FIELD RECALL DETECTED / AUTHORITY VALID / CONTINUITY UNRESOLVED; objective becomes RETURN TO POST"
- Design doc: P-9 "grants `p9_sidearm` through `InventoryManager`"
- Design intent (implied): Both are meaningful progression steps

### AMBIGUOUS / USER DECISION

Does South Reach completion REQUIRE console acknowledgement + P-9 recovery? Design implies yes; runtime says no. **DESIGN_DECISION_REQUIRED**

---

## 5. MARKER / SET-PIECE CLASSIFICATION

| Zone | ID | Classification | Runtime consumer | Notes |
|---|---|---|---|---|
| 01 | `creche_console` | IMPLEMENTED_INTERACTION | Plaque in `_build_interactables` | One-shot, fires `console_acknowledged` |
| 01 | `operator_wake` | AUTHORING_ONLY | Spawn position only | Marker |
| 02 | `hidden_reliquary` | DEAD_ORPHANED | None | MARKERS + SET_PIECES, no code |
| 02 | `lore_plaque` | DEAD_ORPHANED | None | MARKERS + SET_PIECES, no code |
| 02 | `west_service_basin` | VISUAL_LANDMARK | None | SET_PIECES |
| 02 | `east_service_basin` | VISUAL_LANDMARK | None | SET_PIECES |
| 02 | `broken_panel` | VISUAL_LANDMARK | None | SET_PIECES |
| 02 | `nw_inspection_niche` | VISUAL_LANDMARK | None | SET_PIECES |
| 03 | `stele_w1-6`, `stele_e1-6` | VISUAL_LANDMARK | None | SET_PIECES, no interaction |
| 03 | `central_aisle_trigger` | DEAD_ORPHANED | None | MARKERS kind=trigger, no trigger code |
| 03 | `sentinel_spawn_a/b` | FUTURE_ENCOUNTER | Disabled | MARKERS kind=encounter |
| 03 | `attestation_dais` | VISUAL_LANDMARK | None | SET_PIECES + MARKER |
| 03 | `sigil_fragment` | VISUAL_LANDMARK | None | SET_PIECES + MARKER |
| 04 | `p9_locker` | IMPLEMENTED_INTERACTION | SidearmLocker in scene | Grants p9_sidearm |
| 04 | `dry_basin` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 04 | `inactive_locker_a/b/c` | VISUAL_LANDMARK | None | SET_PIECES |
| 04 | `recalled_not_verified` | VISUAL_LANDMARK | None | SET_PIECES |
| 04 | `welded_locker` | VISUAL_LANDMARK | None | SET_PIECES |
| 05 | `lift_lower` | IMPLEMENTED_INTERACTION | TransitLift stations | Bidirectional |
| 05 | `lift_upper` | IMPLEMENTED_INTERACTION | TransitLift stations | Bidirectional |
| 05 | `lift_mechanism` | DEAD_ORPHANED | None | MARKERS kind=interactable, no code |
| 05 | `broken_west_bridge` | VISUAL_LANDMARK | None | SET_PIECES |
| 05 | `daylight_split` | VISUAL_LANDMARK | None | SET_PIECES |
| 05 | `scavenger_nest` | FUTURE_ENCOUNTER | Disabled | MARKERS kind=encounter |
| 05 | `central_shaft` | DEAD_ORPHANED | None | MARKERS kind=marker |
| 06 | `damaged_plinth` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `drum_west/east` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `coil_west/east` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `housing_wa/ea/wb/eb` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `route_tablets` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `fallen_shelving` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 06 | `brass_needles` | VISUAL_LANDMARK | None | SET_PIECES non-blocking |
| 06 | `route_map_wall` | VISUAL_LANDMARK | None | SET_PIECES non-blocking |
| 06 | `port_status_plaque` | IMPLEMENTED_INTERACTION | Plaque in `_build_interactables` | Readout only, no progression flag |
| 06 | `register_of_departures` | DEAD_ORPHANED | None | MARKERS kind=marker |
| 07 | `gate_aperture` | VISUAL_LANDMARK | Production art anchor | Sprite positions |
| 07 | `south_wasteland_vista` | DEAD_ORPHANED | None | MARKERS kind=marker |
| 07 | `rest_checkpoint` | VISUAL_LANDMARK | Production art anchor | RestThreshold sprite |
| 07 | `gate_pylon_west/east` | VISUAL_LANDMARK | None | SET_PIECES blocking |
| 08 | `return_to_post_beacon` | DEAD_ORPHANED | None | MARKERS kind=trigger (different from actual completion trigger) |
| 08 | `approach_sentinel` | FUTURE_ENCOUNTER | Disabled | MARKERS kind=encounter |
| 08 | `road_reveal_trigger` | IMPLEMENTED_INTERACTION | Camera reveal in `_build_triggers` | Fires `_on_reveal_triggered` |
| 08 | `road_anchor` | DEAD_ORPHANED | None | MARKERS kind=marker |
| 09 | `mosaic_center` | VISUAL_LANDMARK | None | SET_PIECES non-blocking |
| 09 | `relay_lamp_altar` | DEAD_ORPHANED | None | SET_PIECES blocking |
| 09 | `thread_anchor_nw/ne/sw/se` | VISUAL_LANDMARK | None | SET_PIECES non-blocking |
| 09 | `reward_cache` | DEAD_ORPHANED | None | MARKERS kind=marker |
| 09 | `route_leech` | FUTURE_ENCOUNTER | Disabled | MARKERS kind=encounter |
| 10 | `south_reach_completion` | IMPLEMENTED_INTERACTION | Trigger in `_build_triggers` | Pure coordinate trigger |

---

## 6. INTERACTION AFFORDANCE

| Fixture | How player knows | Radius | Input | Prompt | Missable? |
|---|---|---|---|---|---|
| Crèche console | Prompt "CRÈCHE CONSOLE" | 72px | G | Readout via show_interaction | Yes |
| P-9 locker | Prompt "AUTHORIZE DESIGNATION LOCKER" then "TAKE P-9" | 84px | E | Animation sequence + HUD | Yes |
| Dust Lung lift | Prompt "SERVICE LIFT" | 72px | Interact | Transport animation | No (reusable) |
| Damaged port console | Prompt "DAMAGED PORT CONSOLE" | 72px | G | Readout text only | Yes |

**Issues:**
- **Crèche console:** FUNCTIONAL_BUT_NOT_LEARNABLE — no tutorial or environmental cue tells player it is interactive
- **P-9 locker:** INTERACTIVE_WITHOUT_VISIBLE_AFFORDANCE — no visual indication it opens until at correct distance with prompt visible
- **Damaged port console:** LOOKS_INTERACTIVE_BUT_IS_NOT — named "console" like a progress gate, but purely flavor

---

## 7. OPTIONAL CHAPEL RESULT

Entering Chapel of Late Service provides **zero gameplay/lore/reward payoff** today.

- `reward_cache` (MARKERS): no runtime consumer
- `relay_lamp_altar` (SET_PIECES): visual only, no script
- `mosaic_center`: visual only
- `thread_anchor_*`: visual only
- `route_leech`: disabled encounter (no combat)
- No flag, no state, no HUD update, no reward

---

## 8. CONFIRMED DEFECTS

### D1 — Completion requires no authored interactions
- **Severity:** HIGH
- **Evidence:** `_on_south_reach_reached()` checks only `completed` and `_is_operator(body)`
- **Responsible:** `awakening_first_return.gd:680-686`
- **Fix:** Add `if not opening_console_acknowledged: return` and `if not p9_recovered: return` before setting completed

### D2 — Objective text stale if console skipped
- **Severity:** MEDIUM
- **Evidence:** `_set_objective(OBJECTIVE_RECOVERY)` stays after completion if console skipped
- **Responsible:** `awakening_first_return.gd:_configure_hud`, `_on_south_reach_reached`
- **Fix:** Override objective at completion (e.g., "FIRST RETURN COMPLETE")

### D3 — P-9 skipped → no sidearm, no feedback
- **Severity:** MEDIUM
- **Evidence:** No P-9 HUD line appears, nothing blocks progression
- **Responsible:** `awakening_first_return.gd:_configure_hud`
- **Fix:** HUD indicates missing P-9 state at completion

### D4 — Entire opening skippable through both authored interactions
- **Severity:** HIGH
- **Evidence:** Scenario D — all zones traversable, completion reached without touching console or locker
- **Responsible:** `awakening_first_return.gd:_on_south_reach_reached`
- **Fix:** Same as D1

### D5 — 15+ markers/set-pieces dead/orphaned
- **Severity:** MEDIUM
- **Evidence:** `hidden_reliquary`, `lore_plaque`, `central_aisle_trigger`, `lift_mechanism`, `register_of_departures`, `return_to_post_beacon`, `road_anchor`, `reward_cache`, `relay_lamp_altar`, `south_wasteland_vista`, `attestation_dais`, `sigil_fragment`, `central_shaft` — zero runtime consumers
- **Fix:** Implement or demote to AUTHORING_ONLY with defer note

### D6 — Lift_mechanism marker orphaned
- **Severity:** LOW
- **Evidence:** MARKERS kind=interactable at (448,-2944), no code; TransitLift exists at different positions
- **Fix:** Change kind to marker or implement

---

## 9. DESIGN DECISIONS REQUIRED

**D1. Should South Reach completion REQUIRE console acknowledgement + P-9 recovery?**
- A: Both required (design intent preserved)
- B: Console required, P-9 optional (weapon side-grade)
- C: Neither required (current behavior — both are flavor only)

**D2. Should Crèche console be mandatory for RETURN TO POST objective, or visible from wake?**
- A: Console unlocks objective (current)
- B: Objective visible from wake, console is first step

**D3. Should optional Chapel have real payoff?**
- A: Add small reward (`reward_cache` marker suggests intent)
- B: Stay visual-only, explicitly marked

---

## 10. DEAD / ORPHANED SEMANTICS

Entries passing repo-wide search with no live consumer:
`hidden_reliquary`, `lore_plaque`, `central_aisle_trigger`, `lift_mechanism`, `register_of_departures`, `south_wasteland_vista`, `return_to_post_beacon`, `road_anchor`, `reward_cache`, `attestation_dais`, `sigil_fragment`, `central_shaft`, `mosaic_center`, `relay_lamp_altar`, `thread_anchor_*`, `broken_west_bridge`, `damaged_plinth`, `brass_needles`, `route_tablets`, `fallen_shelving`, `housing_*`, `drum_*` (collision validation only), `coil_*` (collision validation only), `stele_*`

---

## 11. TEST COVERAGE GAPS

**Existing test (`awakening_first_return_progression_smoke.gd`) proves:**
- Console exists at correct position and advances `opening_console_acknowledged`
- Locker exists and grants P-9
- Lift transports both ways and refuses off-station
- Zone volumes update `current_zone_index` on teleport
- Camera reveals fire once
- South Reach trigger completes when Operator stands at `SOUTH_REACH_COMPLETION_CENTER`
- Encounter markers exist as disabled
- Reset doesn't rewire persistent state

**Does NOT prove:**
- Skip-path behavior (test teleports to each checkpoint, never tests skipping console/P-9)
- Completion gating (test reaches completion directly and asserts completed=true; does not verify gating)
- Objective text consistency after each transition
- Backtracking safety (Scenario F not tested)
- Optional Chapel payoff (correctly can't — payoff doesn't exist)
- Affordance learnability (no test checks prompts appear)

**Smallest test additions:**
```gd
# After normal completion:
assert(awakening.get("opening_console_acknowledged") == true)
assert(awakening.get("p9_recovered") == true)
# Skip-path: don't interact with console, reach completion:
assert(awakening.get("completed") == true) # Current behavior — design decision needed
```

---

## 12. DOCUMENTATION DRIFT

| File | Claim | Runtime truth |
|---|---|---|
| `design/04_architecture/AWAKENING_FIRST_RETURN.md` | Console locks opening state; objective becomes RETURN TO POST | True |
| `design/04_architecture/AWAKENING_FIRST_RETURN.md` | Sections 01-10 progressive authored dungeon | Partially false — completion is single coordinate trigger |
| `design/04_architecture/AWAKENING_FIRST_RETURN.md` | P-9 at (832,-1952) grants sidearm | True |
| `design/04_architecture/AWAKENING_FIRST_RETURN.md` | No combat, disabled encounter markers | True |

---

## 13. RECOMMENDED NEXT SLICE

**Gate South Reach completion behind console + P-9.**

1. Edit `awakening_first_return.gd:_on_south_reach_reached()` to require `opening_console_acknowledged` and `p9_recovered`
2. Update `_configure_hud()` to show hint when either is missing
3. Add skip-path assertions to `awakening_first_return_progression_smoke.gd`
4. Resolve DESIGN_DECISION (options in Section 9)

**Bounded scope:** One function edit, one HUD hint edit, one test edit. No art, no assets, no new systems.
