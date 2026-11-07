# App

- Belongs here: startup mode selection and boot-time routing between Awakening, the development Twin Solaria wrapper, and the Contract sandbox.
- Does not belong here: procgen construction, combat simulation, UI page rendering, actor behavior.
- Current runtime owner: `boot/runtime_entrypoint.gd` parses only the documented CUSTODIAN startup modes and changes to their fixed scene targets. `boot/startup_mode.gd` owns argument validation.
- Production default: no arguments, or `--custodian-start=awakening`, routes to `res://scenes/awakening_first_return.tscn` without starting Contract generation.
- Development modes:
  - `godot --path custodian -- --custodian-start=twin-solaria` routes to the existing `res://scenes/twin_solaria_playtest.tscn` wrapper at Crown Causeway.
  - `godot --path custodian -- --custodian-start=contract-sandbox` starts the persistent `WorldContractBootstrap` once and immediately loads `res://scenes/game.tscn`.
  - `godot --path custodian -- --custodian-start=contract-sandbox --contract-seed=123456` injects a deterministic nonzero seed into the same bootstrap.
- Unknown modes and malformed/inapplicable seeds warn and fall back to Awakening. The router accepts no scene-path override. Missing target scenes or the bootstrap fail visibly without a fallback loop.
- Source of truth: `project.godot` selects `boot/runtime_entrypoint.tscn`; the entrypoint selects the fixed target scenes while existing scene/bootstrap authorities retain their behavior.
## Field Scout Buggy playtest (development-only)

The default **Run Project** (F5) entrypoint and
`--custodian-start=awakening` load
`res://scenes/awakening_first_return.tscn`, which does **not** contain the
Field Scout. The first live Scout is scene-authored under
`res://scenes/game.tscn`, not registered as a spawn in Awakening.

From the **repository root**, launch the Contract sandbox. Godot's **Run
Current Scene** (F6) bypasses the project entrypoint if another scene is
selected; use the explicit project startup argument below:

```sh
godot --path custodian -- --custodian-start=contract-sandbox --contract-seed=123456
```

The seed is optional; supply the same nonzero seed when reproducing placement.
The authored node is `/root/GameRoot/World/FieldScoutBuggyMk1` at
`Vector2(872, -486)` before generation. On a successful Contract install,
`ContractWorldLoader._position_vehicles()` prefers walkable parking-zone
tiles (or main-road tiles when the raw parking list is empty), then eligible
compound tiles if the selected parking/road candidates fail the open-tile filter.
The fallback currently may leave the authored position unchanged when no
candidate is available; **do not** treat the authored coordinates as a reliable
in-world destination after generation.

To investigate a missing Scout, inspect Godot's **Remote** scene tree while
running the sandbox. Confirm the node exists under `GameRoot/World`, inspect
its live `global_position`, `visible`, sprite resource and parent transforms,
and compare the location to the generated playable area. Do not infer its
position from the editor's Local scene tree. At first spawn the Scout is
intentionally **WRECKAGE** (0 health, non-pilotable). Current rendering still
uses `hover_buggy_idle_frames.tres` compatibility art rather than approved
wheeled Scout art; its damaged appearance is not final. The fabricated-assembly
R1 restoration correction and canonical Asset Pipeline V2 family integration
are separately queued and should not be bypassed to demonstrate the vehicle.

Relevant focused verification (from the repository root, with Godot available):

```sh
python3 custodian/tools/validation/run_validation.py --test vehicle_field_scout_class --json
python3 custodian/tools/validation/run_validation.py --test world_contract_prewarm --json
```

Those tests exercise class and startup contracts; they **do not** currently
prove that every seed places the Scout within visual reach. The existing
`contract-world-vehicle-placement-extraction` workstream owns the eventual
vehicle placement service, and any discoverability guarantee needs its own
fixed-seed, runtime-validated acceptance proof.
