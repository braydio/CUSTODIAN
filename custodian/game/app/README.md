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
