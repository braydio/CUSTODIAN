# AWAKENING INTERACTION FEEDBACK + CRÈCHE CONSOLE ACTIVATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interaction-feedback-console-activation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-awakening-room-connectors-polish`
- Locks: `awakening-runtime, gameplay-hud-interaction-prompts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-interaction-feedback-console-activation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `218df82e2e5d8241cb349c21c05f0439570948a4`
- Visual review: `none`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Restore readable interaction feedback in Awakening by making proximity prompts persist for the full time an interaction target is valid, making one-shot/readout feedback remain legible instead of disappearing after a few process frames, and wiring the already-ingested 8-frame Crèche console activation FX so the opening console visibly responds on first acknowledgement.
- Completion boundary: Done when Awakening continuously presents the current valid interaction target, clears the prompt promptly when the target becomes invalid/out of range or the HUD context is suppressed, preserves a readable long-form readout/confirmation dwell without proximity refresh overwriting it, and the existing `awakening_creche_console_activation_fx/activate` 8-frame Asset V2 state visibly plays once at the Layout-owned Crèche console marker on first acknowledgement. No new art is created.
- Current measured state: The implementation now continuously presents the Operator's current actionable Awakening target and clears it when target/context validity is lost. The HUD's ordinary two-frame stale-prompt lease remains intact. `WorldReadoutInteractable` requests a HUD-owned minimum 4.0-second dwell; progression smoke observes the Crèche readout still visible after 3.76 seconds, verifies context suppression clears it, and verifies the current target prompt returns after dwell expiry. A focused HUD smoke confirms ordinary lease expiry, 120-frame target refresh, latch protection against ordinary/action prompts, four-second dwell progression, overlay suppression, and owner release. The live Awakening progression smoke verifies all eight activation frames were observed, configured at 8 FPS, stopped/hidden after playback, and not replayed on re-interaction; it also verifies reset rearms both console acknowledgement and effect. Before main advanced, changed-file validation passed all 20 selected tests with complete coverage. After syncing newer main, changed-file validation selected 22 tests and failed only `review_pairing_contract` because the newly landed `GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1` review packet has malformed review metadata; its unit-tier failure caused the remaining selected tests to skip. The task-specific progression, HUD, and Twin Solaria smokes were rerun against the synchronized tree and passed. Asset V2 doctor is healthy; status reports the activation PNG imported and 1/1 required, while static consumer binding remains unverified because runtime SpriteFrames are assembled by code.
- Evidence: `custodian/game/ui/hud/custodian_hud.gd`; `custodian/game/ui/components/black_reliquary_prompt.gd`; `custodian/game/actors/operator/operator.gd` interaction-target selection; `custodian/game/world/interactions/world_readout_interactable.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/content/metadata/assets/families/awakening_creche_console_activation_fx.asset.json`; runtime activation sheet; Sundered Keep's working per-frame prompt refresh as compatibility evidence.
- Task-specific authority: Operator `interaction_target`/interactable contract owns which target is actionable; gameplay HUD owns presentation only; `awakening_layout.gd` owns the console marker; Asset V2 family `awakening_creche_console_activation_fx` owns activation pixels/frame contract.
- Work surface: primarily `custodian/game/world/awakening/awakening_first_return.gd`, `custodian/game/world/interactions/world_readout_interactable.gd`, and the smallest necessary `custodian_hud.gd` API/lease change. Add focused Awakening/HUD validation; touch the activation Asset V2 family only to verify, not regenerate, its existing runtime state.
- Change:
  1. **Preserve target authority.** Do not create a second proximity scanner in HUD. Continue to use the Operator's existing `interaction_target` chosen by `_find_best_interactable()`.
  2. **Continuous proximity prompt in Awakening.** Add one Awakening prompt presenter/update path, called continuously while gameplay HUD context is active, that reads the current valid Operator target and refreshes the Black Reliquary prompt for as long as that target remains actionable. When target becomes null/invalid/out of range, hide the proximity prompt immediately. Do not special-case only the Crèche console; Transit Lift, Designation Locker, damaged port readout, and future standard interactables must follow the same contract.
  3. **Readable one-shot/readout priority.** Do not solve this by changing the HUD's two-frame safety lease to an arbitrary large global timeout. Preserve stale-prompt protection for frame-refreshed callers. Add an explicit latched/readout presentation path or equivalent priority contract so a one-shot readout/confirmation cannot be erased two frames later or immediately overwritten by the proximity refresh. Long-form readouts must remain legible for at least 4.0 seconds while HUD context remains active, unless the target is lost, gameplay overlay is suppressed, or a higher-priority modal UI opens. After the dwell expires and the target is still valid, return to its proximity prompt.
  4. **Generic WorldReadout compatibility.** Keep `WorldReadoutInteractable` simulation state/UI-independent. It may request the latched HUD presentation through a narrow presentation API, but must not own HUD timers. Preserve Twin Solaria and other existing readout consumers. The existing `AwakeningPlaqueInteractable.prompt_body` field is currently dead; either wire it cleanly into the proximity prompt body or remove/deprecate it rather than leaving another false contract.
  5. **Console activation FX wiring.** Preload/resolve the existing Asset V2 runtime sheet `awakening_creche_console_activation_fx__fx__effect__activate__omni__8f__128.png`. Build one non-looping `AnimatedSprite2D` presentation at Layout marker `creche_console = (112,144)`, with 8 atlas frames of 128×128 at exactly 8 FPS. Keep it hidden/stopped before activation, place it on the world-prop/effect presentation layer so it reads over the room art without covering the Operator, and do not add collision.
  6. **Play exactly once per real acknowledgement.** On the first `_on_console_acknowledged()`, restart frame 0 and play the full 1.0-second activation animation. Hide/stop on `animation_finished`. Re-reading an already-acknowledged console must not replay the activation effect. Preserve the existing recovery-alcove wake, objective update, status lines, and `console_acknowledged` signal.
  7. **Do not duplicate baked console art.** The requested fix is the activation effect. Do not bind the separate idle console world-prop sprite unless live scene evidence proves the production underlay does not already contain the console. Avoid double-rendering a baked prop.
  8. **Reset/debug truth.** If `reset_progression()` is expected to re-arm the opening console in the debug tour, reset both the interactable acknowledgement and activation-FX state together; otherwise document the persistent acknowledgement behavior. Do not leave controller state and interactable state contradictory.
  9. **Validation.** Add focused runtime proof for: prompt remains visible for >=120 rendered frames / >=2 seconds while target remains valid; prompt clears within a bounded frame count after target loss; a long readout survives >=4 seconds without proximity overwrite; modal/context suppression still hides it; console activation renders all 8 frames at 8 FPS once; second interaction does not replay; progression and recovery-alcove behavior remain unchanged.
  10. **Documentation drift.** Correct `awakening_runtime_ingest_status.md`/CURRENT_STATE/FILE_INDEX wording that currently implies the console activation FX already loads through the live runtime route. Asset registration existed; presentation wiring did not.
- Preserve: existing Black Reliquary prompt component styling; Operator interaction selection/range logic; existing Sundered Keep prompt behavior; Twin Solaria readout behavior; Crèche console gameplay acknowledgement semantics; recovery alcove wake; objective/progression; all existing Asset V2 IDs and source pixels.
- Non-goals: No prompt UI redesign; no new console art; no regenerated activation FX; no input-binding redesign; no generic interaction-system rewrite; no connector/spine geometry changes; no modal dialogue system.
- Acceptance:
  - Standing within interaction range of an actionable Awakening target keeps its prompt continuously visible with no flicker for the full target-valid interval.
  - Leaving range/removing the target/context suppression clears the prompt deterministically and no stale prompt remains.
  - Crèche/port readout body text remains readable for at least 4.0 seconds and is not overwritten by the proximity prompt during that dwell.
  - The existing Crèche activation FX runtime sheet is scene/runtime-consumed and all 8 frames play at 8 FPS exactly once on first acknowledgement at the Layout-owned marker.
  - Re-interaction does not replay the activation effect; progression/status/recovery-alcove semantics are unchanged.
  - No duplicate baked console body art is introduced.
  - Existing Sundered Keep prompt-refresh behavior and generic WorldReadout consumers remain green.
- Validation: focused HUD prompt lease/latch smoke; Awakening progression smoke extended with console-FX frame/state assertions; one renderer-backed Crèche activation capture only if structural frame playback cannot prove visibility; generic WorldReadout/Twin consumer smoke if touched; Asset V2 status/doctor for the activation family; changed-file validation; `git diff --check`.
- Task overrides: `none`
- Deferred: broader HUD hierarchy/aesthetic redesign and generalized interaction presentation extraction remain separate work.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: focused HUD interaction lease/latch smoke; Awakening first-return progression smoke; Twin Solaria runtime smoke; changed-file validation with 20/20 selected checks passing and complete file coverage; Asset V2 doctor healthy; activation family status imported 1/1; `git diff --check` clean.
- Result: complete
- Remaining acceptance gaps: none
- Visual review evidence: not required; structured runtime checks observe all eight atlas frames and exact 8 FPS playback, plus visibility/stop/one-shot/reset state.

## Independent Review

- Status: `passed`
- Review workstream: `review-awakening-interaction-feedback-console-activation`
- Reviewed on main: `b0bc0956c4ce0510199b098d74691a39672df69a`
- Reviewed implementation commit: `81004eb98571d209b72cdbe0128d9042dc2dd752`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Reviewer independence: `The paired review used a newly claimed worktree and reconstructed the target from its archived implementation packet, summary, active Awakening design authority, Asset V2 evidence, source changes, and fresh focused validation. The reviewed implementation was not modified.`
- Evidence: `hud_interaction_prompt_lease` and `awakening_first_return_progression` passed; the latter held a valid target through 120 frames, observed the Crèche readout after 3.76 seconds, exercised context suppression and target loss, observed all eight FX frames at 8 FPS, checked once-only replay protection, progression/recovery behavior, and reset. The generic `twin_solaria_runtime` consumer passed. Sundered Keep's `_process()` still refreshes its valid target through `show_interaction`; HUD lease compatibility was independently exercised for 120 frames. Asset V2 status reports the existing activation PNG imported and 1/1 required; doctor is healthy. Runtime scene assertions prove dynamic SpriteFrames consumption/playback, which the static Asset V2 consumer index does not recognize.`
- Validation caveat: `The first direct smoke invocation in the fresh worktree failed before running because Godot had not generated its global class registry. After one headless editor initialization/import, the same focused validations passed. This was worktree setup, not a product defect.`

