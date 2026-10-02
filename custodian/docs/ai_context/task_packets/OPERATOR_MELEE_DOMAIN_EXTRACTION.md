# OPERATOR MELEE DOMAIN EXTRACTION — SLICE F2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-melee-domain-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `931b830d54f2a217d1b473109f708636ac89f21f`
- Goal: Extract melee timeline/drive/target/contact state into one focused authority and cash in the existing modular art where it genuinely improves moving combat presentation, while preserving authored whole-body footwork wherever that produces the stronger animation.
- Completion boundary: Done when fast/heavy chain lifecycle, buffering/commit timing, attack drive, hit-window/contact bookkeeping and melee target solution are owned behind an `OperatorMeleeController`-class authority; Operator public attack APIs remain thin delegates; unarmed/armed posture and moving-fast presentation use the semantic presentation layer; already-ingested moving-fast assets have a real runtime consumer where appropriate; and full-body committed attacks remain supported rather than being mechanically split.
- Current measured state: Melee gameplay/profile data is already largely centralized in `MeleeAttackProfile`, and Fists Fast 01-04 is a live modular E/W 6/6/7/8-frame chain with authored FX and presentation-duration ownership. Armed melee fast attacks still primarily use full-body+FX authority even though alternate lower/upper layers exist. Dedicated moving-fast melee body/weapon/FX strips were ingested previously and remain unwired. Armed melee locomotion is modular but uses one shared facing for lower/upper/weapon, and its direction/frame coverage is uneven (for example south run is 12f while E/W run is 6f). READY/RELAXED posture transitions are modular but stationary-only. The legacy `OPERATOR_UNARMED_FAST_CHAIN_CONSOLIDATION.md` work is functionally closed even though its header still says in progress.
- Evidence: melee functions in `operator.gd`; `MeleeAttackProfile`; weapon definitions; canonical manifest; archived moving-fast ingest packet; `operator_unarmed_fast_chain_smoke.gd`, `operator_attack_phase_cadence_smoke.gd`, `operator_melee_*_smoke.gd`, dagger/cleaver smokes.
- Task-specific authority: `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md`; combat feel/cadence docs; Operator runtime architecture; canonical animation authority.
- Work surface: New melee authority under `game/actors/operator/combat/`; actor facade; existing melee posture resolver/presentation helpers; semantic presentation controller; focused melee validation. Do not absorb loadout, guard, dodge or ranged state.
- Change:
  1. Move melee fast/heavy lifecycle, chain step/buffer/queue/commit state, active attack profile, attack-drive state, hit-window/contact bookkeeping and melee targeting solution into one coherent controller with narrow explicit dependencies.
  2. Keep deterministic combat timing/profile data authoritative. Presentation observes timeline facts; it does not decide damage windows or movement distance.
  3. Preserve current Fists Fast 01-04 modular chain timing and authored lower/upper/FX. Do not replace authored attack lowers with generic walk simply because locomotion reuse is available.
  4. Wire the already-ingested specialized moving-fast body/weapon/FX assets into a semantic moving-attack presentation only for attack/profile states whose gameplay movement contract matches those authored pixels. Prefer this purpose-built art over a generic walk-under-swing shortcut.
  5. For armed melee locomotion/ready posture where independent facing is useful, allow movement-owned lower direction and combat/aim-owned upper+weapon direction only after complete required layers resolve. Synchronize differing frame counts by normalized cycle progress or an equally deterministic cadence mapping, not naive same-frame indexing.
  6. Let READY/RELAXED upper posture persist over lower locomotion where movement is legal and the composed seam is registration-clean. Stationary posture keeps its authored paired lower+upper+weapon silhouette. READY<->RELAXED bridges may run upper-only over lower cadence when that produces the same/better silhouette; fail closed to paired transition if not.
  7. Keep full-body heavy attacks, whole-body attack links with authored footwork, dodge-fast transition, critical execution and Falcon reversal as full-body when the lower pose is part of the action. Full-body is a first-class presentation mode, not legacy debt.
  8. Fold Vigil relaxed->ready and ready->Fast startup semantic coordination into the normal presentation/controller boundary where possible, retiring bespoke rig glue only after identical lifecycle/weapon visibility behavior is proven.
  9. Preserve visible-presentation clock semantics for queue/commit/hit windows and remove actor-local melee state only after controller ownership is complete.
- Preserve: damage/range/arc/knockback/hit-stop/camera values; four-link Fists cadence; target-assist behavior; collision-safe drive budgets; dagger/Cleaver semantics; stamina costs; parry/guard separation; public Operator attack APIs/signals; deterministic fixed tick.
- Non-goals: No attack balance retuning. No new melee art in this packet. No generic arbitrary layer mixer. No conversion of committed full-body attacks purely to reduce file count. No loadout/ranged/dodge extraction.
- Acceptance: Melee lifecycle state has one controller owner; actor facade no longer independently remembers the same chain/drive/contact state; all current fast/heavy/targeting tests remain green; moving-fast runtime assets are either consumed by the exact intended profile/action or explicitly rejected with a recorded mismatch instead of left silently dormant; moving posture/armed strafe composition uses independent lower/upper direction without foot sliding or weapon desync; normalized-progress cadence handles unequal frame counts deterministically; committed actions retain their authored whole-body read.
- Validation: Controller-focused unit/smoke coverage for chain lifecycle/drive/contact state plus existing unarmed fast chain, attack phase cadence, modular fast attack, point-blank, low-FPS contact, soft targeting, melee posture/locomotion socket, dagger, Cleaver and body-ownership tests. Use deterministic frame/progress/registration checks before any renderer review. One short Moment Forge moving-melee scenario in evidence mode is justified for final footwork/readability because cadence + world translation must be judged together. Finish with one changed-file closeout.
- Task overrides: `none`
- Deferred: Missing directional/body art discovered by runtime review goes to `operator-modular-directional-coverage-closeout`; no pixel fabrication in this workstream.

## Handoff

- Next action: Extract controller ownership first, then migrate presentation call sites while their live behavior is characterized.
- Best starting files: melee lifecycle/drive/targeting regions of `operator.gd`; `MeleeAttackProfile`; melee posture resolver; presentation controller; focused melee smokes.
- Blockers or open questions: None.
