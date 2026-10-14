# OPERATOR UNARMED FAST → DODGE HANDOFF V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-unarmed-fast-dodge-handoff-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, animation`
- Paired review workstream: `review-operator-unarmed-fast-dodge-handoff-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: shared melee/dodge action arbitration and FX playback have player-visible control and timing regressions; independently falsify the exact input/visual seam
- Reviewed main: `b654ea569e2f212e97a3dd3b22998eff3bfba358`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `conditional`
- Goal: During unarmed Fists Fast 01–04, a roll press is reliably registered and transitions to a legal tap dodge; the outgoing melee FX never repeats or survives the transition.
- Completion boundary: Resolve fast→dodge input latching, visible animation-clock comparison, end-of-action handling, failed-dodge cleanup, and single-play FX ownership in one narrow correction, with real-frame integration tests. No new art.
- Current measured state: On inspected main `b654ea569e2f212e97a3dd3b22998eff3bfba358`, `operator.gd:_handle_dodge_input` consumes every dodge press during authored fast chains, but buffers only when the *rhythm* window is open and `_buffered_attack_kind` empty; the rest return silently. `_update_melee_attack` compares `_fast_chain_presentation_frame()` (visible owning modular clock) to final frame count of `animated_sprite` (possibly hidden legacy), and returns unconditionally while `dodge` remains buffered. `_start_buffered_fast_chain_dodge` clears melee state before calling a fallible `_try_start_dodge_with_profile`, without checking `false`. `_sync_unarmed_fast_chain_action` drives `_play_optional_fx` every update, whose `OperatorAnimationPlayer.play` invokes `sprite.play` even if a non-looping clip has finished. User reproduced apparent final Fast VFX repetition and loss of roll control. Not yet reproduced with a committed automated fixture; preserve the distinction between source-exposed risks and run-verified cause.
- Evidence: `custodian/game/actors/operator/operator.gd` functions `_handle_dodge_input`, `_fast_chain_queue_window_state`, `_update_melee_attack`, `_start_buffered_fast_chain_dodge`, `_get_dodge_start_rejection_reason`, `_presentation_clock_sprite`, `_sync_unarmed_fast_chain_action`, `_play_optional_fx`; `custodian/game/actors/operator/presentation/operator_animation_player.gd`; `custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd` and `operator_modular_fast_attack_smoke.gd`. The latter mainly tests **roll→fast attack**, not the reported **fast attack→roll** path.
- Task-specific authority: `custodian/docs/ai_context/task_packets/archived/OPERATOR_UNARMED_FAST_CHAIN_CONSOLIDATION.md`; `design/02_features/operator/DODGE_CHARGED_LONG_ROLL.md`; current Fists 6/6/7/8 presentation-duration and committed-contact contracts; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`. Historical superseded cadence documents are not live tuning authority.
- Work surface: Operator melee/dodge seam in `custodian/game/actors/operator/operator.gd`, existing dodge controller/presentation utilities only as needed, exact relevant smoke tests and the validation manifest. The coordination checkout may carry user-owned changes to `operator.gd`; only modify an authorized isolated claimed worktree and never force root sync.
- Change:
  1. Add deterministic fast→roll integration reproduction through real input-frame sampling/handling, measured visible action clock and actual dodge controller state; include Fast 01, 02, 03 and terminal 04, early/open/late presses, current chain buffered `fast` competition, and button-release handling with dodge-charge enabled. Establish intended input arbitration explicitly: roll becomes a persistent, bounded defensive intent at the legal attack-cancel boundary (not an immediate iframe grant); an already-queued subsequent fast link must not silently consume a newer roll request.
  2. In buffered dodge commit, use the current *visible owning* fast-chain clock, its actual animation identity, correct frame count and deterministic elapsed-phase fallback; never use hidden legacy sprite frame count for a modular link. Remove the unconditional infinite return at an unreachable frame. Preserve weapon-defined contact / rhythm timing and nonlooping chain semantics. Do not let a missing/retired presentation clock immobilize gameplay forever.
  3. Handle `_try_start_dodge_with_profile(...)` rejection transactionally. A rejected tap roll must not erase attack/recovery state, leave the hitbox active, leave buffered intent frozen, or preserve attack/FX overlay ownership indefinitely. Record one explicit rejection reason and settle cleanly at the correct phase; respect cooldown, stamina, impact/UI/death/portal and dodge profile rules.
  4. Make the optional authored Fists Fast FX play once per logical link/sector activation; do not retrigger a finished nonlooping clip just because `_update_animation` runs again. Explicitly stop and hide all outgoing melee FX/body overlays on successful roll ownership transfer, normal completion, and interruption; protect correct new-link restarts and legitimate facing changes.
  5. Check `OperatorActionController` completion, lingering `_melee_animation_finished`, queued attack kind, `_dodge_fast_attack_presentation_active`, and body-presenter owner across transitions; avoid split-brain action/presentation owners or double dodge/attack starts. Prefer existing APIs/authorities to a new state machine.
  6. Add bounded telemetry for accepted roll intent, legal handoff, and rejected roll (with profile, chain link, visible frame/action, buffered kind and rejection reason); no per-frame logs. Update only genuinely drifted docs and registered validation ownership.
