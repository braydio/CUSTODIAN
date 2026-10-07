# STEALTH PERCEPTION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `stealth-perception-foundation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `none`
- Locks: `stealth-perception`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `ba04d9e8ee`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Close the live typed-noise defect and establish one shared acoustic perception seam for ordinary enemies and Vaultwings so hearing is a stealth-system capability rather than species-local behavior.
- Completion boundary: This workstream owns S0 and the narrowest S1 acoustic seam from `STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`: typed `NoiseEvent` propagation, receiver-side acoustic evaluation/observation, Enemy adoption, Vaultwing adoption, and focused deterministic validation. It does not own expanded emitters, visual-cone extraction beyond what is required for a coherent shared profile, alarm networks, player awareness UI, material footsteps, acoustic occlusion, or species behavior redesign.
- Current measured state: On reviewed main, `NoiseEvent` is a real RefCounted class but its factory returns `RefCounted`; `NoiseEventBus` signals and returns `Variant`; `EnemyPerceptionComponent` consumes the object through string-key `get()`; and `VaultwingBehaviorController._on_noise_emitted()` uses Dictionary-only two-argument `get(key, default)` semantics, producing the reported runtime error when a real Operator gunshot reaches a HIGH Vaultwing. Enemy receiver tuning already includes vision/hearing range and detection thresholds, while Vaultwing has a separate awareness radius with direct bus handling.
- Evidence: `custodian/game/systems/stealth/noise_event.gd`; `noise_event_bus.gd`; `custodian/game/actors/enemies/components/enemy_perception_component.gd`; `enemy_behavior_profile.gd`; `custodian/game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd`; `vaultwing_behavior_profile.gd`; `custodian/tools/validation/ranged_combat_balance_smoke.gd`; `vaultwing_runtime_smoke.gd`.
- Task-specific authority: `design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`; current weapon-noise tuning remains owned by `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`; actor-family boundaries remain owned by `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Work surface: `custodian/game/systems/stealth/`; Enemy perception/profile consumer; Vaultwing behavior/profile consumer; focused noise/Enemy/Vaultwing validation; consequence-driven active docs only.
- Change: Type `NoiseEvent` end-to-end; introduce the smallest typed receiver-side acoustic observation/evaluation seam justified by Enemy + Vaultwing; keep emitted facts separate from receiver-derived salience; make self-source rejection, distance attenuation, receiver sensitivity, source identification, and relationship qualification explicit; preserve Enemy investigation/search behavior; route Vaultwing acoustic interest through the shared evaluation instead of duplicating acoustic math; add real-event focused regression coverage.
- Preserve: Current weapon-authored noise radius/loudness/threat values; suppression behavior; Enemy vision cone/LOS/detection/search/leash outcomes; Vaultwing species-local state machine and attack/bond policy; fixed-step simulation authority; relationship resolver semantics; current simulation-interest/perception cadence.
- Non-goals: No alarm network; no camera/microphone device; no footstep/material gameplay noise; no normal-play detection HUD; no weather/occlusion acoustics; no global attention meter; no NPA-8 species refactor; no Vaultwing bond/runtime hardening unrelated to hearing.
- Acceptance: The reported Vaultwing gunshot path cannot throw an Object.get arity error; no live acoustic consumer treats `NoiseEvent` as a Dictionary; Enemy and Vaultwing use one shared receiver-side acoustic evaluation contract; self/out-of-envelope stimuli are ignored; neutral/non-hostile stimuli do not automatically become hostile actor targets; current Enemy investigation/search behavior remains equivalent for the same weapon event; BONDED Vaultwing does not reacquire Operator hostility from nearby gunfire; focused tests are deterministic.
- Validation: Extend existing focused noise smoke with the typed contract; run the existing Enemy perception/behavior smoke selected by changed ownership; run `vaultwing_runtime`; run `actor_relationship_contract` if relationship qualification changes; close once with `python3 custodian/tools/validation/run_validation.py --changed --json`.
- Task overrides: `none`
- Deferred: S2 expanded acoustic emitters/material response; S3 alarm network and sensors; S4 player awareness/readability; S5 occlusion/environment masking; S6 wider actor adoption; Vaultwing non-hearing runtime hardening remains a separate dependent packet.

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Bring the landed predecessor/review evidence and any material live-main drift back to this conversation. Re-derive the packet here with the user before promoting it to implementation-ready; do not let the execution agent silently reinterpret architecture, scope, sequencing, or acceptance.

## Handoff

- Next action: reproduce the real Operator gunshot -> NoiseEventBus -> Vaultwing path in focused validation, then repair the typed shared boundary before extracting receiver math.
- Best starting files: `noise_event.gd`, `noise_event_bus.gd`, `enemy_perception_component.gd`, `enemy_behavior_profile.gd`, `vaultwing_behavior_controller.gd`, and focused noise/Vaultwing validation.
- Blockers or open questions: packet remains draft/manual until the design draft is accepted for implementation.