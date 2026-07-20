# Compound Infrastructure Milestone 1 Implementation Plan

**Project:** CUSTODIAN
**Created:** 2026-07-20
**Status:** implemented — global save-manager integration pending
**Authority:** `design/02_features/infrastructure/COMPOUND_INFRASTRUCTURE_SYSTEM.md`

## Goal

Implement the Powered Fabricator slice without replacing the live sector-power system or the existing Basic Turret/Light Barricade placement bridge.

## Live Compatibility Decisions

- The authored `POWER` sector remains the first generator through the legacy `power_node` adapter.
- A prebuilt Field Fabricator is added as an `InfrastructureStructure` with a consumer and `FABRICATION` service.
- `power.gd` accepts explicit generator/consumer/storage component registration while retaining sector discovery.
- `total_power`/`max_power` remain compatibility aliases for stored reserve/capacity; new snapshots also expose explicit grid keys.
- `TurretPlacement` temporarily hosts `capacitor_bank_mk1` placement while the generic construction controller is extracted later.
- The placement commit is the V1 installation interaction: it creates the foundation and starts deterministic assembly.
- No global save manager exists. `InfrastructureRegistry.capture_state()` and `restore_state()` provide the versioned persistence boundary and are proven with a round-trip smoke.

## New Runtime Files

```text
custodian/autoload/infrastructure_registry.gd
custodian/game/infrastructure/definitions/structure_definition.gd
custodian/game/infrastructure/infrastructure_structure.gd
custodian/game/infrastructure/components/power_consumer_component.gd
custodian/game/infrastructure/components/power_generator_component.gd
custodian/game/infrastructure/components/power_storage_component.gd
custodian/game/infrastructure/components/infrastructure_service_component.gd
custodian/game/infrastructure/structures/field_fabricator_mk1.tscn
custodian/game/infrastructure/structures/capacitor_bank_mk1.tscn
custodian/content/infrastructure/definitions/fabrication/field_fabricator_mk1.tres
custodian/content/infrastructure/definitions/power/capacitor_bank_mk1.tres
```

## Transaction Order

```text
select capacitor Ready Build
→ validate current placement surface
→ instantiate scene off-tree
→ consume exactly one token
→ add foundation to world
→ begin construction
→ register structure identity
→ complete construction
→ enable storage component
→ grid recalculates capacity
→ terminal snapshot reflects capacity
```

If token consumption fails, the off-tree instance is freed. If add/initialization fails after token consumption, the token is refunded and the incomplete instance is removed.

## Power Migration

The fixed-step update computes:

```text
generation_rate = legacy generators + registered generators
available_rate  = generation_rate + bounded reserve discharge
allocated_rate  = deterministic priority allocation
net_rate        = generation_rate - allocated_rate
stored_energy   = clamp(stored_energy + net_rate * delta, 0, capacity)
```

Equal priorities sort by stable consumer ID. Storage components scale capacity and charge/discharge contributions by their owner integrity modifier.

## Validation

```text
power_grid_component_registration_smoke.gd
construction_placement_contract_smoke.gd
powered_fabricator_slice_smoke.gd
infrastructure_save_restore_smoke.gd
```

Existing power-rate, fabrication, terminal, turret placement, and Light Barricade smokes remain regression requirements.

## Completion Record

The runtime files, recipe, placement bridge, terminal snapshot, component registration, and four focused smokes listed above are live. Persistence is available as a versioned registry round trip; wiring that payload into a future project-wide save manager is explicitly outside this bounded milestone.
