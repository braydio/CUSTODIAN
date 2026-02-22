# ROADMAP — CUSTODIAN (Current)

## Completed Foundations

- Backend-authoritative terminal command loop and dual server endpoints.
- Deterministic world stepping with seeded replay support.
- Spatial assault approach system with tactical multi-tick resolution.
- Presence/authority split (command vs field mode).
- Policy, doctrine, and fabrication control layers.
- Comms fidelity-driven information degradation.

## Active Priorities

1. Balance and pacing pass
- Tune assault cadence, interception strength, and resource pressure in `core/config.py`.
- Validate long-run stability with deterministic seeds.

2. UX readability pass
- Continue concise operator-facing text cleanup and category help improvements.
- Expand terminal-side discoverability without adding local authority.

3. Snapshot/UI parity pass
- Ensure all high-signal state fields required by terminal side panels are exposed and stable.
- Keep UI projections strictly read-only.

4. Test expansion
- Add more deterministic integration tests for long WAIT sequences and assault/fabrication interplay.
- Add endpoint tests for replay cache/idempotency edge cases.

## Deferred / Future

- Hub/campaign progression beyond current world-state scaffolding.
- Additional scenario archetypes and campaign-level persistence systems.
- Presentation-layer experimentation beyond terminal shell (without changing simulation authority model).
