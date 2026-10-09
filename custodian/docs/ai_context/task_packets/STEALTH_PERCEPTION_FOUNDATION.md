# STEALTH PERCEPTION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `stealth-perception-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `stealth-perception, enemy-runtime, vaultwing-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-stealth-perception-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `cross-family perception authority extraction and live typed-boundary repair; independent review should falsify behavioral drift and accidental behavior-policy centralization`
- Reviewed main: `0c80f6a5a1c64168a39b841fa5de362d98728664`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Make Enemy and Vaultwing consume one typed receiver-side acoustic perception seam so hearing is a shared stealth/perception capability rather than duplicated species/runtime behavior.
- Completion boundary: This slice owns S0 plus the narrowest S1 acoustic seam from `STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`: type `NoiseEvent` end-to-end, introduce one typed receiver-derived observation/evaluation contract, move only demonstrably shared acoustic evaluation out of Enemy/Vaultwing consumers, migrate both live consumers, and add deterministic focused validation. It does not own broader vision extraction, expanded emitters, alarms, normal-play awareness UI, material footsteps, acoustic occlusion, Vaultwing behavior redesign, or NPA-8.
- Current measured state: `NoiseEvent` is a concrete RefCounted class but its factory/bus surface is weakened to `Variant`; `NoiseEventBus.noise_emitted` and `emit_noise/emit_at` accept/return Variant; `EnemyPerceptionComponent` reads event fields through dynamic `get()`; `VaultwingBehaviorController` directly subscribes to the bus and carries species-local acoustic handling around a single `awareness_radius=560` profile value. The stealth design records a real Vaultwing gunshot-handler contract defect and explicitly names Enemy + Vaultwing as the two consumers that justify the first shared acoustic seam. Enemy blackboard/behavior and Vaultwing species behavior are separate authorities and must remain so.
- Evidence: `design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `custodian/game/systems/stealth/noise_event.gd`; `noise_event_bus.gd`; `custodian/game/actors/enemies/components/enemy_perception_component.gd`; `enemy_behavior_profile.gd`; `custodian/game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd`; `vaultwing_behavior_profile.gd`; current focused ranged/noise, Enemy, Vaultwing, relationship and simulation-tier validation.
- Task-specific authority: `design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md` owns sensory architecture; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md` owns actor-family/facet boundaries; current weapon noise tuning remains owned by the ranged/combat-feel authority.
- Work surface: `custodian/game/systems/stealth/`; Enemy perception/profile adapter surface; Vaultwing behavior/profile acoustic consumer seam; the smallest new typed observation/profile/service files required by S0/S1; focused validation and manifest ownership; consequence-driven active docs only.
- Change: Type `NoiseEvent` through creation, bus signal/public methods, and consumers. Introduce the smallest typed receiver-side acoustic observation/evaluation seam that both Enemy and Vaultwing genuinely share. The emitted event owns source facts; receiver evaluation may own range/sensitivity/distance attenuation, source qualification, channel/kind, salience/certainty and deterministic diagnostic identity. Enemy consumes the observation to preserve its existing suspicion/investigation/search behavior; Vaultwing consumes the same observation and maps it through its species-local policy. Keep relationship qualification explicit after sensing so hearing an ally/neutral stimulus never automatically means hostile targeting. Move shared receiver tuning into a focused perception profile only where both consumers prove the field; do not migrate unrelated Enemy or Vaultwing behavior tuning for architectural neatness.
- Preserve: Current weapon-authored noise radius/loudness/threat/suppression values; Enemy LOS/detection thresholds/investigation/search/leash outcomes for equivalent stimuli; Vaultwing wild/bonded species behavior, dive/bait/bond policy and tuning; fixed-step/simulation-interest cadence; relationship resolver semantics; no psychic map-wide alert; no normal-play UI mutation.
- Non-goals: No alarm network; no cameras/microphones; no footsteps/material acoustic gameplay; no expanded noise emitters; no general vision-cone framework unless strictly necessary to support the shared acoustic type; no species behavior migration; no Vaultwing runtime/bond hardening beyond the acoustic consumer adaptation; no NPA-8 convergence.
- Acceptance: (1) live acoustic paths use a typed `NoiseEvent` boundary and no production acoustic consumer treats the event as a Dictionary/weak Variant contract; (2) Enemy and Vaultwing receive one typed receiver-derived acoustic observation/evaluation result; (3) identical in-range/out-of-range/self-source fixtures deterministically agree at the shared sensing layer; (4) relationship/source facts are available without turning sensing into hostility; (5) equivalent player gunshot input preserves Enemy suspicion/investigation/search outcomes; (6) Vaultwing receives the same event without a separate acoustic-distance model or Object/Dictionary arity failure; (7) BONDED/operator-allied Vaultwing does not reacquire Operator hostility merely from hearing Operator gunfire; (8) shared stealth code owns no Enemy/Vaultwing behavior state or target-selection policy; (9) validation ownership follows the new stealth files so future edits do not select unrelated giant actor suites.
- Validation: First add/extend the narrow real-event acoustic contract smoke that drives `NoiseEvent -> NoiseEventBus -> Enemy + Vaultwing`, including self-source, outside-envelope, neutral/allied relationship and bonded-Vaultwing cases. Then run the current Enemy perception/behavior regression selected by the manifest, `vaultwing_runtime`, `actor_relationship_contract`, and directly affected ranged/noise checks. Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: S2 expanded emitters/material response; S3 alarms; S4 awareness UI/readability; S5 occlusion/environment masking; S6 wider cross-family adoption; Vaultwing fixed-step/bond/compatibility hardening belongs to the next packet; NPA-8 remains separately refresh-gated.

## Handoff

- Next workstream: `review-stealth-perception-foundation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: After this implementation lands, continue autonomously into its fresh-context paired review.
- Blockers or open questions: `none; current enemy-runtime lock holders may delay claim but do not change packet readiness`
