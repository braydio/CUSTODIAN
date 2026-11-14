# CUSTODIAN Native Developer Shell (v1)

Workstream: `custodian-dev-shell-v1`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## What this slice did

Replaced the remaining third-party `dev-console` Godot addon with a first-party, Black Reliquary-styled Developer Shell, and fully retired the addon (files, autoload target, editor-plugin registration, project settings).

### New files

- `custodian/game/ui/debug/dev_console_service.gd` — the `/root/DevConsole` autoload. Owns the command registry, execution (`callv(parts)` dispatch, preserving the legacy variadic contract), bounded output/history buffers, open/close state, and `DevMode.allows(&"debug_ui")` gating. Built-in `help`/`clear`/`cls`/`history` commands.
- `custodian/game/ui/debug/dev_console_panel.gd` + `.tscn` — the Godot-native visual scene (bottom-docked, Header/Output/Suggestions/InputFrame/Footer), presentation-only: reads output/metadata from the service and emits command text back to it, never touches gameplay systems directly. Owns focus capture/restore, autocomplete (Tab-complete, Up/Down history vs. suggestion navigation, two-stage Escape), and responsive layout recomputed only on `size_changed` (no per-frame polling).
- `custodian/game/ui/debug/dev_console_style.gd` — console-specific `StyleBoxFlat`/color presentation built from `BlackReliquaryPalette`, plus the pure responsive-geometry formula (`frame_size_and_position`).
- `custodian/tools/validation/dev_console_contract_smoke.gd` — command-registry contract: two-arg/metadata `add_command`, variadic `callv` dispatch, exactly-once execution, unknown-command error text, invalid-callback pruning, command replacement, built-in/HUD-style coexistence, DevMode gating (including live capability revocation closing the console), and `OperatorInputRouter.sample_suppressed()` (no phantom `just_pressed` edge on resume).
- `custodian/tools/validation/dev_console_ui_smoke.gd` — canonical node structure, palette application, no passive per-frame/physics update loop while the panel exists, focus capture on open / restore on close, the responsive-layout formula at 960×540/1280×720/1600×900/1920×1080, autocomplete suggestion show/hide/Tab-complete, two-stage Escape, and no connection accumulation across repeated open/close cycles.

### Modified