- Preserve: Fists 6/6/7/8-frame contact and speed/timing, target solutions, attack-drive carry budgets, stamina and cancel semantics, active dodge iframe rules, charged long/committed roll commitment, roll→fast attack buffer, tap roll→fast attack cancel, armed melee and block/guard, existing animation source assets and Alpha pipeline.
- Non-goals: no new VFX/art generation or re-ingestion; no generalized ability-to-dodge-at-any-time, invulnerability during strike/recovery, input rebinding, new combat state machine, broader Operator domain extraction, balance changes, unrelated main/workflow lock repair.
- Acceptance: (A) fast→roll produces exactly one tap dodge at permitted handoff, for all four authored links, without input loss; (B) late/early/full buffer cases have documented deterministic disposition, never indefinite melee; (C) wrong hidden legacy frame count cannot block visible-clock completion; (D) rejected roll produces no dodge iframe, keeps a valid gameplay state and finite cleanup; (E) final melee FX plays once, stops/hides on handoff, never loops or persists after roll; (F) no duplicate contact/hit and no early iframe; (G) existing roll→fast, fast-chain, charged roll, Flow, melee cadence, animation/body-owner guards remain green; (H) a small in-engine Moment Forge attack→roll sequence demonstrates one transition without large new visual capture. No asset edits.
- Validation: Add/extend narrow real actor smoke in `custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd` or a new registered focused test for input-frame driven Fast 01–04→dodge; extend `operator_modular_fast_attack_smoke.gd` with FX restart/cleanup and keep roll→fast cases; run `operator_charged_long_roll_smoke.gd`, `operator_dodge_flow_smoke.gd`, `operator_attack_phase_cadence_smoke.gd`, action-arbitration/body composition contracts. Validate no skipped or zero-selected tests and final canonical `run_validation.py --changed --json` with full coverage, `check_ai_context.py --json`, `validate_review_pairing.py`, `task_packet_index.py`, `git diff --check`. One minimal in-engine Moment Forge reproduction if objective tests pass.
- Task overrides: none
- Deferred: broader Operator melee domain extraction is separately scoped; do not absorb this correction.

## Handoff

- Next workstream: `review-operator-unarmed-fast-dodge-handoff-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Next action: Validate the packet/review pair against current main, inspect exact owner availability, promote only under ordinary authoring procedure, claim implementation on an eligible `operator-runtime` lock, and run a fresh independent review after landed code.
- Blockers or open questions: draft/manual pending targeted authoring checks; actual in-engine reproduction must select the precise intended defensive-input boundary. Existing unrelated `agent-workflow` locks do not authorize changing this packet's ownership.
