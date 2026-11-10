<!-- V2 turn metadata -->
Task identity: weather-v2-presentation-contract-v1
Task definition: custodian/docs/ai_context/task_packets/WEATHER_V2_PRESENTATION_CONTRACT_V1.md at origin/main aaa2c3e9f0915ca90d168d9b65aafe2483439d07
Remote branch: agent/weather-v2-presentation-contract-v1
Acquisition mode: normal
Acquisition source: origin/main (no prior branch; fresh start)
Acquisition source commit: a283d2a71279e657e1e1ddb485f9e99e48954e63
Checkpoint base: 627fba1798dcd96a4e76ae77aba061781ad02006
<!-- /V2 turn metadata -->

# Turn Handoff — Weather V2 Presentation Contract V1

Workstream: `weather-v2-presentation-contract-v1`

Original goal: Add an opt-in reusable weather presentation profile and deterministic visual samples while preserving V1 weather scheduling, lighting modifiers, indoor exposure, and gameplay authority.

Implemented: `WeatherPresentationProfile`, quality caps, climate/zone/weather overrides, contract-derived seed, fixed-step sample time and presentation-only wind scaling. The no-profile shader path retains V1 `TIME` behavior. No weather schedule or lighting system behavior was changed.

Remaining: Publish the downstream LFS materialization correction through the supported V2 checkpoint; verify remote CI completes LFS pull, Godot editor import, and the unchanged test set; then complete normal landing and fresh paired post-land review. GPU timing, production quality budgets, and final subjective style approval remain pending.

Validation: The exact changed-validation command fails 10/14 before a headless editor import because Godot global classes are not registered, then passes 14/14 after `godot --headless --editor --path custodian --quit`. GitHub run 42745019303 completed class import but failed LFS preflight (`13,549` unresolved pointer paths), so the downstream job now enables LFS and explicitly runs `git lfs pull` and `git lfs checkout` before import. That correction awaits its new remote CI result. `weather_v2_profile_contract`, `weather_v2_profile_baseline`, `world_environment`, and post-import `world_atmosphere_smoke` pass locally. The atmosphere smoke also passes on clean origin/main. `lighting_system_smoke` fails identically on both because its two scene preloads are absent; keep that as separately owned baseline validation debt.

Resume: Keep the active Weather checkout until the LFS workflow correction is checkpointed, its downstream CI passes, and landing/review are complete. Any Godot import cache created for local verification is generated and regenerable; remove only after confirming no process is using this checkout, and then retry through the supported V2 lifecycle.

Sources/evidence: `WEATHER_V2_PRESENTATION_CONTRACT_V1_CLAUDE_SUMMARY.md`; `design/02_features/environment/WEATHER_PRESENTATION_V2_ROADMAP.md`; clean baseline commit `aaa2c3e9f0915ca90d168d9b65aafe2483439d07`.
