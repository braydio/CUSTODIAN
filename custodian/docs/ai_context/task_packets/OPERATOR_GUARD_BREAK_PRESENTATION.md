# OPERATOR GUARD BREAK PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-guard-break-presentation`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `operator-mobile-guard-composition, operator-unarmed-defense-source-promotion`
- Locks: `operator-runtime, operator-assets`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `1e28205778f3337b3d29f94f1fb311f3de754819`
- Goal: Give guard break its own committed, readable whole-body failure presentation, distinct from ordinary non-breaking recoil, without weakening the existing movement lock or letting raw generated source-work bypass Asset Pipeline V2.
- Completion boundary: Done when `GUARD_BREAK` selects a dedicated canonical `block_break_01` full-body action with a dedicated break FX beat, `BREAK_RECOVERY` selects a dedicated canonical `block_break_recovery_01` full-body recovery, the existing impact lock/recoil/vulnerability/re-raise timing remains simulation authority, Asset Pipeline V2 source/runtime/provenance is complete, and ordinary non-breaking guard recoil continues through the mobile-guard composition contract.
- Current measured state: `OperatorGuardController` already models `GUARD_BREAK/BREAK_RECOVERY` separately and `guard_on_break()` applies the enemy-impact movement lock, so guard break must remain a committed whole-body action. Latest main now contains raw east-facing source-work candidates at `custodian/asset_drop/source_work/operator/unarmed_defense_10_generated/operator__full_body__unarmed__defense__block_break_01__e__3f__96.png` and `...block_break_recovery_01__e__6f__96.png`. `temp/ASSET_MANIFEST.json` measures both raw files at **2172×724 RGBA with alpha**, so they are not runtime-ready despite their semantic filenames. No dedicated guard-break FX candidate exists in that ten-file body set. Runtime still lacks canonical `block_break_01` / `block_break_recovery_01` production identities.
- Evidence: `operator_guard_controller.gd`; guard-break branches in `operator.gd`; current canonical Operator manifest/reachability; `operator_guard_flow_smoke.gd`; `OPERATOR_MOBILE_GUARD_COMPOSITION.md`; `OPERATOR_UNARMED_DEFENSE_SOURCE_PROMOTION.md`; `temp/ASSET_MANIFEST.json`.
- Task-specific authority: combat-feel guard contract; `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; Source Session/Operator registration profile.
- Work surface: Approved normalized guard-break body/recovery source from the source-promotion workstream; one new dedicated guard-break FX family through Asset Pipeline V2; canonical runtime publication; semantic guard-break presentation request; focused guard validation.
- Change:
  1. Keep guard break committed. Do **not** reuse the movement-owned lower-body composition used by ordinary enter/hold/non-break recoil/exit.
  2. Consume the approved production-normalized body source only after `operator-unarmed-defense-source-promotion` has completed. Expected accepted east body outputs are:
     - `custodian/asset_drop/inbox/operator/operator__full_body__unarmed__defense__block_break_01__e__3f__96.png` -> **288×96**
     - `custodian/asset_drop/inbox/operator/operator__full_body__unarmed__defense__block_break_recovery_01__e__6f__96.png` -> **576×96**
     Both are 96×96-cell RGBA/true-alpha, non-looping.
  3. Create the missing dedicated guard-break FX as a separate Asset V2 family, keyed to the 3-frame break contact/collapse clock unless the reviewed art source establishes a different exact frame contract:
     - `custodian/asset_drop/inbox/operator/operator__fx__unarmed__defense__block_break_01__e__3f__96.png` -> **288×96**
     - W counterpart only after reviewed counterpart authoring/registration.
     If the FX authoring pass proves a different frame count is materially better, update this packet and the semantic clock contract before publication rather than silently mismatching body/FX clocks.
  4. Asset-family schema: owner `operator`; profile `unarmed`; group `defense`; actions `block_break_01|block_break_recovery_01`; direction `e|w`; layer `full_body|fx`; frame size `96x96`; frame counts `3` for break and `6` for break recovery; loop `false`; timing remains presentation-only and may not redefine gameplay break/recovery timers.
  5. Publish through the Operator Asset V2 adapter into canonical source/runtime under `custodian/content/sprites/operator/{source,runtime}/animations/unarmed/defense/<action>/`. Preserve inbox/archive/source/runtime receipts and generated manifest/reachability truth.
  6. Wire `GUARD_BREAK` to `block_break_01` and `BREAK_RECOVERY` to `block_break_recovery_01` through semantic selection/presentation. Gameplay break timer, vulnerability, recoil velocity, re-raise lockout, posture/stamina consequence and control return remain controller-owned.
  7. The body is a single committed full-body owner for break/recovery. FX is an owner-scoped overlay. Never show modular locomotion lower beneath it and never split the raw full-body source merely to reuse the movement compositor.
  8. Do not runtime-mirror a canonical E identity to produce W. Publish a reviewed W counterpart only through the active Operator counterpart/registration policy.
  9. On missing/incomplete canonical break/recovery art at runtime, fail closed to the existing complete break-compatible fallback instead of showing half a body, skipping body ownership, or borrowing raw source-work.
- Preserve: guard simulation, movement lock, vulnerability, break recovery/re-raise timing, parry behavior, mobile non-break guard composition, fixed-step authority, existing body ownership firewall.
- Non-goals: No mobile guard break. No guard balance change. No generic damage-reaction refactor. No lower/upper locomotion composition during break. No direct use of 2172×724 source-work. No automatic art approval.
- Acceptance: Dedicated `block_break_01` body+FX and `block_break_recovery_01` body are Asset V2-clean and canonical; guard break visibly differs from ordinary non-break recoil; exactly one complete body owner is visible; break remains movement-locked; recovery/control return timing is unchanged; approved E/W presentation is registration-clean; raw source-work never appears in runtime; ordinary block-hit/parry regressions remain green.
- Validation: Source/Asset V2 exact-dimension/alpha/registration checks first; canonical manifest/reachability validation; guard-flow break timing, body-ownership and missing-art fallback negative controls; one short runtime-scale guard-break Moment Forge evidence capture for contact/collapse/readability after structured checks. Human approves subjective final art baseline. Finish with one changed-file closeout.
- Task overrides: `none`
- Deferred: This packet remains blocked until the body source-promotion packet is complete and dedicated break FX exists/reviewed. Directional expansion beyond approved E/W is not required here.

## Handoff

- Next action: Complete/review `operator-unarmed-defense-source-promotion` for the 3f break + 6f recovery body pair, then author the 3f break FX through Asset V2 and promote this packet to ready.
- Best starting files: raw source-work pair; Source Session registration profile; guard controller; presentation controller; Operator Asset V2 adapter; guard-flow smoke.
- Blockers or open questions: Raw body pixels now exist, but are not production-normalized; dedicated break FX does not yet exist.
