# Operator Dodge And Ranged Modular Wiring

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-08
- Created: 2026-06-08
- Last updated: 2026-06-08

## Task

Wire the newly authored full 9-frame Operator dodge body/FX strips into live dodge playback and ingest the completed
E/N/W two-handed ranged stance layers into stable modular runtime resources.

## Outcome

The live dodge presentation uses the authored north/south 9-frame body and FX sequences without changing deterministic
dodge movement, recovery, stamina, or cooldown timing. Completed ranged stance layers are normalized into stable
runtime module paths and registered for follow-up primary-ranged modular presentation work.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, Operator sprite pipeline and focused smokes
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: Operator runtime, sprite pipeline, focused validation, combat-feel/current-state docs
- Files or folders expected to be read but not changed: weapon definitions and existing sidearm modular playback
- Out-of-scope areas: dodge physics tuning, sidearm behavior changes, incomplete ranged fire/aim/reload modular playback

## Constraints

- Determinism concerns: preserve existing dodge timers, velocity, stamina cost, and cooldown
- Simulation/UI boundary concerns: animation selection remains presentation-only
- Asset requirements: use supplied N/S 9-frame dodge body/FX and supplied E/N/W 5-frame ranged stance layers
- Compatibility or migration concerns: retain legacy split dodge/recovery tracks as fallback
- Clarifying questions or assumptions: E/N/W ranged stance is partial coverage and must not replace legacy fire/reload behavior

## Implementation Plan

1. Generate stable full-dodge and ranged-stance runtime sheets.
2. Register full-dodge tracks and partial ranged stance modules in curated SpriteFrames.
3. Select full dodge direction at runtime while allowing the sequence to continue through recovery.
4. Update focused smoke coverage and active docs.

## Acceptance

- Runtime behavior: N/S 9-frame body and FX dodge tracks are selected and continue through recovery
- Documentation: combat feel and AI context describe the live/fallback coverage accurately
- Path/reference validation: generated runtime paths exist and are registered
- Manual validation: inspect supplied strips and generated dimensions
- Automated/headless validation: pipeline rebuild plus Operator ranged-ready/modular smoke tests

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: yes
- `custodian/docs/ai_context/CONTEXT.md`: no
- `custodian/docs/ai_context/FILE_INDEX.md`: yes
- `custodian/AGENTS.md`: no
- Design docs: yes

## Completion Notes

- Implemented: live N/S 9-frame full-dodge body/FX playback; stable runtime generation for full dodge strips; E/N/W two-handed ranged-ready lower, upper, and weapon stance module generation; live idle carbine-ready modular stance playback; focused smoke coverage.
- Validated: `python -m py_compile tools/pipelines/build_operator_modular_runtime.py`; `python tools/pipelines/build_operator_modular_runtime.py`; `godot --headless --path . --script res://tools/pipelines/update_operator_curated_resources.gd`; `godot --headless --path . --script res://tools/validation/operator_ranged_ready_input_smoke.gd`; `godot --headless --path . --script res://tools/validation/operator_modular_layers_smoke.gd`; `godot --headless --path . --editor --quit`; `git diff --check` on touched text files.
- Deferred: dedicated E/W/diagonal dodge strips, optional authored aim-backstep strips, and full modular two-handed ranged movement/fire/recover/reload/muzzle/smoke coverage.

## Next Steps

- Next action: supply remaining production animation coverage when ready
- Best starting files: `custodian/game/actors/operator/operator.gd`
- Required context: supplied dodge/ranged modular sheets
- Validation to run: modular builder, curated rebuild, focused Operator smokes
- Blockers or open questions: production directional dodge and complete ranged action coverage remain partial
