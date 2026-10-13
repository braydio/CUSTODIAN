# COMBAT ATTACK TELL–CONTACT ALIGNMENT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `combat-attack-tell-contact-alignment-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `enemy-runtime, operator-runtime, combat-feel`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-combat-attack-tell-contact-alignment-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: Changes to damage timing and parry counterplay require independent end-to-end falsification.
- Reviewed main: `c4d150edec1ad60d3bc11336cad4333d60df384e`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Every live attack-capable actor presents a readable attack cue whose committed contact/damage phase agrees with gameplay timing; legal parries can actually intercept parryable threats.
- Completion boundary: One shared attack cue/contact invariant, applied at existing per-actor/ability timing owners where needed, with an enumerated audit of **all live damaging actor paths**, focused regressions and no redundant combat controller. This is not an animation-system or combat-balance rewrite.
- Current measured state: The 2026-10-13 Dev Observatory death trace attributes a lethal `GRUNT` ordinary melee attack (`1723976396055:9`) for 8.35 damage at 25.47 px, spatially valid; it does not establish a visible swing. `StandardEnemyMelee.tick()` applies the contact test when its independent timer expires, not at a verified presentation contact marker. IMPORTANT: the GRUNT SCENE override is **0.42 s**, NOT the base config's 0.10 s; Marine 0.45 s, Savage 0.26 s, Pursuit Frame 0.46 s. The GRUNT's authored normal clips vary (7–9 frames at 12 FPS). Operator parry config has 0.16667 s windup + 0.10 s active, so a late/invisible tell makes interception unreliable.
- Evidence: `custodian/game/actors/enemies/combat/{standard_enemy_melee.gd,standard_enemy_melee_config.gd,configs/standard_enemy_melee_{grunt,marine,savage,pursuit_frame}.tres}`; `custodian/game/actors/enemies/{enemy.gd,abilities/{savage_chain,savage_pounce,marine_dash,grunt_falcon_punch}.gd,presentation/enemy_presentation_controller.gd,presentation/sets/enemy_grunt_animation_set.gd}`; `custodian/game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd`; `custodian/game/actors/operator/combat/operator_guard_config.gd`; `custodian/tools/validation/{standard_enemy_melee_smoke.gd,enemy_hit_spatial_telemetry_smoke.gd,operator_guard_flow_smoke.gd}`; `design/02_features/{combat_feel/COMBAT_FEEL_SYSTEM.md,animation/ENEMY_GRUNT_RUNTIME_WIRING.md}`.
- Task-specific authority: Existing attack-phase owners, guard/parry controller, combat spatial hit contract, per-actor animation set/presentation controller, and active Combat Feel design; no parallel damage or parry authority.
- Work surface: Primary: `game/actors/enemies/combat/standard_enemy_melee.gd` and its typed config; targeted adapters only where live audit confirms violations in `game/actors/enemies/abilities/`, `game/actors/ambient/vaultwing/`, and existing Operator/actor attack owners; their **specific** tests and `tools/iteration/changed_file_routes.json` / validation manifest when ownership changes. Keep `enemy.gd`/`operator.gd` thin.
- Change:
  1. **Inventory, then target:** In one compact table enumerate every live actor-generated damage path: GRUNT/Marine/Savage/Pursuit Frame ordinary melee; Savage chain and pounce, Marine dash, Falcon punch; Vaultwing ground/dive; Operator unarmed/armed melee, ranged muzzle/projectile; live turret/projectile and any other active attacking actor found in current source. Classify `telegraphed parryable contact`, `telegraphed collision/travel`, `projectile`, or explicitly intentional non-parryable/environmental. Name owner, cue origin, contact trigger, cancellation path, and proof. Audit first; modify only violating owners. Unimplemented/dormant attacks are out of scope but listed separately.
  2. **One gameplay phase contract:** A strike cannot resolve before its committed, successfully presented cue's authored contact moment. Prefer an actor/ability-owned **deterministic** elapsed-time or normalized-progress marker from the resolved animation/action profile, not `AnimatedSprite2D.frame` as physics authority. A missing/wrong directional clip must resolve a readable authored fallback or fail closed with a diagnostic, never silently hit. Do not force collision-driven dash/pounce or projectile impact to an arbitrary sprite frame: their contact remains physics-driven inside an explicitly telegraphed active phase. Preserve attack IDs, dodge/block/parry priority, spatial range/arc and single-contact semantics.
  3. **First repair ordinary melee:** Align phase transitions and `_execute()` to the real resolved attack cue and configurable impact marker; guarantee cue visibility until contact or cancellation (no ordinary idle/flavor/recoil presentation silently replacing a committed strike unless gameplay also interrupts it). Preserve committed-facing/tracking lock, strong opening attack, target-loss whiff, recovery and redecision. Do not replace scene overrides with the generic 0.10 s default or simply delay to the animation's final frame.
  4. **Parryability:** For each declared parryable hostile attack, expose a testable cue-to-contact interval and ensure >= **0.40 s** from first actually readable tell to earliest contact, unless a stricter locked per-ability design requires an explicitly documented, clearly telegraphed exception. Keep the Operator's existing guard/parry clocks unchanged. Preserve distinct special-attack commitment, travel and cancel windows. Make timing tunable via existing typed profiles/resources, not actor `if` ladders. Never retroactively damage after a successful parry/cancel.
  5. **Targeted actor coverage:** Reconcile special-attack and Vaultwing phase/cue paths with the invariant; patch only violations. Verify Operator melee's existing frame/profile hit windows and ranged fire cues rather than replacing them; projectile/turret damage stays actual collision/shot-driven. If a new actor type cannot be safely aligned within the shared contract, fail closed for the relevant attack and record an exact bounded follow-up rather than implementing a second architecture.
  6. **Proof without log spam:** On attack begin and terminal contact/whiff/cancel, correlate `attack_id`, actor/ability, presented action/clip/fallback, elapsed cue-to-contact, active phase, impact marker, and result. Reuse observatory event types where possible; no per-frame logging or new observability dashboard.
