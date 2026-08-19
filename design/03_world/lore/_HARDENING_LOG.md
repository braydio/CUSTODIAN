# Hardening Log

> **Status:** Canonical design documents created from pre-design sources
> **Date:** 2026-06-11

## Summary

4,410 lines across 10 pre-design files hardened into 1,664 lines across 9 canonical design files. All lore contradictions explicitly resolved per the established precedence hierarchy (ASH_BELL > CORRECTIONS > NEW_LORE_DROP > MAJOR PROFILES > visual templates).

## What Was Created

| Document | Lines | Purpose |
|----------|-------|---------|
| `03_world/lore/CORE_LORE.md` | 273 | Master lore canon — single source of truth |
| `03_world/factions/_FACTION_OVERVIEW.md` | 90 | Cross-faction reference and implementation guide |
| `03_world/factions/PALE_BELL_PENITENTS.md` | 244 | Corrected faction profile (most changed) |
| `03_world/factions/THE_INDEXERS.md` | 125 | Faction profile (verified correct) |
| `03_world/factions/THE_LEASEHOLDERS.md` | 125 | Faction profile (verified correct) |
| `03_world/factions/THE_CHOIR_OF_PROVENANCE.md` | 119 | Faction profile (verified correct) |
| `03_world/factions/THE_BURIED_KINS.md` | 121 | Faction profile (1 fix: Severance→Severing) |
| `03_world/factions/FERAL_DEFENSE_REMNANTS.md` | 124 | Faction profile (verified correct) |

## What Was Modified

| Document | Change |
|----------|--------|
| `03_world/locations/SUNDERN_KEEP_LORE.md` | "Penitents of Static" → "Pale Bell Penitents"; "Severance" → "Severing"; "Unarrival" → "Unnarrival"; +cross-reference note |

## Key Corrections Baked In

1. **Penitents naming:** Penitents of Static → Pale Bell Penitents (early) / Unarrived Penitents (late revelation). Static is now one ritual technology, not core identity.
2. **Terminology exposure:** Unnarrival gated behind `ash_bell_exposure >= 5`. Public term is "The Severing". Institutional procedural variant "Severance Event" is acceptable in context.
3. **Faction framework:** All factions defined by Severing/Unnarrival relationship FIRST. Custodian relationship is TRANSITIVE.
4. **Spelling:** "Unarrival" (single n) → "Unnarrival" (double n) per ASH_BELL doc authority.

## Pre-design Docs Status

Pre-design files in `pre-design/` remain on disk for reference but are superseded for canon decisions. The individual visual templates (FACTION_PROFILE_*) remain useful as artist-facing briefs. A `_HARDENING_COMPLETE.md` marker has been placed in `pre-design/` to document this.

## Post-Hardening Additions

| Document | Lines | Purpose |
|----------|-------|---------|
| `02_features/factions/FACTION_EXPRESSION_SYSTEM.md` | ~500 | Faction implementation spec — data model, taxonomy lock, gameplay boundaries, migration order, runtime ownership, Buried Kins relationship layer, Sundered Keep vertical slice. Created 2026-07-29 from Faction Continuity Audit findings. |

---

## 2026-08-18 — Reciprocal Continuity Reauthoring

Superseded the June 2026 provenance-root cosmology.

Previous lock:
- `Unnarrival` double-n
- Unnarrival as cosmic root wound
- Non-Recipient as hidden anti-arrival entity
- provenance as reality-level continuity substrate

New lock:
- `Unarrival` single-n
- Unarrival originates in Ash-Bell Station IX terminology
- Severing tied to reciprocal Lattice continuity hazard
- provenance is forensic / continuity-origin evidence
- Non-Recipient retired as confirmed entity
- Ash-Bell continuity remains physically real
- Null Warrant retained
- Reciprocal Continuity Doctrine is highest authority for this domain

See: `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`
