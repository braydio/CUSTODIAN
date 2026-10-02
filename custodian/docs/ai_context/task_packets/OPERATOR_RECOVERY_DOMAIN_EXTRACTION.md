# OPERATOR RECOVERY / SURVIVABILITY DOMAIN EXTRACTION — SLICE F6

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-recovery-domain-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine, custodian-death-handoff-foundation`
- Locks: `operator-runtime, custodian-death-flow`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `931b830d54f2a217d1b473109f708636ac89f21f`
- Goal: Extract Operator damage/recovery/Field Patch survivability behavior into explicit authorities and make the movement-permissive Field Patch animation reflect its real 35% movement contract without weakening committed damage/death presentation.
- Completion boundary: Done when incoming damage/death lifecycle and recovery/consumable behavior no longer live as one actor-local flag cluster; focused damage and recovery authorities own their respective state; existing `OperatorIntegrityReclaim` is consumed rather than duplicated; public health/Field Patch APIs delegate; moving Field Patch uses locomotion lower + upper patch action/FX while stationary use retains authored paired body; the heal commit has an explicit presentation event/beat without becoming timing authority; and damage reactions/death remain committed where gameplay locks movement.
- Current measured state: Field Patch uses a 1.25s vulnerable window, commits 35% max-health healing, preserves the patch if interrupted before commit and slows movement to 35%; movement remains legal during use. Canonical E/W `field_patch_use_01` publishes 14-frame 96x96 lower+upper+FX at 11.2 FPS, while the current presentation plays the paired lower+upper action even when the actor moves. Light hit recoil is a committed 0.22s damage action; heavy knockdown/death are full-body committed reactions. `OperatorIntegrityReclaim` already owns deterministic reclaim-packet math. Death handoff is being changed by the separate persistent-recovery R1 packet and must land before this extraction.
- Evidence: Field Patch/damage/death functions in `operator.gd`; `operator_integrity_reclaim.gd`; Field Patch and damage-reaction design docs; `field_patch_smoke.gd`; modular/light/heavy reaction tests; death-handoff packet.
- Task-specific authority: combat resource/readability authority; Integrity Reclaim authority; persistent recovery/death handoff authority; Operator runtime architecture; canonical animation authority.
- Work surface: Focused damage authority under `game/actors/operator/combat/` and recovery/consumable authority under `game/actors/operator/interaction/` or the nearest established Operator boundary; actor facade; semantic presentation controller; health/HUD status consumers; focused validation.
- Change:
  1. Separate damage intake/reaction/death coordination from recovery/consumable state. Do not create one new god-controller: damage authority owns incoming health/damage/death decisions; recovery authority owns Field Patch/reclaim-facing recovery state.
  2. Reuse the existing `OperatorIntegrityReclaim` helper as the reclaim math authority and expose it through the recovery boundary; do not clone packet timers or source-efficiency logic.
  3. Preserve the newly landed campaign-level death handoff exactly. Extraction may delegate it but must not restore actor-owned lives/Game Over semantics.
  4. Field Patch moving presentation: while movement is legal/nonzero, keep lower locomotion identity/direction/progress and play only upper `field_patch_use_01` + FX; stationary use keeps the authored lower+upper+FX pair. Lower speed/cadence should visually correspond to the actual reduced movement contract without making animation speed the gameplay authority.
  5. Add an explicit presentation-only patch commit event/semantic beat at the real gameplay commit instant. Prefer the existing authored frame/FX intensity if it reads clearly; do not move heal application to an animation callback. If the existing strip cannot make commit legible, record a bounded FX asset requirement rather than inventing simulation delay.
  6. Preserve interruption semantics: damage, attack, dodge, reload, death, UI/runtime locks and field-work cancellation before commit still preserve the patch; post-commit cleanup remains exactly once.
  7. Keep light damage reaction, heavy knockdown and death as committed paired/full-body presentations while movement is locked. Do not put locomotion under reactions merely to maximize modularity.
  8. Remove actor-local duplicate health/recovery lifecycle flags only after facade APIs/signals and HUD consumers delegate to the new authorities.
- Preserve: max health/tuning, Field Patch count/cap/heal/use duration/movement multiplier, reclaim math and eligibility, damage taxonomy, hit-stop, reaction durations, death animation/telemetry/handoff, HUD contract, fixed tick.
- Non-goals: No passive regeneration. No Field Patch balance change. No new death/revive design. No mobile damage reaction. No new patch body art. No inventory/fabrication redesign.
- Acceptance: Damage/recovery state has explicit non-overlapping owners; death handoff remains exactly once; all existing health/reclaim/Field Patch tests pass; moving patch no longer slides a planted lower action while translating; stationary patch retains authored pose; lower cadence persists without phase churn; heal occurs from gameplay time exactly as before and commit presentation cannot cause/delay it; committed reactions remain full-body/paired.
- Validation: Add focused controller ownership/state tests, run `field_patch_smoke.gd`, `operator_integrity_reclaim_smoke.gd`, light/heavy damage/knockdown/death regressions and the death-handoff tests. Use deterministic frame/progress and commit timestamp assertions first; one tight Field Patch moving evidence capture is justified for cadence/readability after logic is green. One changed-file closeout.
- Task overrides: `none`
- Deferred: Any new commit FX needed after review goes to Asset V2 with an explicit family/state requirement. Persistent Crèche/Post recovery remains on its separate roadmap.

## Handoff

- Next action: Wait for death-handoff R1, extract damage/recovery ownership, then change only Field Patch presentation using the shared movement-permissive seam.
- Best starting files: damage/death/Field Patch regions of `operator.gd`; `operator_integrity_reclaim.gd`; presentation controller; focused health/recovery tests.
- Blockers or open questions: Dependency on `custodian-death-handoff-foundation` is intentional so this packet extracts the new death truth rather than the old GameState compatibility path.
