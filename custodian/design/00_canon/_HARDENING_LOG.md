# Hardening Log

> **Status:** Canonical design documents created from pre-design sources
> **Date:** 2026-06-11

## Summary

4,410 lines across 10 pre-design files hardened into 1,664 lines across 9 canonical design files. All lore contradictions explicitly resolved per the established precedence hierarchy (ASH_BELL > CORRECTIONS > NEW_LORE_DROP > MAJOR PROFILES > visual templates).

## What Was Created

| Document | Lines | Purpose |
|----------|-------|---------|
| `00_canon/CORE_LORE.md` | 273 | Master lore canon — single source of truth |
| `03_content/factions/_FACTION_OVERVIEW.md` | 90 | Cross-faction reference and implementation guide |
| `03_content/factions/PALE_BELL_PENITENTS.md` | 244 | Corrected faction profile (most changed) |
| `03_content/factions/THE_INDEXERS.md` | 125 | Faction profile (verified correct) |
| `03_content/factions/THE_LEASEHOLDERS.md` | 125 | Faction profile (verified correct) |
| `03_content/factions/THE_CHOIR_OF_PROVENANCE.md` | 119 | Faction profile (verified correct) |
| `03_content/factions/THE_BURIED_KINS.md` | 121 | Faction profile (1 fix: Severance→Severing) |
| `03_content/factions/FERAL_DEFENSE_REMNANTS.md` | 124 | Faction profile (verified correct) |

## What Was Modified

| Document | Change |
|----------|--------|
| `03_content/locations/SUNDERN_KEEP_LORE.md` | "Penitents of Static" → "Pale Bell Penitents"; "Severance" → "Severing"; "Unarrival" → "Unnarrival"; +cross-reference note |

## Key Corrections Baked In

1. **Penitents naming:** Penitents of Static → Pale Bell Penitents (early) / Unarrived Penitents (late revelation). Static is now one ritual technology, not core identity.
2. **Terminology exposure:** Unnarrival gated behind `ash_bell_exposure >= 5`. Public term is "The Severing". Institutional procedural variant "Severance Event" is acceptable in context.
3. **Faction framework:** All factions defined by Severing/Unnarrival relationship FIRST. Custodian relationship is TRANSITIVE.
4. **Spelling:** "Unarrival" (single n) → "Unnarrival" (double n) per ASH_BELL doc authority.

## Pre-design Docs Status

Pre-design files in `pre-design/` remain on disk for reference but are superseded for canon decisions. The individual visual templates (FACTION_PROFILE_*) remain useful as artist-facing briefs. A `_HARDENING_COMPLETE.md` marker has been placed in `pre-design/` to document this.
