# Operator Flashlight V1

## Status

Implemented as permanent Operator equipment under
`res://game/actors/operator/components/operator_flashlight.tscn`.

## Contract

The Operator always carries a flashlight. It starts off and toggles as one
deterministic on/off state through `flashlight_toggle` (keyboard physical L,
controller MISC1 / Xbox Share where Godot exposes it). It has no battery,
charge, durability, consumption, loot, upgrade, or inventory model.

The component consumes the Operator's existing world-space
`ControllableActor.aim_direction`; it never reads mouse or stick state. A
normalized nonzero direction becomes the retained facing, while zero aim keeps
the previous valid direction. Facing updates while the flashlight is off.

## Presentation

The flashlight uses two persistent native `PointLight2D` nodes registered in
`render_point_light`:

- A shadow-casting warm beam uses
  `light_cookie_beam_96x192.png`, color `#E8D7B2`, energy `1.15`, height
  `24 px`, and texture scale `2.75`. The cookie points down in source space;
  the pivot's fixed `-90°` base rotation makes `Vector2.RIGHT` point east. Its
  useful authored falloff reaches approximately `528 px`.
- A non-shadowed local glow uses `light_cookie_radial_soft_128.png`, the same
  warm color, energy `0.30`, and texture scale `1.75`, yielding approximately
  `112 px` of immediate-radius readability.

Major authored `LightOccluder2D` geometry remains shadow authority. The
flashlight does not add tile- or prop-level occluders.

Environmental darkness remains the responsibility of authored
`LightingZone2D` profiles. This component never changes ambient lighting or
automatically activates by zone.

## Deferred

- Enemy awareness or reaction to the flashlight.
- Darkness authoring for Undergate or other intended flashlight spaces.
- Audio, flicker, upgrades, and alternate flashlight equipment.

## Validation

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/operator_flashlight_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/controller_input_contract_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/lighting_system_smoke.gd
```
