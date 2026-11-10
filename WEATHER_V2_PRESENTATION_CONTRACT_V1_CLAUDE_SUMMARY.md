# Weather V2 Presentation Contract V1 — Implementation Summary

Workstream: `weather-v2-presentation-contract-v1`

## Result

The workstream adds an opt-in `WeatherPresentationProfile` resource, quality-tier caps, climate/zone/weather overrides, contract-seeded visual sampling, fixed-step visual time, and presentation-only wind scaling. V1 weather schedule, lighting modifiers, indoor exposure and gameplay authorities remain unchanged when the profile is absent. The profile-state CPU baseline is recorded in the roadmap; GPU cost and production quality budgets remain unmeasured.

## Validation and baseline parity

Passed on the Weather workstream after a headless editor import:

- `weather_v2_profile_contract`
- `weather_v2_profile_baseline`
- `world_environment`
- `world_atmosphere_smoke.gd` (also passed on clean `origin/main@aaa2c3e9f0915ca90d168d9b65aafe2483439d07` after editor import)

The earlier 180-second timeout/assertion was stale generated Godot import/class-cache state. It did not recur after import on the workstream or clean main and is not attributed to the Weather source changes. The comparison refreshed generated `.godot` cache data only.

`lighting_system_smoke.gd` fails identically on clean main and the workstream because it preloads absent `lighting_playground.tscn` and `gatehouse_lighting_test.tscn`. This is pre-existing mainline validation debt, outside this slice; neither lighting assets nor the smoke were changed. The focused `check_ai_context.py`, manifest JSON parse and `git diff --check` pass.

### CI clean-checkout import correction

GitHub downstream changed validation initially failed four tests on a clean checkout (10 passed): the two new Weather V2 tests, `world_environment`, and `carrow_operations_house_interior`. Their logs showed unavailable global GDScript classes because the workflow invoked the validation runner before Godot's editor import registered project classes. Reproducing the exact `run_validation.py --changed --base origin/main --json` command locally produced the same 10/14 result before import. After `godot --headless --editor --path custodian --quit`, the same command passed 14/14. The downstream validation job now performs that import before running the unchanged selection; the manifest and test set are unchanged. The updated GitHub check is pending after publication.

## Status and handoff

The implementation remains unlanded and needs the packet's fresh paired review after landing. No visual approval is implied; the packet makes final subjective review conditional. Keep the missing-scene lighting baseline documented and separately owned. Do not create or acquire a separate repair task from this result.

Next Handoff: checkpoint the existing Weather V2 workstream through its supported V2 lifecycle, publish the exact branch SHA, let updated downstream CI verify the editor-import correction, then use the normal landing and fresh paired-review path. GPU profiling and production quality budgets remain future review gates.