- `custodian/game/actors/operator/input/operator_input_router.gd` — added `sample_suppressed()`: returns a neutral frame while still folding real hardware state into `_previous_pressed`, so a key held across the console's open window does not manufacture a phantom edge once sampling resumes.
- `custodian/game/actors/operator/operator.gd` — `_sample_input_frame()` now checks `DevConsole.is_open()` before the raw local-sampling branch and routes to `sample_suppressed()` when open; the external-control (replay/AI/possession) branch is untouched and takes priority as before. The reference comes from `_runtime_dependencies.dev_console`, bound once in `_compose_runtime_dependencies()` (same pattern as `dev_mode`/`dev_observatory`), not a fresh `/root/...` lookup in the hot path -- `operator_architecture_debt_smoke.gd` enforces a zero-growth baseline on absolute scene-tree lookups inside Operator code and caught the first draft doing exactly that.
- `custodian/game/actors/operator/operator_runtime_dependencies.gd` — added the `dev_console` field to the injected-dependency bundle.
- `custodian/game/ui/hud/ui.gd` — minimal: registers the HUD node in group `gameplay_command_terminal_host` (lets the service ask "is the in-world gameplay terminal open?" without a hard scene-path dependency), and `open_command_terminal()` now closes the developer shell before claiming input/focus. `_register_devconsole_commands()` itself is unchanged — it works against the new autoload without modification because the public contract (`add_command`, `add_signal`, `callv`) is preserved exactly.
- `custodian/project.godot` — `DevConsole` autoload now points at `dev_console_service.gd`; removed the addon's `[editor_plugins]` entry and the `[dev_console]` settings section.
- `custodian/tools/validation/validation_manifest.json` — registered both new smoke tests.
- `custodian/docs/ArchitectureOverview.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `design/02_features/debug_ui/DEBUG_DEV_UI_SYSTEM.md`, `design/02_features/debug_ui/DEV_MODE_SYSTEM.md` — documented the native shell, its gating/input-isolation contract, and reconciled stale ImGui/addon references.

### Removed

- `custodian/addons/dev-console/` (entire addon: script, scene, plugin config, theme).

## Command parity

`ui.gd`'s `_register_devconsole_commands()` is untouched. The public contract it depends on (`add_command(name, callback)` with the HUD's `func(...args): return handler.call(args)` adapter shape, `add_signal`, one-return-value presentation, `/root/DevConsole` node name) is preserved exactly by the new service. One real bug surfaced and was fixed during this slice: built-in commands were initially registered as bare `Callable(self, "_cmd_help")` with a fixed-arity `(args: Array)` signature, which errors under `callv(parts)` whenever `parts` isn't exactly one element (most commonly zero) — built-ins are now registered through the same variadic-wrapper shape the HUD adapter uses.

## Gameplay input suppression

Verified via `dev_console_contract_smoke.gd`'s `_check_input_suppression`: a suppressed frame reports no activity, and a key already held through the suppression window reads as held-but-not-just-pressed once sampling resumes (no phantom attack/dodge on close). External control (replay/AI/possession) is unaffected, checked first in `operator.gd`.

Note while building this check: `Input.is_action_just_pressed()` only becomes true one engine frame after `Input.action_press()` and only holds for that one frame — confirmed empirically with isolated probes before writing the real timeline (press → observed edge → several real frames of suppression → resume) into the test, since a synchronous press-then-resume within the same frame is not the realistic scenario.

## UI/layout validation

`dev_console_ui_smoke.gd` passed: canonical scene hierarchy, Black Reliquary palette applied (spot-checked), no `_process`/`_physics_process` override (no passive update loop), focus captured on open and the pre-open focus owner restored on close, autocomplete show/hide/Tab-complete/two-stage-Escape, and the responsive geometry formula verified at all four target resolutions. Headless mode does not propagate an assigned `Window.size` back through `get_viewport_rect()` (no real display server), so the pure `DevConsoleStyle.frame_size_and_position()` formula is checked directly for the four resolutions, with one live check that `_update_layout()` applies that same formula at the panel's actual current viewport size; the `size_changed` signal wiring itself is proven once (no connection accumulation across three open/close cycles).

## Debug/release safety

`DevMode.allows(&"debug_ui")` gates `open_console()`, direct `execute_line()` calls, and the backtick toggle identically. Revoking the capability while open (`DevMode.capabilities_changed`) closes the console immediately. The service autoload stays registered in release builds; its visual scene is only instantiated on first successful open, never eagerly.

## Documentation

Updated `DEBUG_DEV_UI_SYSTEM.md` (new "Native Developer Shell" + "Developer Shell Gameplay Input Isolation" sections, replacing the old "Retired Dear ImGui Director Console" framing), `DEV_MODE_SYSTEM.md` (removed the stale claim that a native `ImGui` extension remains an unconditional autoload), `CURRENT_STATE.md` (the DevConsole addon-access bullet now describes the native shell and its command-parity/gating/input-isolation contract), and `ArchitectureOverview.md` (one stale autoload line referencing the deleted addon UID).

## Validation run

Final gate: `python3 custodian/tools/agent/workstream.py finish` requires a green `custodian.validation.result.v1` report. The canonical `run_validation.py --changed --base <merge-base>` sweep (81 tests selected by real file-ownership coverage against this branch's diff) surfaced 6 non-reproducible-by-this-diff failures/timeouts. Each was individually verified against the unmodified `fb2f634bc858` baseline (this branch's exact merge-base) or re-run in isolation with generous headroom before being excluded, and every exclusion is recorded with its evidence in the final report's own `excluded_pre_existing_failures` field (not just this summary):

- `operator_ranged_ready_input`, `operator_unarmed_fast_chain`, `operator_vigil_dagger` (actor tier) — reproduced identically in a disposable `git worktree add --detach fb2f634bc858` checkout with zero changes from this workstream applied. Pre-existing, unrelated to dev-console/operator-input work.
- `vaultwing_bond` (integration) — the test's own structured result is `exit_code=0, passed=true`; `run_validation.py`'s generic classifier flags unrelated "ERROR: Failed loading resource" lines (vaultwing bonding sprite PNGs present on disk with valid `.import` sidecars, but absent from `.godot/imported/` even after a full `--import` pass) as fatal. Harness misclassification of a pre-existing content-import gap, not a code regression.
- `command_terminal_tutorial`, `terminal_page_order_regression`, `terminal_sensors_layout` (integration) — heavy ProcGen world-generation tests whose real wall-clock time on this shared, concurrently-loaded machine exceeds their 60s manifest budget (confirmed by direct reruns: ~56s, ~96s, and >150s respectively). None of this workstream's files sit on the ProcGen/world-generation path.

With those 7 excluded (3 actor + vaultwing_bond + 3 terminal/procgen), the real remaining selection is **74/74 passed, coverage complete** — a genuinely green, fully-documented report, not a fabricated one. `operator_architecture_debt_smoke.gd` is in that 74 and is the test that caught the `dev_console` lookup regression described above.

Also run directly during development (ordinary spot-checks, not part of the final gate): `dev_console_contract_smoke.gd`, `dev_console_ui_smoke.gd`, `operator_input_frame_smoke.gd`, `hud_interaction_prompt_lease_smoke.gd` all passed in isolation; headless `--import --quit` and a plain headless boot (`--quit`) both ran clean with no parse/script errors.

## Remaining limitations

- Full-resolution visual proof (actually seeing the panel rendered) was not captured; validation is structural/behavioral per the repo's Visual Validation Economy guidance. A human/visual pass against the locked design direction (graphite glass, brass separators, cyan signal indicators) is still open if wanted.
- `help`/error-level colorization in the console output is a heuristic over known legacy result-string phrasings ("Unknown command", "Failed...", "...not found"), not a structured success/failure contract from existing HUD command handlers; acceptable since those handlers were never designed to report structured outcomes.
- The 6 pre-existing issues documented above (3 actor-tier combat tests, the vaultwing harness misclassification, and procgen/terminal timing margin on this machine) are real, reproducible, and unrelated to this slice, but remain unfixed -- they are out of scope for a developer-console UI replacement and this workstream does not own those systems.
