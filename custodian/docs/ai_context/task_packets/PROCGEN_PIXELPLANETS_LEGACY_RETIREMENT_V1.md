# PROCGEN PIXELPLANETS LEGACY RETIREMENT V1

- Packet schema: custodian.task_packet.v2
- Workstream: procgen-pixelplanets-legacy-retirement-v1
- Category: world-procgen
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: none
- Locks: procgen-planet-contract
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime
- Paired review workstream: review-procgen-pixelplanets-legacy-retirement-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: Removing a Godot resource dependency from the seeded world-contract generator can silently change RNG selection or break runtime consumers; independently verify deterministic contract identity, scene loading, and absence of resource regressions.
- Reviewed main: 0d41ea40266faa0f3a5ccb8faf251fd65cc883e4
- Authoring chat: not-recorded
- Visual review: none
- Goal: Retire the obsolete PixelPlanets 2D scene integration and tracked dangling symlink without changing deterministic planet identity, procedural world profiles, contract generation, or the existing independently rendered terminal globe.
- Completion boundary: Land the bounded source, scene, symlink, focused regression, and current-tense documentation changes on origin/main through the canonical workstream lifecycle. A separate independent paired review follows implementation landing.
- Current measured state: The tracked custodian/Planets entry is a mode-120000 symlink to ../PixelPlanets/Planets. Host report confirms the physical root PixelPlanets directory is absent. CustodianContractMap currently chooses from six PLANET_LIBRARY keys and attempts to load res://Planets/... scenes. It also defines six corresponding PLANET_WORLD_PROFILES used by the map. TerminalPlanetPreview already builds a seeded procedural 3D globe using contract planet key and seed, not the legacy scene instance. No existing PixelPlanets retirement packet or owner was found in the inspected main; dispatcher eligibility must still be checked at claim time.
- Evidence: custodian/game/world/procgen/custodian_contract_map.gd; custodian/game/world/procgen/custodian_contract_map.tscn; custodian/game/ui/terminal/terminal_planet_preview.gd; custodian/game/ui/hud/ui.gd; custodian/Planets; design/02_features/pixel_planet/PIXEL_PLANET_CONTRACT_SYSTEM.md; design/00_meta/PROJECT_STATUS.md; existing focused contract/procgen/terminal smoke tests.
- Task-specific authority: AGENTS.md and custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; custodian/docs/ai_context/VALIDATION_RECIPES.md; current contract/world-profile owner in custodian/game/world/procgen/custodian_contract_map.gd; seeded terminal renderer in custodian/game/ui/terminal/terminal_planet_preview.gd.
- Work surface: custodian/game/world/procgen/custodian_contract_map.gd; custodian/game/world/procgen/custodian_contract_map.tscn; custodian/Planets (tracked symlink only); contract-dependent runtime/UI consumers where exact references require migration; focused tests under custodian/tools/validation/; design/02_features/pixel_planet/PIXEL_PLANET_CONTRACT_SYSTEM.md; design/00_meta/PROJECT_STATUS.md; only directly affected current-state docs if needed.
- Publication inputs: none
- Change: Remove PLANET_LIBRARY and all six obsolete res://Planets scene paths; choose planet keys from the existing PLANET_WORLD_PROFILES keys in identical sorted order, retaining the existing RNG draw sequence and all six profile values. Remove defunct 2D planet loading/instantiation and unused PlanetRoot, offset, and cleanup state only where independently proven unused. Keep generate_contract and generate_edgar_contract deterministic and retain their planet.key, planet_seed, world_profile, map_seed and contract_seed semantics and signals. Remove planet.instance and planet.scene_path only after auditing all live consumers; do not replace them with fake scenes, null paths advertised as valid, or new duplicate authority. Keep TerminalPlanetPreview procedural and its key/seed behavior unchanged. Delete the single tracked custodian/Planets symlink through the normal claimed worktree; do not follow it. Do not hunt for or fabricate a physical PixelPlanets directory that the host reports absent. Reconcile current-tense design/status claims with the resulting implementation without altering historical archives.
- Preserve: Six ordered planet keys (terran_wet, terran_dry, islands, ice_world, lava_world, gas_giant), all PLANET_WORLD_PROFILES values, deterministic seed selection/profile and weather/tint/foliage output, procgen map and world loader behavior, terminal globe material generation and controls, campaign geography, and existing review claims/locks. No touching the held review-agent-paired-review-declared-doc-archive-gate-v1 checkout or its symlink/evidence; its historical tree is intentionally preserved.
- Non-goals: New planets, new visuals or Asset V2 family, procgen tuning, changes to campaign generation logic, cleanup of unrelated checkouts or independent projects, review recovery, claim parking, deletion of external directories, changes to public WIRE, or bypassing protected dispatcher lifecycle.
- Acceptance: (1) Git main no longer tracks custodian/Planets, and current Godot source/scene resources contain no live res://Planets references. (2) Six keys, their sorted order, per-key world-profile values, deterministic planet key/seed/map-seed results for representative fixed seeds, and map/world-profile generation remain unchanged. (3) The scene and both contract generation paths load with no PixelPlanets files installed. (4) Real terminal globe renders from contract key and seed without planet.instance or planet.scene_path. (5) No runtime consumer or focused smoke requires the absent 2D scene files; active status/design docs describe the new authority correctly. (6) Focused regression and canonical changed-file validation pass with complete applicable coverage, and git diff --check is clean. (7) No other worktree, claim, original review evidence, or unrelated asset is altered.
- Validation: Add or adapt one focused deterministic contract regression and a no-Planets-resource test under custodian/tools/validation/ using existing smoke infrastructure; compare a fixed-seed baseline derived from source before modification rather than asserting newly invented expected RNG values. Run existing focused contract/procgen startup smoke and terminal globe smoke or closest already-registered equivalent; check Godot scene/resource import without the symlink, references through git grep and targeted rg, canonical python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json with complete applicable coverage, and git diff --check. Use targeted authoring/category and packet index checks only when packet metadata changes are necessary; do not run unrelated broad Godot sweeps.
- Task overrides: none
- Deferred: Any future planet source art, alternative visual systems, contract-world redesign, physical deletion of other repositories, or recovery of preexisting review claims.

## Next Handoff

- Next workstream: review-procgen-pixelplanets-legacy-retirement-v1
- Next packet state: dependency-gated until implementation lands and archives complete
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: A fresh independent review of the actually landed deterministic migration is mandatory.
- Next action: After canonical implementation finish and archival on origin/main, dispatch the paired fresh-context review against its exact landed commit and preserved baseline tests.
- Blockers or open questions: No remaining human design decision; normal dispatch/claim, source validation and independent review gates remain authoritative. 
