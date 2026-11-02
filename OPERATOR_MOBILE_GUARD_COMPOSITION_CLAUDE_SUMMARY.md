# Operator Mobile Guard Composition

Implemented the unarmed guard presentation lifecycle in the post-Slice-E semantic presentation path. Moving enter, hold, non-breaking recoil, and exit now pair movement-owned lower-body locomotion with the aim-facing upper defense action. Stationary enter/recoil retain their authored paired poses; exit reverses the upper enter action while the lower locomotion clock continues. Missing required layers fall back to a complete paired body. Guard break keeps its impact-recovery lock and never selects mobile composition.

The focused smoke now covers movement west while guarding east, enter/hold/recoil/recovery/exit, lower progress continuity, stationary paired layers, missing-layer fallback, upper-owned completion, and guard-break exclusion. The runtime-scale Moment Forge scenario proves the actual westward strafe through moving enter, hold, and exit with state probes and six evidence keyframes.

## Evidence

- After syncing current `origin/main`, `operator_guard_flow`, `operator_modular_defense_ranged`, `operator_body_pair_canonical`, `operator_visual_ownership`, `operator_fixed_tick_spine`, `operator_input_frame`, `operator_upper_fx_canonical`, and `operator_mobile_guard_strafe`: passed.
- Moment Forge `combat/operator_mobile_guard_strafe --capture-mode evidence`: passed, 60 Hz; evidence at `reports/moment_forge/combat/operator_mobile_guard_strafe/20261010T195227-0400`. The scenario schema requires six sorted contact-sheet ticks; they bracket setup and release while sampling moving enter, steady hold, and exit.
- Code changed-file validation: coverage complete; 54 passed, 3 failed, 15 skipped. The remaining failures are `operator_ranged_ready_input`, `operator_unarmed_fast_chain`, and `operator_vigil_dagger`. These are the already-diagnosed baseline issues assigned to `operator-baseline-validation-rehabilitation`; no related gameplay or assertion weakening was included here. After the later main sync, the documentation-only changed-file sweep passed `review_pairing_contract` (1/1).
- `git diff --check`, manifest/scenario JSON parsing, and managed packet-index verification: passed.

The first expanded smoke run exposed a wrong test assumption: `_is_movement_locked()` reports action locks, while guard-break displacement suppression is driven by `_enemy_impact_lock_timer`. The test now checks the actual impact lock. Owner-scoped upper FX also revealed that its canonical smoke called parry FX before acquiring a body owner; the fixture now establishes the ordinary body owner, and shared FX is registered with both ordinary body owners. Optional FX stays silent when no body owner is active.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: an invalid guard-break lock assertion and an ownerless FX fixture were uncovered during regression expansion; the changed-file sweep also surfaced three known baseline failures in the dependent rehabilitation packet.
- Root cause / contributing factors: the test conflated separate lock types; the FX smoke bypassed runtime body-owner setup; existing ranged-counter, fast-chain-carry, and Vigil-camera baselines remain unrepaired.
- Prevention / pipeline improvement: assert guard break through its impact timer, exercise shared FX through the canonical owner API, and continue the explicit baseline repair packet after this dependency lands.
- Tooling / docs drift discovered: none beyond the three already-owned baseline failures.
- Follow-up: operator-baseline-validation-rehabilitation
- What worked: the presentation controller preserved lower locomotion identity/progress while the upper guard phase changed.

## Next Handoff
- Next workstream: operator-baseline-validation-rehabilitation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: recheck dispatcher eligibility after this packet is archived complete, then claim the ready/auto baseline rehabilitation packet.
- Blockers or open questions: three known baseline checks remain assigned to that successor.
