# Faction Implementation Tracker

> **Status:** Runtime-shaped queue only
> **Canon authority:** `design/03_world/factions/_FACTION_OVERVIEW.md`
> **Idea source:** `design/03_world/factions/FACTION_GAMEPLAY_OPPORTUNITIES.md`

Documentation does not satisfy a row. `IMPLEMENTED` requires the focused
runtime validation named by the row. Existing old-roster faction code is
migration input, not evidence that the new mechanic exists.

| ID | Mechanic | Owning subsystem | Dependencies | Smallest playable slice | Focused validation | Status |
|---|---|---|---|---|---|---|
| FI-001 | Canonical faction identity data | `FactionDefinition` / registry authority to be selected | Canon lock | Load and query seven polity definitions plus one separately typed Mesh hazard definition | Definition/registry smoke proving IDs, classification, uniqueness, and lookup | PLANNED |
| FI-002 | Resident / secondary / tradition / hazard world-profile schema | World profile authority | FI-001 | One generated region exposes a resident polity, optional secondary polity, local traditions, hazard layers, and occupancy posture without treating Mesh as polity | Procgen/world-profile schema smoke | PLANNED |
| FI-003 | Environmental expression and tableaux | Procgen faction-expression authority | FI-001, FI-002 | One reusable environmental tableau for each polity and one Mesh overlay, without bespoke combat rosters | Deterministic site/tableau smoke across fixed seeds | PLANNED |
| FI-004 | Occupancy posture | Actor/faction behavior authority | FI-001, FI-002 | One shared actor archetype expresses guarded, patrolled, quarantined, working, evacuating, or contested posture before combat | Focused posture/behavior smoke | PLANNED |
| FI-005 | Relationship state | Focused polity-relationship authority | FI-001 | One polity moves `neutral -> guarded -> hostile` through explicit events and persists correctly | Dedicated relationship transition/persistence smoke | PLANNED |
| FI-006 | Jurisdiction and access claims | Future focused claims/access authority | FI-005, interaction and credential authorities | One Charter door dispute supports Custodian override and negotiated local access | Focused access-claim resolution smoke | BACKLOG |
| FI-007 | Persistent Domain allocation, expansion, and contraction decisions | Campaign/Domain state authority | Persistent Domain state, FI-005 | One Fieldworks/Drawdown decision changes retained territory or service load across region teardown/reload | Campaign persistence smoke proving Domain survives CampaignRegion teardown | BACKLOG |
| FI-008 | Witness attestation and evidence | Future focused identity/evidence authority | Identity/evidence model, FI-005 | One disputed-person event compares machine provenance with social testimony | Focused evidence/attestation outcome smoke | BACKLOG |
| FI-009 | Legacy Interdiction Mesh integration | Hazard-layer and encounter authority | FI-001, FI-002 | One Mesh checkpoint overlays any resident polity and resolves rules independently from polity relationship | Hazard-layer composition smoke proving Mesh is not a polity | PLANNED |

## Next Agent Slice

**Goal:** implement FI-001 only after auditing live faction IDs and data owners.

**Likely files:** the existing runtime faction registry/data files discovered by
graph and source search, plus one focused smoke under
`custodian/tools/validation/`.

**Constraints:** preserve old IDs through an explicit compatibility plan; keep
polity, tradition, and hazard classifications distinct; do not introduce roster
symmetry or faction-specific actor classes.

**Acceptance:** seven unique polity IDs load; the Mesh loads only as
`HAZARD_LAYER`; old IDs are mapped or rejected intentionally; no gameplay row
beyond FI-001 is implied complete.
