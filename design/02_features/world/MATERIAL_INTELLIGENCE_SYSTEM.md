# Material Intelligence System

Status: review  
Feature type: world simulation / game feel / telemetry  
Codex source: `design/90_codex/world/material_intelligence_system.md`  
Runtime autoload: `custodian/game/systems/world/material_intelligence.gd`

## Summary

Material Intelligence provides a lightweight runtime query layer for identifying
the probable material at a world position. V1 is observability-first: it
supports explicit cell overrides, typed material profiles, material-contact
reporting, a current-player material gauge, heatmap tags, and Developer
Observatory session reporting.

This first slice does not infer materials from every tile automatically. Untagged
positions safely resolve to `unknown`. The profile response fields establish a
future contract for footsteps, impact effects, and stealth noise without
changing those systems in v1.

## Non-goals

- no new art
- no new audio
- no combat balance changes
- no movement or stealth tuning changes
- no AI behavior changes
- no procedural-generation output changes
- no player-facing UI
- no automatic tile or prop classification in v1

## Material IDs

- `unknown`
- `stone_dry`
- `stone_wet`
- `metal_rusted`
- `metal_powered`
- `ash`
- `soil`
- `grass`
- `memory_glass`
- `ruin_concrete`
- `void_growth`
- `wood_old`
- `shallow_water`

These identifiers are canonical for the v1 runtime. Unknown or unsupported IDs
degrade to the `unknown` profile.

## Runtime API

- `get_material_id_at(world_position) -> StringName`
- `get_material_at(world_position) -> MaterialProfile`
- `set_material_at(world_position, material_id)`
- `set_material_cell(cell, material_id)`
- `report_contact(world_position, contact_kind, data)`
- `get_summary()`
- `clear()`

The default lookup grid is 64 px. Explicit overrides are presentation and
telemetry metadata only; they do not create collision, alter navigation, or
change the generated world.

## Contact Types

The public contact vocabulary is:

- `footstep`
- `bullet_impact`
- `melee_impact`
- `body_impact`
- `dodge_slide`
- `field_patch_use`
- `enemy_death`

V1 runtime integrations report actual projectile impacts, muzzle-blocked shots,
confirmed player melee impacts, and enemy deaths. Footsteps are deliberately not
logged per frame; Developer Observatory samples the current material beneath the
player as a gauge. Other contact types are reserved for later authoritative
callers.

Every contact produces:

- one structured `material_contact` Observatory event;
- cumulative counts by contact kind and material in the exported Material
  Intelligence summary;
- a low-weight `material_<contact_kind>` SectorHeatmap sample.

Material telemetry never feeds back into damage, movement, AI, stealth,
collision, procedural generation, or world state.

## Profile Contract

`MaterialProfile` exposes:

- material ID and display name;
- footstep noise and stealth-visibility multipliers;
- bullet and melee impact response IDs;
- footstep sound-family ID;
- descriptive tags and notes.

The multipliers and response IDs are data contracts only in v1. They do not
change gameplay or spawn new effects.

## Observatory Contract

Developer Observatory exports a `material_intelligence` summary containing
override-cell counts and cumulative contact counts. Runtime gauges include
`player_material` and the profile's prospective footstep-noise multiplier. The
session analyzer prints current material state plus retained contact breakdowns
by material and kind.

Cumulative summary counts remain useful when the bounded Observatory event ring
wraps.

## Acceptance

- `MaterialIntelligence` is autoloaded.
- Unknown positions safely return the typed `unknown` profile.
- Explicit material cells resolve to their canonical profile.
- Actual impact/death contacts log through Developer Observatory.
- Material contacts contribute low-weight SectorHeatmap tags.
- Observatory export includes `material_intelligence`.
- The analyzer prints a `MATERIAL INTELLIGENCE` section.
- No gameplay behavior changes.

## Validation

```bash
python -m py_compile \
  custodian/tools/analysis/analyze_dev_observatory_session.py
python tools/validate_design_codex.py
cd custodian
godot --headless --path . \
  --script res://tools/validation/material_intelligence_smoke.gd
godot --headless --path . \
  --script res://tools/validation/dev_observatory_smoke.gd
godot --headless --path . \
  --script res://tools/validation/sector_heatmap_smoke.gd
```

Manual validation uses a short combat session, F10 export, and the analyzer.
Confirm actual impacts create material contacts, current player material is
visible, and combat outcomes remain unchanged.
