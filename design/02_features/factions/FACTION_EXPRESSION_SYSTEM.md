# Faction Expression System

> **Status:** canonical seven-polity runtime target; runtime cutover pending
> **Canon authority:** design/03_world/factions/_FACTION_OVERVIEW.md
> **Implementation queue:** design/02_features/factions/FACTION_IMPLEMENTATION_TRACKER.md
> **Last reconciled:** 2026-09-24

This document defines how the seven-polity canon should reach runtime without
pretending the current Godot faction prototype has already migrated. The
Legacy Interdiction Mesh is a HAZARD_LAYER, never an eighth polity.

## 1. Design Principle

Polities are institutional answers to keeping people and infrastructure alive
inside persistent Lattice Domains. They are not enemy teams. Their identity
must appear through environment, behavior, target selection, access rules,
social posture, and consequences before dialogue explains them.

The player should be able to infer who occupies a place from what has been
maintained, retired, sealed, claimed, rescued, stripped, witnessed, or left
under old automated control.

## 2. Current Runtime Compatibility Boundary

The live procgen runtime still exposes dominant_faction and currently feeds it
prototype values such as iconoclast, cult_mechanist, and scavenger. That is
implementation truth, not current setting canon.

Do not silently rename those fields or values in documentation as if the
runtime were already migrated. FI-001 and FI-002 in the implementation tracker
own the eventual cutover:

1. FI-001 introduces typed canonical identity data.
2. FI-002 replaces the overloaded world-profile faction slot with polity,
   tradition, hazard, and occupancy fields.
3. Compatibility aliases, if required, live only at explicit load/adaptation
   boundaries and receive an exit condition.

Until those slices land, documentation may describe the target schema while
clearly labeling dominant_faction as the live compatibility field.

## 3. Runtime Taxonomy Lock

Target world-profile identity:

    {
        "resident_polity": "fieldworks_compact",
        "secondary_polity": "",
        "local_traditions": [],
        "hazard_layers": ["legacy_interdiction_mesh"],
        "occupancy_posture": "working",
        "expression_profile": "fieldworks_repair_site"
    }

Classification:

| Field | Meaning |
|---|---|
| resident_polity | Primary living political/social institution in the region |
| secondary_polity | Optional second polity with lower presence or contested standing |
| local_traditions | Local schools, lineages, inherited labels, and cultural practices that do not define the polity roster |
| hazard_layers | Composable non-polity hazards such as the Legacy Interdiction Mesh |
| occupancy_posture | How occupants are behaving now: working, guarded, patrolled, quarantined, evacuating, contested, abandoned |
| expression_profile | Tableau/activity/decor profile used to express the local institution or tradition |

Canonical polity IDs:

- fieldworks_compact
- drawdown_councils
- cordon_service
- charter_authorities
- orraic_orders
- recovery_companies
- witness_assemblies

Canonical non-polity hazard:

- legacy_interdiction_mesh - HAZARD_LAYER

Historical names such as Pale Bell Penitents, Indexers, Leaseholders, Choir of
Provenance, Buried Kins, and Feral Defense Remnants may survive only through
their explicit mappings below. They are not new canonical polity IDs.

## 4. Canonical Gameplay Boundaries

| Polity / layer | Primary pressure | Typical player decision | Persistent or systemic consequence |
|---|---|---|---|
| Fieldworks Compact | Capacity, maintenance, cautious expansion | Reopen, repair, or reserve capacity | Territory, service load, exposure, maintenance debt |
| Drawdown Councils | Deliberate contraction and allocation | Retain, evacuate, or retire | Population movement, retired services, defensible core |
| Cordon Service | Evidence, verification, isolation | Verify, wait, isolate, or breach | Exposure risk, route status, trust, precedent |
| Charter Authorities | Standing, jurisdiction, accountable access | Invoke, negotiate, or contest a claim | Access precedent, legitimacy, future cooperation |
| Orraic Orders | Rescue, refuge, duty under pressure | Divert to rescue or hold course | Survivors, hazard severity, obligations |
| Recovery Companies | Extraction and salvage under closing windows | Recover, protect, or leave in place | Asset relocation, disabled site functions, resentment |
| Witness Assemblies | Attestation, personhood, social continuity | Accept machine proof, testimony, or reconciliation | Identity, access, civic trust, household continuity |
| Legacy Interdiction Mesh | Dead automated rules and spatial denial | Disable, authenticate, reroute, or preserve | Route access, security posture, power use |

