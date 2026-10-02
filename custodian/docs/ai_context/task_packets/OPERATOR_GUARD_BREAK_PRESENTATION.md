# OPERATOR GUARD BREAK PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-guard-break-presentation`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `operator-mobile-guard-composition`
- Locks: `operator-runtime, operator-assets`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `b252b5392aabaaa74f1203c3759a2584e6def726`
- Goal: Give guard break its own committed, readable whole-body presentation so the strongest defensive failure is visually distinct from ordinary non-breaking block recoil without weakening its movement lock.
- Completion boundary: Done when `GUARD_BREAK/BREAK_RECOVERY` selects a dedicated canonical unarmed break body+FX action, the existing impact lock/recoil/timing remains simulation authority, the full-body break hands back cleanly to the post-break neutral/guard lifecycle, Asset Pipeline V2 source/runtime/provenance is complete, and ordinary `block_hit_01` remains the lighter non-break response.
- Current measured state: `OperatorGuardController` already models guard break/break recovery separately and `guard_on_break()` applies an enemy-impact lock, so a mobile lower-body composition would be incorrect. Runtime currently lacks a dedicated unarmed `block_break_01` body/FX identity; the existing guard presentation family covers enter/hold/hit only. This packet is blocked on authored production pixels rather than on runtime design.
- Evidence: `operator_guard_controller.gd`; guard-break branches in `operator.gd`; canonical Operator manifest; `operator_guard_flow_smoke.gd`; mobile-guard packet.
- Task-specific authority: combat feel guard contract; Operator runtime animation authority; `design/04_architecture/ASSET_PIPELINE_V2.md`.
- Work surface: New Operator defense source art through Asset Pipeline V2, canonical runtime publication, guard-break semantic presentation request, focused guard validation.
- Change:
  1. Author/review one committed guard-break action whose readable sequence is contact -> guard collapse/loss -> recoil/fall-off -> recovery handoff. Do not use lower locomotion during break.
  2. Initial Asset V2 handoff names, if E/W are independently authored, are:
     - `custodian/asset_drop/inbox/operator/operator__full_body__unarmed__defense__block_break_01__e__6f__96.png`
     - `custodian/asset_drop/inbox/operator/operator__fx__unarmed__defense__block_break_01__e__6f__96.png`
     - W equivalents with `__w__` when the silhouette/FX is not safely counterpart-derived.
     Each proposed strip is 6 frames of 96x96, therefore 576x96 RGBA with true alpha, non-looping.
  3. Asset-family schema: owner `operator`; animation profile `unarmed`; action group `defense`; action `block_break_01`; direction `e|w`; layer `full_body|fx`; frame size `96x96`; frames `6`; loop `false`. Humans stage reviewed source; canonical runtime names/paths are generated, not hand-authored.
  4. Publish through the Operator Asset V2 adapter into canonical source/runtime under `custodian/content/sprites/operator/{source,runtime}/animations/unarmed/defense/block_break_01/`. Preserve ingest receipts/archive/provenance.
  5. Wire `GUARD_BREAK/BREAK_RECOVERY` to the dedicated action through semantic selection/presentation. Gameplay break timer, vulnerability, recoil velocity, re-raise lockout and stamina/posture consequences remain controller-owned.
  6. Do not derive/mirror a counterpart automatically unless the reviewed Operator counterpart policy proves registration/silhouette/FX safe. A time-saving mirror that degrades the break read is not acceptable.
  7. On missing/incomplete action at runtime, fail closed to the current complete break-compatible presentation rather than half-rendering.
- Preserve: guard simulation, break lock, vulnerability, recovery timing, parry, mobile non-break guard composition, fixed-step authority.
- Non-goals: No mobile guard break. No guard balance change. No generic damage-reaction refactor. No lower/upper split merely to reuse locomotion.
- Acceptance: Dedicated body+FX is Asset V2-clean and canonical; guard break visibly differs from ordinary block hit; exactly one complete body owner is visible; break remains movement-locked; recovery/control return timing is unchanged; E/W presentation is registration-clean; ordinary block-hit and parry regressions remain green.
- Validation: Asset V2 plan/status/doctor and alpha/frame/canvas/registration checks first; canonical manifest/reachability validation; guard-flow break timing and body-ownership negative controls. One short runtime-scale guard-break Moment Forge evidence capture is justified for contact/collapse/readability after structured checks. Human approves subjective final art baseline. One changed-file closeout.
- Task overrides: `none`
- Deferred: unblock only after reviewed production body/FX source exists in the asset-drop workflow.

## Handoff

- Next action: Supply/review the 576x96 E body+FX source pair (and W if independently authored), then change Status to ready and run normal Asset V2 + runtime wiring.
- Best starting files: guard controller; presentation controller; Operator asset schema/ingest; guard-flow smoke.
- Blockers or open questions: Production `block_break_01` body/FX pixels do not yet exist.
