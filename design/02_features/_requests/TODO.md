# Feature Request Backlog — TODO

> Documents that were previously loose in `design/` root, moved here because they describe features that are **not yet implemented**. Once implemented, promote the doc out of `_requests/` into the appropriate feature folder and mark complete.

---

## Open Requests

### 1. ENEMY_FACTORY.md (2,168 lines)
**Procedural Enemy Generation Factory**
- Extracts animation frames from transparent spritesheets
- Groups frames into animation families
- Generates visual variants (tinting, scaling, overlays)
- Generates gameplay variants (stats, behavior)
- Deterministic spawning from seed
- **Status:** Explicitly labeled as "feature request" — not implemented

### 2. ENEMY_VARIANT_SYSTEM.md (1,157 lines)
**Procedural Enemy Variant Composition**
- Beast Pack (alpha-based) + Wolf (Aseprite JSON) asset pipelines
- Shared variant factory for deterministic enemy profiles
- Family → Tier → Affix composition
- DPS normalization per threat level
- **Status:** "Development Specification" — design phase, no runtime code

### 3. VARIANT_FACTORY.md (1,306 lines)
**Variant Factory — Deterministic Enemy Composer**
- Builds complete `EnemyVariantProfile` from seed + biome + threat + room context
- Data-only generation (no scene/sprites instantiation)
- Originally named `VARIANT_FACTORY.my` (typo, corrected)
- **Status:** Companion to ENEMY_FACTORY and ENEMY_VARIANT_SYSTEM — not implemented

---

## Implementation Dependencies

The three enemy procgen docs above are interdependent and should likely be implemented as one system:

1. `VARIANT_FACTORY.md` — Core composer engine (data profiles)
2. `ENEMY_VARIANT_SYSTEM.md` — Asset pipelines + affix composition layer
3. `ENEMY_FACTORY.md` — Full runtime factory consuming the above

---

## Related Existing Systems

These features would integrate with:
- `02_features/enemy_director/` — Enemy wave/spawn director
- `02_features/enemy_objective/` — Enemy objective system
