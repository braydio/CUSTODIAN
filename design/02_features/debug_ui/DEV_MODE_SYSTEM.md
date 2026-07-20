# DEVELOPMENT MODE SYSTEM

Status: implemented V1
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Goal

Provide one release-safe runtime authority for developer capabilities without making offline tooling depend on game state.

## Runtime Contract

`DevMode` is the first debug-related autoload. It derives capability state from:

- `OS.is_debug_build()`;
- the `custodian_dev` custom export feature;
- `custodian/dev/enabled` project setting;
- explicit command-line opt-ins such as `--custodian-dev`, `--debug-ui`, `--observe`, or `--heavy-diagnostics`.

`--no-dev-mode`, `--no-debug-ui`, `--no-observe`, and `--no-heavy-diagnostics` are explicit negative overrides. Heavy diagnostics are not enabled merely because the executable is a debug build; they require the heavy flag or `custodian/dev/heavy_diagnostics`.

Capabilities:

```text
DevMode.enabled
DevMode.debug_ui_enabled
DevMode.observatory_sampling_enabled
DevMode.heavy_diagnostics_enabled
DevMode.allows(capability)
```

`DebugBus`, `DebugSnapshotCollector`, `DebugImguiConsole`, and `DevObservatory` disable their eligible input/process work when the corresponding capability is unavailable. Observatory event/counter/gauge accumulation is disabled outside development eligibility. Explicit Observatory export remains callable and forces one current runtime snapshot.

The native `ImGui` extension remains an unconditional autoload in V1; its CUSTODIAN console consumer does not connect or draw outside debug-UI eligibility. A future `DevBootstrap` may instantiate/remove the entire debug stack per export.

## Offline Boundary

Python reports, Aseprite pipelines, HTML review generators, and explicitly invoked validation scripts do not read `DevMode`. Command invocation is their development gate.

## Acceptance

- Release-style resolution is disabled by default.
- Debug builds enable cheap development/UI and Observatory eligibility but not heavy diagnostics.
- Custom feature, project setting, and positive/negative command-line overrides resolve deterministically.
- `DevMode` loads before the debug stack.
- Observatory export retains its forced final snapshot behavior.
