# Operator Fists Fast → Dodge Handoff Fix

- Packet schema: custodian.task_packet.v2
- Workstream: operator-unarmed-fast-dodge-handoff-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: none
- Locks: operator-runtime
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, runtime, visual
- Paired review workstream: review-operator-unarmed-fast-dodge-handoff-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: player-control handoff and one-shot presentation regression
- Reviewed main: b654ea569e2f212e97a3dd3b22998eff3bfba358
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: conditional
- Goal: Fast 01–04 → roll does not lose input, freeze melee, or replay lingering FX.
- Completion boundary: One narrow fast-chain/dodge/FX correction and focused regression; no new art, animation timing, damage or roll balance.
- Current measured state: `operator.gd` consumes fast-chain dodge presses outside the rhythm window; buffered dodge compares visible modular frame to hidden `animated_sprite` count and returns each tick; clears melee before fallible dodge start; `_play_optional_fx` replays on repeated presentation updates. Observed player symptom, source-backed risks; no runtime repro yet.
- Evidence: `custodian/game/actors/operator/operator.gd` and `custodian/tools/validation/operator_{unarmed_fast_chain,modular_fast_attack,charged_long_roll}_smoke.gd`.
- Task-specific authority: current `design/02_features/operator/DODGE_CHARGED_LONG_ROLL.md` and archived `OPERATOR_UNARMED_FAST_CHAIN_CONSOLIDATION.md`; visible attack clock owns presentation observations, dodge controller owns dodge state.
- Work surface: `custodian/game/actors/operator/operator.gd` only for narrow orchestration; `custodian/game/actors/operator/presentation/operator_animation_player.gd` only if reusable playback needs correction; existing tests/validation manifest if changed.
- Change: Use exact implementation targets below; prefer existing helpers and no added persistent state unless indispensable.
- Preserve: 6/6/7/8 Fists frames and contact cadence, intentional late *attack* rhythm rejection, stamina/cooldown/iframe, charged-roll rules, buffered roll→attack, other weapons, contact/hitbox, existing asset pipeline.
- Non-goals: New animations, broad melee controller extraction, gameplay retuning, controller rebinding, force-syncing user's dirty root `operator.gd`.
- Acceptance: Roll press from each Fast 01–04 reaches exactly one legal dodge or a deterministic reported rejection, never indefinite attack; FX starts once per link/sector and retires at dodge/completion; no lost hits, premature iframe, duplicate attack or regression.
- Validation: Focused `custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd` and `custodian/tools/validation/operator_modular_fast_attack_smoke.gd` first; `custodian/tools/validation/operator_charged_long_roll_smoke.gd`, `custodian/tools/validation/operator_dodge_flow_smoke.gd`, `custodian/tools/validation/operator_attack_phase_cadence_smoke.gd`; then `custodian/tools/validation/run_validation.py --changed --json`, `custodian/tools/agent/validate_review_pairing.py`, `custodian/tools/agent/task_packet_index.py`, and `git diff --check`. No zero-selected/skipped/timeout pass.
- Task overrides: none
- Deferred: independently queued melee domain extraction.

## Specific patch guidance (not a replacement implementation)

1. `operator.gd:_handle_dodge_input()` (~9910): the fast-chain early return is unconditional. Record a *one-shot* dodge intent even when `_fast_chain_queue_window_state()` is `early`/`late` or `_buffered_attack_kind == "fast"`; define roll priority over a pending next punch, but **commit only at a legal attack recovery/cancel boundary**. Preserve hold/release consumption with `dodge_charge_enabled`; do not convert a roll press into immediate i-frames. Route through the existing dodge controller. Explicitly report blocked stamina/cooldown.
2. `_update_melee_attack()` (~6750): replace `animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)` in the buffered-`dodge` branch with `var clock := _presentation_clock_sprite()` and `clock.sprite_frames.get_frame_count(clock.animation)`, guarding missing/invalid clock. Do not loop forever on a missing finished signal or mismatched legacy/modular frame; use the authoritative melee timeline/phase as bounded fallback, never a generic extra animation loop.
3. `_start_buffered_fast_chain_dodge()` (~6884): the current implementation calls `_reset_fast_chain()` and clears melee **before** `_try_start_dodge_with_profile()` returns. Preflight `_get_dodge_start_rejection_reason()` and explicitly settle a failed start; preserve hitbox, melee/action state and finite end-of-chain cleanup. Successful transfer must clear active overlays, attack buffer/drive and relinquish old body owner exactly once. Do not weaken `_can_start_dodge` globally.
4. `_sync_unarmed_fast_chain_action()` (~2594) calls `_play_optional_fx()` (~4319) every render tick. Gate playback on a *new action/link/sector identity*, e.g. compare `_modular_upper_fx_action_animation` plus clip identity; `OperatorAnimationPlayer.play()` must not retrigger an already-finished nonlooping FX on repeated sync. Reset link identity on genuine new attack, hide/stop on roll/terminal cleanup; check SpriteFrames loop flags without mutating unrelated clip resources.

## Focused test matrix

- Four Fast links × early/open/late roll input; existing queued `fast`; terminal link; visible modular vs intentionally different hidden legacy frame counts.
- Accepted roll: one dodge, accurate stamina/cooldown/iframe and no stale melee VFX; rejected roll: no iframe, explicit rejection and finite melee cleanup.
- Repeated `_update_animation()` after short FX completion must not restart FX; next attack link must play its own FX once.
- Preserve existing roll→fast buffer, authored hit frames, action-controller ownership; one minimal Moment Forge attack→roll replay only after focused code tests.

## Handoff

- Next workstream: review-operator-unarmed-fast-dodge-handoff-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Run opt-in authoring handoff; dispatcher claim only if eligible, then focused implementation + fresh paired review.
- Blockers or open questions: Draft/manual pending targeted automatic preflight; do not claim before promoted. Exact cancellation boundary must respect existing attack commitment.
