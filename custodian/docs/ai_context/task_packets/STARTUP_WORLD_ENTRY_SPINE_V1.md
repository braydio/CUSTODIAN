# STARTUP WORLD ENTRY SPINE V1

- Workstream: `startup-world-entry-spine-v1`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-review-pipeline`
- Locks: `app-boot, world-lifecycle`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-startup-world-entry-spine-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Replace implicit scene-as-boot-policy startup with the first explicit CUSTODIAN App/Boot spine, preserving Awakening as the production default while making Twin Solaria and the procgen Contract sandbox directly bootable for development through deterministic startup modes.
- Current measured state: `project.godot` directly boots `res://scenes/awakening_first_return.tscn`. Awakening intentionally owns no Contract prewarm or handoff. `game.tscn` is the current procgen Contract runtime shell and binds persistent `WorldContractBootstrap` through `WorldContractProxy`. Production Twin Solaria is registered as `hub_twin_solaria`; `twin_solaria_playtest.tscn` is its standalone Operator/camera wrapper. `game/app/` is scaffold-only even though `ARCHITECTURE.md` already assigns startup mode selection and runtime entrypoint ownership there.
- Task-specific authority: `custodian/docs/ARCHITECTURE.md`; `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `custodian/game/app/README.md`; live `WorldContractBootstrap`; Twin Solaria level definition.
- Change: Add a minimal runtime entrypoint and startup-mode parser under `game/app/boot/`; make it the project main scene; route default to Awakening without Contract generation; add explicit development startup modes for Twin Solaria and Contract sandbox; allow deterministic optional Contract seed injection; add focused validation and correct stale boot docs.
- Preserve: production story begins in Awakening; Awakening does not prewarm or surface a Contract; Twin Solaria remains Hub-context and is not added to procgen `world_ingress`; `game.tscn` remains the procgen Contract runtime shell; `WorldContractBootstrap` remains the sole prewarm/generation authority; existing `WorldContractProxy`, `ContractWorldLoader`, `LevelLoader`, and `RouteTraversalManager` remain their existing authorities.
- Non-goals: No Ashen Forum implementation; no Road→Forum transition; no production Continuity Port; no Twin story unlock; no procgen performance refactor; no pause-policy changes; no Contract outcome/return loop; no new assets; no default story boot change away from Awakening.
- Acceptance: No-override boot still reaches Awakening with bootstrap generation count zero. Twin startup enters the existing Twin playtest wrapper at Crown Causeway. Contract-sandbox startup begins exactly one bootstrap generation and loads `game.tscn`; the existing proxy/loader consumes the same in-flight/ready contract without duplicate generation. Invalid modes fail safely to Awakening. Startup code contains no procgen construction or gameplay authority.
- Deferred: production Awakening→Hub transition; Hub runtime host; Hub→Twin Solaria physical route; Field Terminal/Continuity Port handoff; pause-independent background streaming; procgen optimization/decomposition.

## Architecture

Implement the target App/Boot layer already named in `custodian/docs/ARCHITECTURE.md`:

```text
custodian/game/app/boot/
    startup_mode.gd
    runtime_entrypoint.gd
    runtime_entrypoint.tscn
```

Keep this surface tiny.

### Startup modes

Use one explicit CLI contract, preferably:

```bash
godot --path custodian -- --custodian-start=awakening
godot --path custodian -- --custodian-start=twin-solaria
godot --path custodian -- --custodian-start=contract-sandbox
godot --path custodian -- --custodian-start=contract-sandbox --contract-seed=123456
```

If a canonical developer argument parser now exists on live main, reuse it.

Do not accept arbitrary scene paths.

Mode targets:

```text
awakening
  -> res://scenes/awakening_first_return.tscn

twin-solaria
  -> res://scenes/twin_solaria_playtest.tscn

contract-sandbox
  -> /root/WorldContractBootstrap.ensure_started(optional_seed)
  -> res://scenes/game.tscn
