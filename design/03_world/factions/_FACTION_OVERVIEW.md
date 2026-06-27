# CUSTODIAN — Faction Overview

> **Status:** Canonical design reference — cross-faction comparison and implementation guide
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

| Faction | Severing Interpretation | Failure Mode | Gameplay Pressure | Environmental Footprint |
|---------|------------------------|--------------|-------------------|------------------------|
| **Pale Bell Penitents** | Cosmic disclosure — arrival was never guaranteed | Sacred ambiguity | Temporal-perceptual distortion | Listening shrines, ash circles, dead speakers, sealed-door altars |
| **Indexers** | Classification catastrophe — universe became unfiled | False certainty | Corrupted information, mislabeled knowledge | Relabeled rooms, sorted salvage, tagged corpses, altered terminals |
| **Leaseholders** | Access-chain breach — rightful claims were broken | Dead authority | Route/system denial, locked access | Claim seals, locked doors, impounded goods, legal barricades |
| **Choir of Provenance** | Provenance contamination — context detached from things | Purity without mercy | Sealed choices, moral friction | Quarantine geometry, sealed artifacts, preserved evidence, sterile zones |
| **Buried Kins** | Abandonment — help never came | Survival identity as total truth | Defensive habitation, moral hesitation | Repaired homes, ration shelves, domestic life inside dead infrastructure |
| **Feral Defense Remnants** | None — protocol continued without command | Obsolete procedure | Spatial denial, old automated violence | Patrol routes, warning lights, sealed checkpoints, active turrets |

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
- `dominant_faction`
- `secondary_faction` (optional)
- `original_site_function`
- `collapse_mode`
- `surviving_truth`
- `false_interpretation`
- `signal_quality`
- `archive_risk`
- `material_condition`

Faction profiles then modify: prop pools, enemy behaviors, room tags, inspect text, objective type, ambient audio, lighting, map labels, and machine output corruption.

---

## Faction Profiles

See individual files in this directory for complete faction profiles:

- `PALE_BELL_PENITENTS.md` — Signal ascetics who worship the failure of arrival
- `THE_INDEXERS.md` — Classification invaders who overwrite meaning with taxonomy
- `THE_LEASEHOLDERS.md` — Armed legal continuity from a dead interstellar bureaucracy
- `THE_CHOIR_OF_PROVENANCE.md` — Ancient verification authority narrowed into severity
- `THE_BURIED_KINS.md` — Sealed shelter survivors who kept the lights on
- `FERAL_DEFENSE_REMNANTS.md` — Broken security enforcing rules no one remembers

---

## Visual Design Templates

Artist-facing visual design briefs are preserved in the pre-design directory for reference:
- `pre-design/FACTION_PROFILE_THE_PENITENTS_OF_STATIC.md` — Superseded naming; use "Pale Bell Penitents" for design briefs
- `pre-design/FACTION_PROFILE_THE_INDEXERS.md` — Current and correct
- `pre-design/FACTION_PROFILE_THE_LEASEHOLDERS.md` — Current and correct
- `pre-design/FACTION_PROFILE_THE_CHOIR_OF_PROVENANCE.md` — Current and correct
- `pre-design/THE_BURIED_KINS_FACTION_PROFILE.md` — Current and correct
- `pre-design/FACTION_PROFILE_FERAL_DEFENSE_REMNANTS.md` — Current and correct
