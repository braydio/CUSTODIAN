# Codex Task Queue

Auto-generated from PRE_TASK.md. Do not edit manually — run `bash tools/codex_ingest.sh` to update.

---

## Ready

- [ ] **[high]** EMERGENCY: Remove unapproved Return Causeway Prologue from production route
  - ID: 20260725_1230_01
  - Added: 2026-07-25
  - **What happened:** Return Causeway is an agent-owned, in-progress 96×72 procedural level (`return_causeway_layout.gd`) that was merged into the production route without user sign-off. Its task packet is still marked `in_progress` with all gameplay acceptance criteria unchecked.
  - **Why it's broken:**
    - Collision: Wall sprites render at -32px visual offset but collision is on original unshifted tile, causing visible walls that don't block and invisible blockers
    - Elevation: Fake elevation system moves operator by `height * 24px` independently of visual architecture
    - The production route `vista_approach → return_causeway → front_gate` activates this unfinished level
  - **Unapproved content injected:** The agent-authored task invented a Buried Terminal, "Custodian identity imprint" sequence, identity-locked gatehouse, forced shore-path detour, Return Mooring checkpoint, and gate that requires imprint. Runtime implements `"IMPRINT CUSTODIAN IDENTITY"` setting `_gatehouse_unlocked = true`.
  - **Immediate action:** Remove Return Causeway from production route. Do NOT repair it.
  - **Subtasks:**
    1. Add reverse direct edge `keep_to_vista_direct` to `custodian/content/routes/sundered_keep/sundered_keep_route.json`
    2. Replace production profile `enabled_edge_ids` with: `["enter_vista", "vista_to_keep_direct", "vista_exfil", "keep_to_vista_direct", "keep_exfil"]`
    3. Ensure production profile does NOT enable: `vista_to_causeway`, `causeway_to_keep`, `causeway_to_vista`, `keep_to_causeway`, `enter_causeway_debug`, `causeway_exfil_debug`
    4. Quarantine Return Causeway behind `causeway_only` debug profile only
    5. Update Vista destination prompt from "CONTINUE TO RETURN CAUSEWAY" → "ENTER SUNDERED KEEP"
    6. Update route smoke tests to prove: production goes World → Vista → Front Gate; Return Causeway never activates under production
    7. Update docs: `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`, `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/CONTEXT.md`
    8. State clearly that Return Causeway is quarantined and must not be promoted without explicit user review
  - **Constraints:** Do NOT repair, redesign, polish, or expand Return Causeway. Preserve files only as isolated non-production experiment.
  - **Production route after fix:** World → Vista Approach → approved Front Gate
  - **Return Causeway after fix:** Exists only as `causeway_only` debug profile until deliberate user review

- [ ] **[medium]** Add a sound when the operator picks up scrap parts
  - ID: 20260725_1217_01
  - Added: 2026-07-25
  - Context: Audio

- [ ] **[low]** The low health warning could be a bit louder
  - ID: 20260725_1217_02
  - Added: 2026-07-25

- [ ] **[medium]** Enemies should stagger when hit with heavy attacks
  - ID: 20260725_1217_03
  - Added: 2026-07-25
  - Context: Combat

- [ ] **[high]** Add screen shake on critical hits
  - ID: 20260725_1217_04
  - Added: 2026-07-25

- [ ] **[medium]** Inventory needs a tooltip when hovering items
  - ID: 20260725_1217_05
  - Added: 2026-07-25
  - Context: UI

## In Progress

_None._

## Done

_None._
