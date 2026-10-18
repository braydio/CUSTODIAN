# CUSTODIAN Vehicle Integration System V1

**Status:** active architecture authority  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b  
**Reviewed main:** `3067be7817c1713f989a92753a7d199e913b82bc`

## Goal

Make a new CUSTODIAN vehicle primarily a data + source-art integration job, not a new animation controller/importer/runtime-wiring project.

```text
approved source art
 -> immutable handoff/source_work
 -> resolved vehicle visual kit
 -> deterministic derivation/normalization
 -> Asset Pipeline V2
 -> generated SpriteFrames/presentation resource
 -> reusable VehiclePresentationRig
 -> registry scene binding
 -> focused integration validation
```

This extends the existing registry and Asset V2. It does not create a second gameplay state machine or asset pipeline.

## Ownership

- `VehicleRegistry` / `VehicleDefinition`: semantic identity and resolved profile references.
- `PilotableVehicle`: movement, health, pilot ownership, disable/destruction, wreck/restoration and entry.
- `VehicleRestorationInteraction`: held recovery mechanics.
- Asset Pipeline V2: production asset publication.
- Vehicle Integration System: presentation description, deterministic art derivation, generated presentation resources, reusable composition and orchestration only.

## Author less, reuse more

Four visual classes:

1. **Authored body:** `drive_01`; silhouette-changing `disabled_01`; `destroy_01`; `restore_01` when real reconstruction art is needed; unique R3/R4/Relic behavior.
2. **Derived body:** `parked_01` from a neutral drive frame; `wreck_01` from the settled destroy endpoint.
3. **Procedural:** engine idle/start, brake, ordinary impact, light/exhaust/heat/dust motion that does not permanently change chassis geometry.
4. **Shared:** fleet recovery FX, post-destroy smoke, common impact/dust and service/component visual vocabulary.

For a normal five-authored-direction vehicle this reduces a naive ten-state/fifty-directional-sheet body workload to roughly four authored body families, about a 60 percent baseline reduction before same-chassis reuse. A sibling chassis variant may need zero new body animation.

## Vehicle visual kit V2

`custodian/content/vehicles/vehicle_visual_kits.json` remains the vehicle-facing authority and evolves to schema v2. It must support:

- Asset V2 body family ID
- direction policy
- optional inherited base kit
- authored semantic body-state map
- derived-state rules
- procedural preset IDs
- shared FX family/fitting policy
- normalized semantic anchors
- optional skin ID
- attachment IDs

Same-chassis variants inherit the base kit and override only what changes. Inheritance is deterministic, cycle-safe and never changes gameplay data.

Recommended semantic shape:

```json
{
  "asset_family": "custodian_field_scout_buggy_mk1",
  "direction_policy": "8dir",
  "inherits": "",
  "body_states": {
    "drive": "drive_01",
    "disabled": "disabled_01",
    "destroy": "destroy_01",
    "restore": "restore_01"
  },
  "derived_states": {
    "parked": {"from": "drive_01", "frame": 0},
    "wreck": {"from": "destroy_01", "frame": "last"}
  },
  "procedural_states": {
    "engine_idle": "vehicle_engine_idle_light",
    "engine_start": "vehicle_engine_start_light",
    "brake": "vehicle_brake_light",
    "impact": "vehicle_impact_light"
  },
  "shared_fx": {"recovery": "vehicle_recovery_fx_common"},
  "anchors": {
    "body_root": [0.5, 0.82],
    "fx_center": [0.5, 0.52],
    "service_socket": [0.61, 0.60],
    "power_source": [0.34, 0.62],
    "power_bus": [0.50, 0.58],
    "powertrain": [0.67, 0.63]
  }
}
```

## Family registration

All body states in one family share one registration contract. Do not independently fit each state. Record reference state/direction, frame size, vehicle root, ground-contact line, stable body envelope, global scale and optional semantic source markers.

For complex destroy/restore sources, prefer source metadata markers such as `__VEHICLE_ROOT`, `__GROUND_CONTACT`, and `__SERVICE_SOCKET` so transient debris cannot distort body bounds.

The Field Scout remains 156x156 RGBA per runtime body frame. Do not revive the obsolete 256px body planning canvas.

## Shared FX fitting

Canonical fitting policies: `CENTER`, `BOUNDS`, `ANCHOR`, `PATH`.

| FX | Fit | Data |
|---|---|---|
| `scan_sweep_01` | BOUNDS | body/presentation bounds |
| `fault_ping_01` | ANCHOR | failed subsystem/service socket |
| `install_sparks_01` | ANCHOR | service socket |
| `power_route_01` | PATH | source -> bus -> target |
| `bootstrap_01` | CENTER | fx center |
| `restore_success_01` | BOUNDS | presentation bounds |