- Preserve: Existing attack damage and weapon identity, damage types, range/arc/grace, target choice and lock, guard/parry/riposte logic, stagger/critical branches, dash collision physics, ranged muzzle/projectile behavior, player fast-chain cadence, animation asset paths, and existing attack interruption rules. The user's dirty coordination `operator.gd` must not be overwritten; work only through an isolated claimed worktree.
- Non-goals: No new sprites/FX/SFX, blanket speed nerf, general parry-window expansion, AI/Director overhaul, combat authority extraction, retargeting rewrite, renderer-driven physics, or unrelated game-feel polish.
- Acceptance:
  - A1. Every active actor damage emitter is accounted for in a compact coverage matrix, with exact contract verdict and test; none silently skipped.
  - A2. For ordinary melee, all four configured enemy profiles resolve a visible attack cue, legal contact only at/after its authored impact marker, and exactly one terminal result per ID; facing/target loss/whiff/cancellation behave as before.
  - A3. Each parryable attack presents >=0.40 s of actual readable warning before earliest contact (or records a documented design exception); simulate guard-ready and parry input 0.15 s after cue and prove success is mechanically possible at the legal contact frame.
  - A4. Special abilities, Vaultwing, Operator melee and shot/projectile/turret paths either satisfy the same relevant timing invariant unchanged or have bounded verified fixes. Travel/collision attacks are never converted to distance-free damage.
  - A5. No damage after cancellation/parry/death, duplicate hit across large `delta`, missing-clip invisible hit, attack-clip interruption mismatch, or off-arc/out-of-range result becomes damaging.
  - A6. The lethal GRUNT reproduction at 25.47 px produces a recorded, visible committed strike before damage. Simulate low FPS/hitch frames (>=0.24 s) and confirm determinism without skipped or duplicated phases.
  - A7. No substantial `enemy.gd`/`operator.gd` growth, no new assets, no per-frame telemetry; preserved affected regressions and one final changed-file suite pass.
- Validation: First one new deterministic Godot `tools/validation/attack_tell_contact_alignment_smoke.gd` covering actor matrix, cue timing, late/missing clips, contact/cancel/parry/whiff and low-FPS. Reuse only directly relevant `standard_enemy_melee_smoke.gd`, `enemy_hit_spatial_telemetry_smoke.gd`, `combat_exchange_commitment_smoke.gd`, `operator_guard_flow_smoke.gd`, plus existing specific Savage/Marine/Falcon/Vaultwing and Operator timing smokes for touched owners. Minimal frame-index/clip evidence before a single short Moment Forge clip if pixels cannot otherwise verify readability. Then once: `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`.
- Task overrides: `none`
- Deferred: Subjective tuning, attack art enhancement and genuinely dormant actor abilities require separate work; this packet must report such exclusions explicitly.

## Handoff

- Next workstream: `review-combat-attack-tell-contact-alignment-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: On fetched main, check for equivalent active work, run targeted authoring preflight on this packet plus its review, promote both from `draft/manual` to `ready/auto` only after ownership/preflight, publish through the sanctioned workflow, then claim only if dispatcher eligible. Implement with compact actor matrix, targeted tests, and a fresh independent review.
- Blockers or open questions: Review current actor workstream locks before promotion; current `agent-workflow` blocker is unrelated to this packet's combat locks. Current chat URL not recorded.