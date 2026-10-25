# ASH BELL LIFT DEV QUICK LAUNCH
- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-lift-dev-quick-launch`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-surface-lift-v2-asset-intake`
- Locks: `debug-runtime, world-lifecycle, ash-bell-lift-site`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `review-ash-bell-lift-dev-quick-launch`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `asset/route lifecycle or presentation cross-authority; independent post-land verification required`
- Reviewed main: `b224e51a295e19ef4ae15111c1517dc6a79e70ea`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Launch the real playable CUSTODIAN runtime directly outside the Ash-Bell surface lift from a developer-only named preset, without replaying the campaign or using a disconnected art preview.
- Completion boundary: One reusable launch-preset authority and one `ash_bell_lift_surface` preset runnable from a dev-enabled startup path or existing Developer Shell; real Operator, generated-world map, actual AshBellLiftIngressSite and unchanged route/interaction semantics. Prove deterministic placement, camera and controls, and release-safe gating; no gameplay shortcut persists after debugging.
- Current measured state: DevMode capability flags, `/root/DevConsole` command registry, `DebugBus`, `LevelLoader` and `WorldIngressSpawner` already exist. `ContractWorldLoader` currently has specialized `debug_start_near_sundered_keep_entrance` and offset controls; no generic Ash-Bell named launch preset has been found. Ash-Bell site is placed by registered world ingress on generated terrain, its approach point comes from `AshBellLiftIngressPresentation.get_interaction_approach_position()`, and only explicit `DESCEND BELOW` interaction begins travel.
- Evidence: `design/02_features/debug_ui/DEV_MODE_SYSTEM.md`, `DEBUG_DEV_UI_SYSTEM.md`, `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/game/world/levels/world_ingress_spawner.gd`, `custodian/game/world/approaches/ash_bell/ash_bell_lift_ingress_site.gd`, `custodian/game/world/approaches/ash_bell/ash_bell_lift_ingress_presentation.gd`, `custodian/game/ui/debug/dev_console_service.gd`, `custodian/game/world/levels/level_loader.gd`, `custodian/tools/validation/ash_bell_lift_ingress_presentation_smoke.gd`.
- Task-specific authority: `DevMode` capability gate for all debug effects; main startup/ContractWorldLoader for playable world lifecycle; WorldIngressSpawner for real ingress placement; existing AshBellLiftIngressSite for interaction and entry; Developer Shell for interactive command UX. Never put new world authority inside the art scene.
- Work surface: A small named launch-preset registry/controller adjacent to existing dev orchestration (find real current owner first), bounded boot/scene caller and Developer Shell command registration, `ContractWorldLoader` only minimal delegation if required, focused Godot dev-launch smoke/test and `design/02_features/debug_ui/` documentation.
- Change:
  1. Inspect current root bootstrap and debug commands. Choose one short named preset contract `ash_bell_lift_surface`; reject unknown IDs and conflicting flags deterministically. Make the same path callable via developer-enabled startup argument (suggested `-- --custodian-dev --dev-launch=ash_bell_lift_surface` if confirmed by Godot parsing) and Developer Shell (suggested `dev_launch ash_bell_lift_surface`). Command vocabulary is a proposal; preserve existing parser/registry syntax.
  2. Request the standard playable world setup and registered `WorldIngressSpawner` placement. Resolve the **actual** spawned `AshBellLiftIngressSite` instance, wait until world floor/collision/nav and lift placement are ready, then calculate a safe, connected walkable point adjacent to `get_interaction_approach_position()`. Never hardcode a generated-world XYZ, set the Operator inside cliff collision, or skip the actual placement resolver.
  3. Place/activate the **real** Operator and camera in playable world, with normal controls/inventory/physics, no detached puppet at idle, correct entrance orientation. The location is just outside the lift, not inside its boarding bounds. Do not force White Thread/progression unlocked unless the preset explicitly declares a separate unlock variant later.
  4. Enforce DevMode eligibility in both CLI and Developer Shell; release builds, explicit `--no-dev-mode` and `--no-debug-ui` must not expose a mutable shortcut. A failed site lookup, unsafe candidate, incomplete generation or missing camera fails visibly and non-destructively, without teleporting to (0,0) or entering a wrong level. Avoid duplicate world/session spawn if requested after game already runs: use authorized transition/reset or reject with diagnosis.
  5. Expose a deterministic launch receipt/report (preset, seed/map, found ingress ID, actual computed safe spawn position, camera identity, success/fail reason), and a one-command launch instruction in developer docs. Keep extensible to a future lower-lift landing preset without implementing it now.
  6. Add focused smoke with real generated terrain and actual ingress, movement/camera/interaction checks, negative gating for release and unsafe placement, no accidental auto-descend, no false success on spawn failure.
- Preserve: Normal story startup, Awakening/Hub/Contract flow, all portal/route events, real procgen floor/path walkability, Ash-Bell White Thread gating, return route, level loader state, developer-shell non-overlapping modal behavior and release mode.
- Non-goals: No static-position fake lift, isolated mock scene, new global teleport subsystem, new navigation connectivity authority, unlock cheat, general level-selection UI, persistent save mutation, or lift art changes.
- Acceptance: In a dev-capable executable, both launch entrypoints resolve the same named preset and land a controllable Operator on actual connected safe ground just outside a correctly instantiated surface lift with camera following; same exact lift accepts `DESCEND BELOW` and enters the normal Underground path; invalid preset/release flags/unsafe spawn fail without world corruption; ordinary boot untouched.
- Validation: Existing `ash_bell_lift_ingress_presentation_smoke.gd`, `world_ingress_spawner_smoke.gd`, `world_ingress_physics_reentry_smoke.gd`, `contract_world_operator_void_spawn_failsafe_smoke.gd`, `dev_console_contract_smoke.gd` as directly affected; new focused playable quick-launch smoke (name after file creation), release/negative launch smoke, `git diff --check` and changed-file validation.
- Task overrides: `none`
- Deferred: More presets (underground lower lift, unlocked White Thread, chapel) and an interactive location picker UI. No dependency on integration artwork to exercise canonical current lift.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Follow the dependency order; deliver exact validation and artifact/provenance evidence, then let the paired fresh-context review execute.
- Blockers or open questions: More presets (underground lower lift, unlocked White Thread, chapel) and an interactive location picker UI. No dependency on integration artwork to exercise canonical current lift.

