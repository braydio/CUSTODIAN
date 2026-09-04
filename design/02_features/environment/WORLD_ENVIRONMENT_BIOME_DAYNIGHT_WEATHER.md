# World Environment V1 — Biomes, Day/Night, Deterministic Weather

**Status:** implementation
**Runtime:** `custodian/`

## Authority

Exactly three systems own this feature:

- `ProcGenTilemap` owns immutable per-cell ecological biome semantics and exports them in level data.
- `WorldEnvironmentDirector` owns the fixed-physics clock, seeded weather schedule, indoor exposure, and environment modifier publication.
- `WorldLightingDirector` remains the lighting compositor; authored and zone profiles are base authority and environment modifiers never replace them.

`WorldAtmosphere2D` remains the only fullscreen environmental pass. It renders weather and precipitation below UI. Existing shared shrub/tree foliage materials remain the only foliage wind materials.

## Locked V1 Contract

- Day length is 1440 real seconds: one real minute is one game hour.
- Biomes are `scrubland`, `woodland`, `wetland`, and `rocky_upland`.
- Climate profiles remain world profiles; roads, paving, interiors, platforms, parking, and authored surfaces remain region/surface semantics rather than biomes.
- Weather states are `clear`, `overcast`, `light_rain`, `heavy_rain`, `mist`, `dust_wind`, `snow`, and `ashfall`.
- Weather holds 90–240 seconds and transitions over 8–15 seconds.
- Weather affects only lighting, fog/grade, precipitation, and foliage wind. It has no gameplay modifiers.

## Dataflow and Determinism

Biome classification consumes accepted procgen floor cells, terrain/elevation output, accepted map seed, and profile moisture/exposure biases. It never changes at runtime and cannot modify walkability.

The environment seed combines `contract_seed`, accepted `map_seed`, and `world_profile.profile_seed`. Candidate evaluation never consumes environment RNG. Equal contract data plus equal fixed-physics elapsed time must yield equal weather.

Foliage precedence is:

`world/climate ceiling → biome ceiling → route/playability ceiling → contextual multiplier → deterministic placement roll`

Route policy always wins. Biome is orthogonal to world-ascent distance/style progression.

## Rendering

Lighting composition is authored/zone base × day influence × weather influence, with retained climate fog/cosmic baselines and temporary flash added afterward. Profile influence values can suppress environment and weather for interiors, events, and anomalies.

Procedural rain, snow, ash, and dust are rendered by the existing atmosphere shader in world space. UI is never graded. Indoor exposure transitions between 1.0 and 0.12 over 1.25 seconds while weather continues advancing.

## Scope Exclusions

No weather damage, movement/accuracy/perception penalties, temperature, wetness, accumulation, puddles, lightning, seasons, biome migration, biome-specific spawning/loot, new tilesheets, cosmology work, or faction work.

## Acceptance

Focused biome and environment smokes must prove deterministic fields/schedules, climate bias, rocky forcing, clock rate, indoor suppression, authored profile retention, and shared-material preservation. Existing procgen, foliage, lighting, atmosphere, and full procgen validation must remain green before this status becomes `complete`.