```

## Production Default

No args must remain:

```text
runtime_entrypoint
  -> awakening
  -> awakening_first_return.tscn
```

It must not call `WorldContractBootstrap.ensure_started()`.

Preserve the current opening contract: no Field Terminal, no Forum, no Continuity Port, no Contract, no prewarm.

## Twin Solaria Direct Startup

For `twin-solaria`:

- route to the existing playtest wrapper, not a new duplicate scene;
- prove it hosts the production `hub_twin_solaria` level;
- prove arrival at `Spawn_CrownCauseway`;
- do not add `world_ingress` to `twin_solaria_v1.json`;
- do not mark Twin unlocked in Hub/campaign state;
- do not generate a Contract.

This is a developer startup path only. Production access is a later Hub route.

## Contract Sandbox Direct Startup

For `contract-sandbox`:

1. parse optional integer seed;
2. call persistent `WorldContractBootstrap.ensure_started(seed)` exactly once;
3. change to `game.tscn`;
4. allow existing `WorldContractProxy` to publish the ready contract or wait for `contract_ready`;
5. allow existing `ContractWorldLoader` to attach the accepted map beneath `World/ProcGenRuntime`, reposition Operator/world anchors, refresh camera/navigation, and place registered world ingresses.

Do not wait for generation to finish before loading `game.tscn` merely to simplify control flow. The persistent bootstrap already exists to span that scene boundary.

Do not add a second generator.

## Failure Contract

Unknown mode: warn and route to Awakening.

Malformed seed: define one explicit safe behavior and test it. Do not silently interpret malformed input as a meaningful seed.

Missing target scene: fail visibly without recursive fallback loops.

## Documentation Drift

Update `custodian/docs/ARCHITECTURE.md`:

- its App/Boot section already knows Awakening is the application opening;
- its later “Current Boot Flow” still incorrectly begins with `game.tscn` and immediate Contract generation;
- its migration note still refers to wiring the superseded Home scene as default.

After this slice, current boot truth is:

```text
runtime_entrypoint
  -> Awakening by default
  -> explicit Twin/Contract developer modes
```

The future production sequence remains:

```text
Awakening -> Hub/Forum -> Contract deployment
```

Update `game/app/README.md`, `CURRENT_STATE.md`, `CONTEXT.md`, and `FILE_INDEX.md` only as required by live behavior.

## Focused Validation

Add a focused startup smoke such as:

`custodian/tools/validation/startup_world_entry_smoke.gd`

Prove:

1. `project.godot` points to the runtime entrypoint;
2. default/no args resolves Awakening;
3. default boot leaves `WorldContractBootstrap.generation_count == 0`;
4. explicit Awakening matches default;
5. Twin mode resolves only to existing Twin wrapper;
6. Twin wrapper uses production Twin level and Crown Causeway spawn;
7. Twin mode does not create procgen generation or world ingress;
8. Contract mode calls bootstrap exactly once;
9. fixed seed reaches bootstrap unchanged;
10. `game.tscn` proxy sees the same bootstrap generation/contract rather than starting a second one;
11. bad mode/seed follows documented fail-safe;
12. direct `game.tscn` compatibility remains if existing tests require it;
13. `world_contract_prewarm_smoke.gd`, Awakening smoke, and Twin runtime smoke remain green.

Register validation-manifest ownership. Run focused tests first, then changed-file validation and `git diff --check`.

No Moment Forge required.

## Completion

Archive this packet complete, leave the paired review active, write
`STARTUP_WORLD_ENTRY_SPINE_V1_CLAUDE_SUMMARY.md`, record exact startup commands, and land normally.

## Handoff

- Next action: production Hub continuation/world-transition slice, not more logic in the boot router.
- Best starting files: `project.godot`, `game/app/README.md`, `WorldContractBootstrap`, `world_contract_proxy.gd`, `twin_solaria_playtest.tscn`, and the boot/flow docs.
- Blockers or open questions: none. Hub/Forum content remains intentionally deferred.