## Review Result

- Outcome: `passed`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed main: `b0bc0956c4ce0510199b098d74691a39672df69a`
- Reviewed implementation commit: `81004eb98571d209b72cdbe0128d9042dc2dd752`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Findings: `none`
- Focused evidence: `HUD prompt lease, Awakening progression/console FX, and Twin Solaria generic readout smokes passed; Asset V2 status is 1/1 imported and doctor healthy; git diff --check passed.`
- Review conclusion: `The current Operator interaction target remains the prompt authority; Awakening refreshes it continuously and clears it on invalidation or HUD suppression. The HUD retains ordinary stale-prompt expiry while owner-scoped readouts have a minimum four-second latch. The existing Asset V2 activation sheet is assembled at the Layout marker and all eight non-looping frames play once on first acknowledgement. Reinteraction and debug reset, readout compatibility, and recovery/progression behavior meet the packet contract.`
- Follow-up workstream: `none`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Review disposition: `passed`

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the first new progression test assigned a target only once, but Operator simulation correctly replaced that synthetic target; the first changed-file run exposed a missing manifest owner for the generic readout source. During finish, newer main caused a managed packet-index conflict, and the post-sync changed-file sweep found an unrelated malformed startup-integrity review packet and skipped the remaining tiers.
- Root cause / contributing factors: the test initially modeled the HUD input rather than maintaining Operator target authority; the validation manifest omitted the generic readout owner; and incoming main contained review metadata that violates the repository review-pairing contract.
- Prevention / pipeline improvement: the focused test now maintains a valid target or places the Operator within the real console range; the progression manifest explicitly owns `world_readout_interactable.gd` so changed-file coverage closes.
- Tooling / docs drift discovered: Asset V2 static status cannot recognize a runtime SpriteFrames binding assembled by code. The post-sync changed-file sweep also surfaces malformed metadata in the independently landed `GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1` paired-review packet.
- Follow-up: `manual-follow-up`
- What worked: focused runtime assertions exercised the readout, prompt, activation strip, acknowledgement, and debug-reset lifecycle without renderer captures.
