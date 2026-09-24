# CUSTODIAN — Faction Overview

> **Status:** Canonical design reference — seven-polity comparison and implementation guide
> **Doctrine authority:** `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`
> **Supersedes:** MAJOR_FACTION_PROFILES.md (pre-design). Conflicts resolved per FACTION_PROFILES_CORRECTIONS.md and ASH_BELL_AND_DESIGN_GUIDANCE.md.

---

## Design Principle

CUSTODIAN factions should not exist as simple "enemy types." Each faction is a different answer to the collapse of trustworthy civilization. Every faction should express:

- What they believe happened after the Severing
- What they think the old world owed them
- What they preserve, corrupt, destroy, or misread
- What spaces they occupy
- What they do before combat
- What evidence they leave behind
- How they change procedural worlds without needing explicit exposition

The player should rarely be told what a faction is. They should learn by seeing what enemies protect, what they ignore, what they steal, what they mark, what rooms they modify, what machines they maintain, what they destroy on sight, and what their bodies, tools, and rituals imply. **The best CUSTODIAN faction is one the player understands before the Hub ever names it.**

---

## Faction Comparison Table

| Polity family | Continuity answer | Failure Mode | Gameplay Pressure | Environmental Footprint |
|---------|------------------------|--------------|-------------------|------------------------|
| **Fieldworks Compact** | Maintenance and cautious expansion preserve continuity | Expansion hides maintenance debt | Reopen, repair, or reserve capacity | Workshops, field boards, repaired conduits |
| **Drawdown Councils** | Honest contraction preserves more life than collapse | Triage becomes destiny | Retain, evacuate, or retire services | Evacuation sectors, decommission marks, preserved corridors |
| **Cordon Service** | Evidence before passage limits reciprocal risk | Emergency authority becomes permanent suspicion | Verify, isolate, or breach | Layered cordons, route histories, decontamination stations |
| **Charter Authorities** | Durable rights make infrastructure accountable | Standing becomes ownership theater | Invoke, negotiate, or contest claims | Claim boards, access schedules, duty rosters |
| **Orraic Orders** | Duty may require interrupting the system | Sacrifice becomes doctrine | Rescue, shelter, or hold course | Waystations, refuge routes, field clinics |
| **Recovery Companies** | Mobile extraction preserves value before routes fail | Salvage strips living systems | Recover, protect, or liquidate | Lift frames, tagged machinery, modular camps |
| **Witness Assemblies** | Social testimony preserves personhood beyond machine proof | Recognition becomes patronage | Attest, deny, or reconcile identity | Testimony circles, household registers, memorial walls |
| **Legacy Interdiction Mesh** *(hazard layer)* | None; dead protocols continue | Correct execution without context | Disable, authenticate, reroute | Checkpoints, fields of fire, warning eras |

---

## Implementation Priority

For current runtime development, implement in this order:

1. **Faction room tag modifiers** — environmental props per faction
2. **Faction prop/decal pools** — what each faction leaves in rooms
3. **One idle/pre-combat behavior per faction** — what they do before noticing the player
4. **One gameplay pressure per faction** — how they affect the player's information, movement, or choices
5. **Five short inspect lines per faction** — scan text
6. **One procedural tableau per faction** — a signature room arrangement

Do not start with long lore logs. The player should learn factions by walking into rooms and noticing what has been done to them.

---

## Recommended World Generation Variables

Each generated world should roll:
- `resident_polity`
- `secondary_polity` (optional)
- `original_site_function`
- `collapse_mode`
- `surviving_truth`
- `false_interpretation`
- `signal_quality`
- `archive_risk`
- `material_condition`

Faction profiles then modify: prop pools, enemy behaviors, room tags, inspect text, objective type, ambient audio, lighting, map labels, and machine output corruption.

---

## Active Polity Profiles

See individual files in this directory for complete active profiles:

- `FIELDWORKS_COMPACT.md`
- `DRAWDOWN_COUNCILS.md`
- `CORDON_SERVICE.md`
- `CHARTER_AUTHORITIES.md`
- `ORRAIC_ORDERS.md`
- `RECOVERY_COMPANIES.md`
- `WITNESS_ASSEMBLIES.md`
- `LEGACY_INTERDICTION_MESH.md` — hazard layer, not polity

The prior six-roster files remain retained as historical/tradition references.

---

## Visual Design Templates

Artist-facing visual design briefs are preserved in the pre-design directory for reference:
- `pre-design/FACTION_PROFILE_THE_PENITENTS_OF_STATIC.md` — Superseded naming; use "Pale Bell Penitents" for design briefs
- `pre-design/FACTION_PROFILE_THE_INDEXERS.md` — Current and correct
- `pre-design/FACTION_PROFILE_THE_LEASEHOLDERS.md` — Current and correct
- `pre-design/FACTION_PROFILE_THE_CHOIR_OF_PROVENANCE.md` — Current and correct
- `pre-design/THE_BURIED_KINS_FACTION_PROFILE.md` — Current and correct
- `pre-design/FACTION_PROFILE_FERAL_DEFENSE_REMNANTS.md` — Current and correct
