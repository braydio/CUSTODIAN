# Ritualant Expanded Arena Asset Family

Status: implemented; automated validation green; mapper art approval pending.

## Outcome

The Ritualant Underground now consumes the expanded `2594x1737` arena plate,
revised chapel connector apron and foreground forelip, lower-quarter seal, and
shared White Thread decal/warning/activation presentation through Asset
Pipeline V2. Gameplay geometry, hazard collision, tension, and encounter state
remain separate runtime authorities.

## Source handling

- The incoming arena was a padded `3000x2000` master whose non-transparent
  bounds were exactly `2594x1737`. The runtime candidate was cropped to those
  transparent bounds without resizing or resampling.
- The padded master remains under
  `asset_drop/source_work/ritualant_scene/`.
- VFX review grids and the supplied ZIP moved to
  `source_work/ritualant_scene/hazard_vfx/`; only canonical horizontal strips
  entered the effect-family inbox.
- The additional left/right chapel expansion underlays moved to
  `source_work/ritualant_scene/chapel_expansions/`. They remain source material
  because this slice supplied no runtime state/registration contract for them.
- Asset Pipeline ingest records are
  `job_20260831T055558Z_85f32153` and
  `job_20260831T055617Z_2342599f`.

## Runtime ownership

- `ritualant_underground_environment` owns 37 static environment states.
- `ritualant_underground_hazard_fx` owns the eight-frame warning and ten-frame
  activation strips.
- `EncounterHazardTelegraph2D` is presentation-only and observes the existing
  White Thread state contract.
- The lower-quarter seal fades for 1.35 seconds after encounter completion;
  the real northern traversal boundary remains independent.
- Initial native-scale arena and seal registration is `(0,-1120)` and
  `(0,-1600)` respectively.

## Validation

Passed:

```text
ritualant_underground_environment_assets_smoke.gd
ritualant_hazard_telegraph_smoke.gd
```

The focused coverage checks exact files/dimensions, RGBA contract, native arena
scale, SpriteFrames regions and looping, presentation state transitions,
one-shot activation behavior, unchanged mechanical hazard dimensions, and the
completion seal fade.

## Human mapper follow-up

Open `res://scenes/debug/forlorn_ritualant_underground_mapper.tscn` and approve
the south connector seam, encounter center, northern teaser throat, forelip,
seal, and hazard alignment. The old site `Floor` and `PerimeterRubble` remain
visible until that review proves the expanded plate can replace them without
double-rendered cliff faces. This is deliberately not inferred from numeric
dimensions alone.
