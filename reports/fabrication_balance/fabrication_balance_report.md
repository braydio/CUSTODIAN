# Fabrication Balance Report

Scenario: `default_fabrication_run`
Duration: `30` minutes
Total runs: `900`
Proposal JSON: `reports/fabrication_balance/proposed_changes.json`

## Flags

- Never affordable: archive_sensor_pylon
- Always optimal: barricade_light
- Never chosen: archive_sensor_pylon
- Lore violations: 0

## Recipe Outcomes

| Recipe | Category | Affordable rate | Chosen rate | Avg crafted/run |
|---|---:|---:|---:|---:|
| archive_sensor_pylon | archive | 0.00% | 0.00% | 0.00 |
| barricade_light | structure | 83.56% | 83.56% | 1.03 |
| fabricator_pattern_decode_01 | archive | 61.78% | 61.67% | 0.81 |
| field_sealant_patch | support | 54.67% | 54.67% | 0.60 |
| power_bank_patch | power | 15.11% | 14.11% | 0.14 |
| sensor_pylon_basic | sensor | 43.89% | 43.00% | 0.46 |
| turret_basic | defense | 28.11% | 26.44% | 0.26 |

## Build And Drop Profile Matrix

| Build | Drop profile | Runs | Top crafted | Top bottlenecks |
|---|---|---:|---|---|
| defense_first | baseline | 100 | barricade_light:108, fabricator_pattern_decode_01:89, field_sealant_patch:49, turret_basic:35 | structural_alloy:5230, capacitor_dust:2081, blackwood:1992, memory_glass_fragment:1986 |
| defense_first | generous | 100 | barricade_light:153, fabricator_pattern_decode_01:80, field_sealant_patch:75, sensor_pylon_basic:62 | structural_alloy:4833, capacitor_dust:2091, memory_glass_fragment:1975, blackwood:1947 |
| defense_first | scarce | 100 | fabricator_pattern_decode_01:73, barricade_light:52, field_sealant_patch:45, sensor_pylon_basic:34 | structural_alloy:5217, capacitor_dust:2238, blackwood:2048, memory_glass_fragment:2012 |
| fabrication_first | baseline | 100 | barricade_light:108, fabricator_pattern_decode_01:83, field_sealant_patch:51, sensor_pylon_basic:47 | structural_alloy:5165, capacitor_dust:2344, memory_glass_fragment:1958, blackwood:1890 |
| fabrication_first | generous | 100 | barricade_light:147, field_sealant_patch:86, fabricator_pattern_decode_01:86, sensor_pylon_basic:61 | structural_alloy:4960, capacitor_dust:2235, memory_glass_fragment:1890, blackwood:1795 |
| fabrication_first | scarce | 100 | fabricator_pattern_decode_01:88, barricade_light:51, field_sealant_patch:46, sensor_pylon_basic:43 | structural_alloy:5449, capacitor_dust:2182, blackwood:2001, memory_glass_fragment:1981 |
| repair_support | baseline | 100 | barricade_light:105, fabricator_pattern_decode_01:72, field_sealant_patch:50, sensor_pylon_basic:38 | structural_alloy:5149, capacitor_dust:2156, memory_glass_fragment:1985, blackwood:1943 |
| repair_support | generous | 100 | barricade_light:152, field_sealant_patch:90, fabricator_pattern_decode_01:80, sensor_pylon_basic:58 | structural_alloy:4867, capacitor_dust:2032, memory_glass_fragment:1979, blackwood:1852 |
| repair_support | scarce | 100 | fabricator_pattern_decode_01:81, barricade_light:49, field_sealant_patch:44, sensor_pylon_basic:38 | structural_alloy:5282, capacitor_dust:2207, blackwood:2028, memory_glass_fragment:1988 |

## Resource Pressure

Top bottlenecks:
- `structural_alloy`: 46152
- `capacitor_dust`: 19566
- `memory_glass_fragment`: 17754
- `blackwood`: 17496
- `resin_clot`: 12639
- `power_components`: 5430
- `fiber_moss`: 5422
- `ruin_scrap`: 2940
- `signal_filament`: 503

Top gained resources:
- `ruin_scrap`: 98969
- `blackwood`: 13752
- `spent_charge_cell`: 12470
- `frayed_signal_filament`: 7217
- `signal_filament`: 5551
- `structural_alloy`: 5532
- `cracked_field_tag`: 5245
- `resin_clot`: 4197
- `power_components`: 3613
- `capacitor_dust`: 2976

## Lore Drop Table Review

- No lore rule violations detected.
- Rule enforced: drops should reveal faction role, objective, and target context instead of generic currency.

## Proposal Contract

- Proposals are JSON-only and written separately from runtime data.
- The pipeline does not apply balance changes automatically.
- Review `changes[]` in the proposal JSON before editing live recipe/drop data.