These are pressures, not mandatory combat mechanics. A polity may oppose the
Custodian without attacking. Hostility is a posture and relationship outcome,
not a faction-definition default.

## 5. Preserved Legacy Gameplay Implications

The old six-roster work contained useful mechanics. Preserve them as local
traditions, tendencies, or hazard behaviors rather than discarding them:

| Legacy concept | Canonical home | Preserved implication |
|---|---|---|
| Pale Bell Penitents | Local Ash-Bell / Orraic tradition | Bounded, telegraphed temporal-perceptual distortion around specific listening sites. Never silently falsify authoritative health, inventory, damage, or save state. |
| Indexers | Local archival/classification tradition | Persistent semantic corruption with visible evidence of alteration: relabeled rooms, sorted salvage, changed terminal meaning. |
| Leaseholders | Charter Authority tendency/extreme | Claim and access denial, impoundment, inherited standing, and conflicts between machine-recognized authority and lived legitimacy. |
| Choir of Provenance | Provenance-focused Cordon lineage | Optional quarantine choices, evidence thresholds, isolation, and the moral cost of opening uncertain material. |
| Buried Kins | Witness-linked local society / tradition | Guarded rather than automatically hostile posture, relationship tracking, warnings, infrastructure sensitivity, and combat as a failure state. |
| Feral Defense Remnants | Legacy Interdiction Mesh | Patrol routes, turret arcs, checkpoints, recognition conflicts, obsolete credentials, and spatial denial without beliefs or diplomacy. |

The gameplay opportunity bank remains the generous source for concrete
scenarios. This document owns only the reusable runtime boundaries.

## 6. Roster Symmetry Reduction

Do not build seven parallel armies with bespoke basic melee, ranged, heavy,
fast, support, elite, leader, and special units. That would express politics
through model names while multiplying art and behavior cost.

Prefer composition:

    physical archetype: grunt / marine / drone / heavy
    polity doctrine:   fieldworks / drawdown / cordon / charter / orraic / recovery / witness
    local tradition:   optional historical or regional overlay
    hazard layer:      optional Legacy Interdiction Mesh
    posture:           working / guarded / patrol / quarantine / evacuation / contested

First production target per polity:

1. one unmistakable environmental tableau;
2. one pre-combat or noncombat activity;
3. one target-selection or interaction doctrine;
4. one signature gameplay pressure;
5. no more than the minimum faction-specific combat roles needed to prove the
   behavior.

## 7. Typed Identity Data

FI-001 should establish one definition/registry authority rather than parallel
sources of truth. The final field names may follow the cleanest live seam, but
the external contract must support:

- stable ID and display name;
- classification as POLITY or HAZARD_LAYER;
- ambient activity pool;
- target or interaction tag weights;
- environmental tag/modifier pool;
- inspect/dialogue profile references;
- pressure/profile identifiers;
- relationship/posture support where applicable.

The registry must load seven unique polity definitions plus one separately
typed Legacy Interdiction Mesh definition. Old prototype or legacy IDs must be
mapped or rejected intentionally, never silently treated as canonical.

## 8. Environmental Expression

Each polity should have at least one signature tableau that can be composed
with site function and local history:

| Polity / layer | Example tableau |
|---|---|
| Fieldworks Compact | Repair board, survey stakes, open conduit, shared tools, staged spares |
| Drawdown Councils | Evacuation sector, decommission marks, portable archive, preserved corridor |
| Cordon Service | Nested perimeter, clean/uncertain lanes, specimen cabinet, incomplete verification station |
| Charter Authorities | Public claim board, maintained lock, duty roster, access schedule, appeal marker |
| Orraic Orders | Refuge route, rescue cache, field clinic, missing-person list, service bell |
| Recovery Companies | Lift frame, tagged machinery, packing grid, dismantled shell, protected component |
| Witness Assemblies | Testimony circle, relationship map, duplicate-name register, annotated record |
| Legacy Interdiction Mesh | Checkpoint, overlapping warning eras, patrol wear, fields of fire, active cabinet |

