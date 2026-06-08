# Operator Modular Sidearm Playback

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-06
- Created: 2026-06-06
- Last updated: 2026-06-07

## Task

Correct upper-body facing ownership and wire the ingested modular sidearm draw/fire layers into live Operator playback.

## Outcome

Ordinary locomotion faces upper and lower body together, ranged-ready gives aim direction to the upper body, and sidearm draw/fire/FX assets render through dedicated modular layers.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Active runtime/docs files: `custodian/game/actors/operator/`, `custodian/tools/pipelines/update_operator_curated_resources.gd`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: Operator runtime scene/script/resources, curated-resource builder, modular smoke, active design/context docs
- Files or folders expected to be read but not changed: modular sidearm runtime PNGs
- Out-of-scope areas: new production art and combat simulation tuning

## Constraints

- Determinism concerns: facing ownership must derive from existing deterministic state and direction vectors.
- Simulation/UI boundary concerns: animation layers are presentation-only.
- Asset requirements: draw/fire lower, upper, pistol, and FX layers exist for NE/NW/SE/SW; cardinal/recovery/reload coverage remains missing.
- Compatibility or migration concerns: retain legacy ranged placeholders when modular sidearm playback is unavailable.
- Clarifying questions or assumptions: use the final complete draw frame as the held ready pose and resolve pure cardinal aim to the nearest authored diagonal.

## Implementation Plan

1. Correct upper-body locomotion facing ownership.
2. Add dedicated sidearm weapon/FX SpriteFrames and scene layers.
3. Synchronize ready/fire presentation and add focused smoke coverage.
4. Update active docs and validate headlessly.

## Acceptance

- Runtime behavior: locomotion-only upper/lower face movement; sidearm-ready upper faces aim; sidearm fire uses modular upper/weapon/FX layers.
- Documentation: active design and current-state docs describe the contract and asset gaps.
- Path/reference validation: new resources load from stable modular runtime paths.
- Manual validation: deferred if no interactive display is available.
- Automated/headless validation: curated rebuild and focused Operator smoke tests pass.

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md`: update required.
- `custodian/docs/ai_context/CONTEXT.md`: no ownership change required.
- `custodian/docs/ai_context/FILE_INDEX.md`: no new entrypoint required.
- `custodian/AGENTS.md`: no routing change required.
- Design docs: update combat-feel facing contract.

## Completion Notes

- Implemented: state-owned facing; dedicated modular sidearm/upper-FX resources; four-diagonal synchronized lower/upper/pistol/FX draw and fire; Operator-local layer alignment; draw-complete gating; held final draw pose; fire-to-held return; candidate selection that chooses the sidearm while melee/unarmed is selected even if a carbine is carried; and mutually exclusive sidearm presentation that hides the separate primary-ranged/carbine overlay and FX.
- Validated: modular runtime build, curated SpriteFrames rebuild, four-diagonal/timing/alignment `operator_modular_layers_smoke.gd`, `operator_ranged_ready_input_smoke.gd`, editor parse/scan, asset-tracker parity, and `git diff --check`.
- Deferred: missing production cardinal draw/fire and recover/reload coverage; existing headless resource-leak warnings remain.

## Next Steps

- Next action: supply cardinal draw/fire and recover/reload clips.
- Best starting files: `custodian/game/actors/operator/operator.gd`
- Required context: modular sidearm runtime sheets and ranged-ready state.
- Validation to run: curated resource rebuild and Operator modular/ranged-ready smokes.
- Blockers or open questions: none; pure cardinal aim currently resolves to the nearest authored diagonal.
