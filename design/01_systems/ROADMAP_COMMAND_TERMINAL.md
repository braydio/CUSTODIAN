# CUSTODIAN Command Terminal — Development Roadmap

**Last Updated:** 2026-07-20
**Implementation Authority:** `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`
**Audit:** `design/02_features/terminal/TERMINAL_DESIGN_AUDIT.md`

This roadmap is retained for historical reference. Implementation and player-facing language follow the newer authority docs above. The checkbox list below was replaced with a page maturity matrix on 2026-07-20.

---

## Page Maturity Matrix

```
PAGE             STATUS                NOTES
─────────────────────────────────────────────────────────────
SHELL            complete-v1           Modal, nav rail, status chips, transcript, command input
OVERVIEW         functional-v1         Ranked sector diagnosis, stable incidents/recommendations, live Operator location
STATUS           functional-v1         Canonical fidelity-aware output using deterministic simulation time
SECTORS          functional-v1         Sector cards, damage overlays, minimap integration
POWER            readout-partial       Four globals + basic table — needs routing controls, presets, preview
DEFENSE          readout-scaffold      Turret count + coverage inference — needs asset list, LOS, targeting
FABRICATION      functional-v1         Most complete page — recipe browse, queue, build progress
SENSORS          readout-scaffold      Needs dedicated contact model with confidence, age, source sensor
INCIDENTS        transcript-scaffold   Incidents sourced from transcript — needs incident registry + lifecycle
ARCHIVE          placeholder           Hardcoded STATE NOMINAL — needs real archive state
RECON            placeholder           Hardcoded HYP-01/02/03 — needs real hypothesis system
CONTRACTS        active-contract-only  Shows active contract — needs proposal browser
HISTORY          transcript-mirror     Shares bounded transcript — needs append-only operational history
SETTINGS         placeholder           Static text — needs real controls
```

## Legacy Phase Status (Historical)

The checkboxes below are preserved as-is from the original roadmap. They reflect the state as of 2026-04-08 and do not represent current implementation status. Refer to the maturity matrix above for authoritative status.

### Phase 1: Core UI Layout — Status: mostly implemented
- Terminal scene: implemented in `custodian/game/ui/hud/ui.gd` + `custodian/scenes/game.tscn`
- Top bar: implemented
- Activity feed: implemented (transcript)
- Planet view: implemented (basic)
- Tactical map: implemented (minimap)
- Command bar: implemented

### Phase 2: Command System — Status: partially implemented
- Command parser: implemented
- Execution mode: buffered (per design authority)
- Autocomplete: implemented (needs dedup and registry extraction)

### Phase 3: Integration — Status: partially implemented
- Activity feed hookup: implemented (transcript)
- Planet/map transitions: not implemented
- Game state binding: partial

### Phase 4: Polish — Status: not started
- Performance optimization: not started
- Visual polish: not started
- Sound: not started

---

## Key Design Decisions (Resolved)

| Decision | Resolution | Authority |
|----------|-----------|-----------|
| Execution mode | Buffered (tick-queued) | Deterministic sim goals |
| Activity feed source | Transcript entries | Terminal spec |
| Planet/tactical data | Separate SubViewports | Current implementation |

---

## Dependencies

- `custodian/content/ui/terminal/` — art assets (sufficient for stages 1-4)
- Simulation layer command handlers
- Entity state system
- Power/Threat tracking systems
- Incident registry (P1)
- Operational history store (P1)

---

## Implementation Sequence (from audit)

1. Semantic integrity — snapshot, simulation clock, fidelity policy, canonical STATUS, Overview ranking
2. Command architecture — registry, schemas, router extraction, shared help/completion
3. Operational command pages — Power first, then Defense, Sensors, Incidents
4. Persistent records — incident registry and operational history
5. Meta systems — Archive, Recon, Contracts, Settings
6. Visual polish — transitions, globe markers, threat vectors, sounds, map previews

No new terminal art assets necessary for stages 1-4.