## Reusable presentation rig

```text
VehiclePresentationRig
  Body
  PersistentOverlays
  AttachmentRoot
  LightRoot
  TransientFxRoot
  RecoveryFxPresenter
```

Recommended code:

```text
custodian/game/vehicles/presentation/
  vehicle_presentation_controller.gd
  vehicle_presentation_rig.tscn
  vehicle_body_presenter.gd
  vehicle_attachment_presenter.gd
```

The V7 recovery presenter is hosted/delegated by this rig after it lands. Never create a second recovery presenter.

`PilotableVehicle` provides semantic intent only:

```gdscript
presentation.update_motion(velocity, facing_direction, brake)
presentation.set_lifecycle(&"wreckage")
presentation.present_event(&"impact", context)
```

After migration it does not choose runtime PNGs, atlas frames or canonical Asset V2 body state IDs.

Direction resolution is centralized:

```text
exact authored state+direction
 -> approved mirror
 -> declared derived state
 -> declared procedural state
 -> explicit compatibility fallback
 -> structured fail-soft missing-presentation result
```

No filename guessing.

## Costumes and attachments

Build-time skins handle non-silhouette changes: faction paint, stripes/numbers, grime/weathering masks, decals and restrained color variants.

Runtime attachments handle independently changing silhouette: scanner mast, cargo/service module, relay dish, light bar, turret/weapon and utility fittings.

Attachments follow semantic anchors and body direction/clock. A detachable module must not require a duplicate chassis animation set.

## Deterministic art derivation

Extend `custodian/tools/assets/sprite_import/shared_transform.py`; do not add a vehicle-only normalizer.

Add `explicit_regions` for irregular source sheets. Ordered source rectangles are included in the deterministic plan digest, then the existing shared scale/anchor/alpha renderer normalizes them.

Derived outputs record source SHA(s), regions/order, family registration, derivation rule, transform plan SHA and output SHA. Parked/wreck derivation and skin composition feed normal Asset V2 inbox/publication. Runtime never reads source_work.

## Generated projections

```text
custodian/content/vehicles/generated/<visual_kit_id>_presentation.tres
custodian/content/metadata/vehicles/generated/<vehicle_id>.integration.json
```

The receipt records vehicle/kit IDs, inheritance chain, source handoff/family SHAs, normalization/derivation plans, output hashes, direction map, anchors/fitting, scene consumer and validation identities.

## Vehicle Integrator CLI

Canonical orchestrator:

```text
custodian/tools/vehicles/vehicle_integrator.py
```

Commands:

```text
inspect plan stage derive ingest build wire validate status integrate
```

Planning is read-only by default. Mutation uses explicit apply/replace semantics.

The integrator delegates handoff verification to `implementation_handoff.py`, transforms to shared sprite-import, publication to Asset V2/`asset.py`, runtime projection to the vehicle presentation builder and validation to focused vehicle validators. It does not reimplement them.

`plan` reports vehicle/kit/inheritance, source coverage, authored/mirrored/derived/procedural/shared states, skins/attachments, exact outputs/consumers, missing requirements and validation before mutation.

## Migration completion

Current compatibility state is temporary:
- visual-kit schema v1 is only SpriteFrames/default/move
- `PilotableVehicle` directly selects body animation identities
- Field Scout scene still references hover compatibility frames
- `update_vehicle_runtime_resources.gd` is hover-specific

Migration is complete only when the Scout is generated/wired through the integrator and the hover-specific builder has zero production consumers and is removed.

## Implementation DAG

| Slice | Workstream | Purpose | Depends on |
|---|---|---|---|
| VI1 | `vehicle-presentation-contract-v1` | visual-kit V2, inheritance, resolved states/anchors/fitting | reviewed V7 |
| VI2 | `vehicle-presentation-runtime-v1` | reusable rig/controller and PilotableVehicle extraction | VI1 review |
| VI3 | `vehicle-art-derivation-v1` | explicit-region/common-registration/derived-state/skin tooling | VI1 review |
| VI4 | `vehicle-integrator-v1` | orchestration, generated resources/receipts, Scout migration + sibling reuse proof | VI2 + VI3 reviews |

VI2 and VI3 may run in parallel.

## Final acceptance

The system is proven when the Scout uses the reusable rig; canonical Scout art is Asset V2-owned; PilotableVehicle no longer owns body animation IDs; parked/wreck derivation is automatic; shared recovery FX fit by semantic anchors/policies; a sibling fixture reuses Scout body art without duplicate PNGs; integrator plan/build/check is deterministic; hover-specific generation has no production consumer; and VI1-VI4 paired reviews pass.
