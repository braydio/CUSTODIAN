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

GitHub downstream changed validation initially failed four tests on a clean checkout (10 passed): the two new Weather V2 tests, `world_environment`, and `carrow_operations_house_interior`. Their logs showed unavailable global GDScript classes because the workflow invoked the validation runner before Godot's editor import registered project classes. Reproducing the exact `run_validation.py --changed --base origin/main --json` command locally produced the same 10/14 result before import. After `godot --headless --editor --path custodian --quit`, the same command passed 14/14. That fixed the class-resolution failures, but the next CI run found a second clean-checkout prerequisite: LFS pointer files were still present during the import preflight (`13,549` unresolved paths). The downstream job now enables LFS checkout and runs `git lfs pull` plus `git lfs checkout` before the editor import. Test selection and manifest remain unchanged. Run `42746980494` passed after the downstream job materialized LFS, imported project classes/resources, and ran the unchanged 14-test selection successfully.

## Status and handoff

The implementation landed in PR #124 at merge commit `495ea3a1ff55f9740692e5d762a385d7aec64440`, incorporating tested implementation head `bffb65e9f2e2d0d0c17e4921be66e81187bdc3d2`. GitHub run `42746980494` passed all three required jobs, including LFS materialization, headless editor import, and downstream changed validation. The V2 `workstream.py finish` retired the temporary implementation checkout; its final metadata checkpoint is `d25103a1976130646640e1f507a7d2e1536697f3` and does not replace the landed implementation commit. The required fresh paired review is pending. No visual approval is implied; the packet makes final subjective review conditional. Keep the missing-scene lighting baseline documented and separately owned.

## Next Handoff

Claim and complete `review-weather-v2-presentation-contract-v1` in a fresh reviewer context after the implementation packet's archived-complete transition. Do not acquire `weather-v2-layered-precipitation-v1` until review acceptance. GPU profiling, production quality budgets, and conditional subjective style approval remain future gates.