Expression must remain deterministic when used by procgen. It may change
presentation and interaction affordances, but it must not become collision,
navigation, save, or simulation authority by accident.

## 9. Pre-Combat and Noncombat Behavior

Actors should do institutionally legible work before combat:

- Fieldworks inspect anchors, move supplies, and escort repair.
- Drawdown count evacuees, retire services, and guard departure plans.
- Cordon interview, sample, observe, and issue staged warnings.
- Charter inspect credentials, mediate access, and post claims.
- Orraic members render aid, search, shelter, and relay warnings.
- Recovery crews survey, isolate energy, dismantle, load, and negotiate.
- Witnesses interview, compare accounts, escort disputed people, and conduct hearings.
- Mesh systems scan, challenge, classify, warn, track, deny, and fire according to local protocol.

The behavior state machine should consume posture/activity data rather than
hardcoding one branch per polity. Detection may transition an actor into
warning, guarded, or hostile behavior depending on relationship and local
rules.

## 10. Target Selection and Interaction Doctrine

Use tag-driven scoring or another data-driven contract instead of polity-name
branches. Useful target/interaction tags include:

- archive_node
- map_terminal
- room_signage
- access_control
- door
- quarantine_seal
- artifact
- contradiction
- life_support
- water_source
- domestic_space
- signal_source
- receiver
- security_console
- salvage_target
- evacuee
- disputed_person
- intruder
- player

Examples:

- Fieldworks prioritizes damaged infrastructure and repairable service nodes.
- Drawdown prioritizes evacuation routes and services marked for retirement.
- Cordon prioritizes uncertain arrivals, samples, and boundary integrity.
- Charter prioritizes access control, claims, and accountable operation.
- Orraic actors prioritize endangered people and refuge routes.
- Recovery prioritizes recoverable machinery and extraction paths.
- Witness prioritizes people, testimony, records, and custody disputes.
- Mesh prioritizes whatever its inherited protocol identifies, often intruders
  or credential failures rather than a political enemy.

## 11. Relationships, Claims, Evidence, and Persistence

Relationship state should be polity-facing and reusable, not a Buried-Kins-only
special case. FI-005 owns the first focused neutral -> guarded -> hostile
transition and persistence contract.

Claims/access (FI-006), persistent Domain allocation (FI-007), and
attestation/evidence (FI-008) should remain separate authorities that query
polity identity rather than becoming fields inside a faction god object.

Persistent consequences belong to Domain/campaign state. A CampaignRegion may
be torn down while the represented Domain retains changed territory, services,
routes, relationships, claims, people, and hazards.

## 12. Legacy Interdiction Mesh Boundary

The Mesh has no citizens, diplomacy, ideology, relation score, or unified
command. It may overlay any resident polity, local tradition, or unoccupied
route. Local systems can share credentials or network behavior without becoming
a government.

Mesh integration must therefore compose with polity relationship rather than
replace it. FI-009 must prove a Mesh checkpoint can operate independently from
the resident polity's relationship state.

## 13. Implementation Order

The authoritative queue is FACTION_IMPLEMENTATION_TRACKER.md. Keep slices
small and independently provable:

1. FI-001 canonical identity definitions and registry.
2. FI-002 resident/secondary/tradition/hazard world-profile schema.
3. FI-003 deterministic environmental expression/tableaux.
4. FI-004 reusable occupancy posture.
5. FI-005 polity relationship state.
6. FI-006 jurisdiction/access claims.
7. FI-007 persistent Domain allocation and contraction/expansion.
8. FI-008 witness attestation/evidence.
9. FI-009 Mesh composition.

Do not infer completion from documentation. Each row requires its named focused
runtime evidence.

## 14. Validation and Non-Goals

Validation should prove the smallest changed contract first, then affected
regressions, then broader changed-file validation.

Non-goals for the canon migration itself:

- do not rewrite live prototype data merely to make names look current;
- do not create seven bespoke enemy rosters;
- do not make the Mesh a polity;
- do not make every Orraic Order a Pale Bell sect;
- do not make every Cordon unit Choir;
- do not make every Charter authority a Leaseholder;
- do not erase Buried-Kin, Indexer, Pale Bell, Choir, Leaseholder, or Feral
  Defense gameplay ideas that have a valid mapped home;
- do not make CampaignRegion teardown destroy the represented Domain.
