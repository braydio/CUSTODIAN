## 2026-03-02

- Locked Assault-Resource-Link Phase C salvage-coupling design from `CLARIFY.md` into `design/archive/historical/ASSAULT-RESOURCE-LINK.md` with deterministic formula, bounds, and edge-case handling.
- Implemented Phase C in `game/simulations/world_state/core/assaults.py` and `core/assault_instance.py` using assault-scoped salvage accounting (intercept ammo, tactical ammo, transit fortification wear, intercepted units, total units).
- Replaced fixed penetration salvage with bounded formula-based salvage resolution and added concise after-action salvage breakdown lines in assault impact output.
- Added/updated assault tests for formula behavior, clamp envelopes, zero-unit edge handling, and after-action summary surfacing in `test_assault_misc_design.py`.
- Implemented ARRN expansion in `core/relays.py` with deterministic relay stability decay, state thresholds (`STABLE/WEAK/DORMANT`), dormancy pressure computation, bounded knowledge drift, and tiered relay unlock benefits (`RELAY_RECOVERY` 1-7).
- Added ARRN knowledge/status surfaces: `STATUS KNOWLEDGE`, updated status/help contract strings, and relay sync reporting for weak-link packet corruption.
- Wired ARRN unlock effects into simulation systems: remote repair discount at tier 2, warning lead-time bonus at tier 3, Archive Plating fabrication gate at tier 4, logistics penalty reduction at tier 5, and status-fidelity flooring at tiers 1/6.
- Added ARRN regression coverage in `test_arrn_progression.py` and expanded status/contract snapshot assertions.

## 2026-02-27

- Added in-terminal tutorial command surface with topic drilldowns and slash-prefixed command support for UI parity.
- Expanded tutorial content with tagged message formatting, examples, and UI-focused structure.
- Added a quickstart tutorial flow that stages commands through the first assault and returns control to the operator.
