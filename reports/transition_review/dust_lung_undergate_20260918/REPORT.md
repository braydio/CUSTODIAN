# Dust Lung to Undergate production transition review

Scene: `res://scenes/awakening_first_return.tscn`

## Captures

1. `01_upper_dust_lung_flashlight_off.png` — Operator `(0, -3500)`, flashlight off.
2. `02_pre_threshold_flashlight_off.png` — Operator `(0, -3735)`, flashlight off.
3. `03_south_throat_flashlight_off.png` — Operator `(0, -3900)`, flashlight off.
4. `04_south_throat_flashlight_on.png` — Operator `(0, -3900)`, flashlight on.
5. `05_mechanism_nave_drum_flashlight_on.png` — Operator `(0, -4384)`, flashlight on toward the west drum.
6. `06_operator_beneath_foreground.png` — Operator `(0, -4720)`, flashlight on beneath the foreground mechanism.

`contact_sheet.png` contains the six captures in the order above.

## Objective verification

- Dust Lung underlay remains registered at `Vector2(0, -3200)`.
- Undergate underlay and foreground remain registered together at `Vector2(0, -4320)`; foreground remains at `z_index = 10`.
- No plate seam, scale discontinuity, or transition matte is visible in the capture sequence.
- No bright baked light is visible as originating inside the Undergate south throat.
- Dust Lung is visibly brighter than the Undergate threshold.
- Continuous southward profile audit changed directly from `awakening_dust_lung_failing_daylight.tres` at `y=-3500`, to `awakening_undergate_threshold.tres` at `y=-3708`, to `awakening_undergate_core.tres` at `y=-4060`; no baseline profile appeared between zones.
- Flashlight-on capture 04 materially increases local inspection visibility relative to flashlight-off capture 03 at the same position.
- The west drum/major geometry interrupts the flashlight beam in capture 05.
- The foreground mechanism renders over and occludes the Operator in capture 06.

## Objective defects

None found in the reviewed transition.

The existing `awakening_undergate_lighting_smoke.gd` passed. Godot import also completed; the import scan reported an unrelated pre-existing parse error in `res://game/actors/projectiles/missile.gd` (`_spawn_impact_at()` missing).
