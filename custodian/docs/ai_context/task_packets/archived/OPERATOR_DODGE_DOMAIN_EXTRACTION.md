# OPERATOR DODGE DOMAIN EXTRACTION — SLICE F4

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-dodge-domain-extraction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `7511489095a7fc35a3e5c907d0e1ba42e8787f8e`
- Goal: Extract dodge/charge/Flow/chain lifecycle into a focused traversal authority while preserving the deliberate full-body presentation model for displacement-owning dodge actions.
- Completion boundary: Done when dodge charge, tap/long-roll selection, iframes, chain/Flow, recovery/carry and cancellation state are owned behind an `OperatorDodgeController`-class authority; `operator.gd` keeps only facade/orchestration and the sole `move_and_slide()`; current full-body dodge/chain/dodge-fast presentations and independent FX remain unchanged; and no duplicate dodge state survives in the actor.
- Current measured state: Dodge simulation and presentation functions remain in `operator.gd`. Canonical full-body dodge/chain-link and dodge-fast transition art is live, and charge/ready/release/chain-release feedback is a presentation-only effect path. These actions own displacement or a committed whole-body silhouette; lower-locomotion modular composition would fight the authored motion rather than improve it.
- Evidence: dodge functions/state in `operator.gd`; canonical dodge/charge identities; `operator_dodge_flow_smoke.gd`, `operator_dodge_presentation_smoke.gd`, `operator_charged_long_roll_smoke.gd`, `operator_dodge_charge_feedback_smoke.gd`, overlap telemetry smoke.
- Task-specific authority: dodge/Flow combat-feel specs; Operator runtime architecture; fixed-step/movement ownership; canonical presentation authority.
- Work surface: New traversal controller under `game/actors/operator/traversal/`; actor movement facade; presentation request seam; dodge focused tests.
- Change:
  1. Move dodge charge, release classification, active dodge clocks, iframes, Flow/chain state, recovery, exit carry and cancellation reasons into one controller.
  2. Keep physical movement application through the Operator chassis: the controller may produce deterministic movement/recovery intent, but it must not become a second `move_and_slide()` owner.
  3. Preserve current full-body presentation for dodge, dodge chain links and dodge-fast attack transition. These are intentional whole-body actions, not legacy presentation debt.
  4. Keep dodge charge/release/Flow FX independent and presentation-only. Do not reintroduce direct Operator PNG loading or simulation state into the VFX node.
  5. Preserve interruption interfaces with melee/ranged/field patch/action arbitration through explicit controller results/signals rather than actor-private flag peeking.
  6. Remove actor-local dodge state/helpers only after the controller owns the complete lifecycle and existing public/debug snapshots delegate to it.
- Preserve: stamina costs, tap/hold thresholds, distance/velocity/iframes, Flow math, chain cost/timing, collision behavior, dodge-fast buffer semantics, controller input behavior, full-body/FX pixels and timing.
- Non-goals: No modular lower-body dodge. No new dodge art. No dodge economy/balance tuning. No melee/ranged extraction. No change to `move_and_slide()` ownership.
- Acceptance: Exactly one dodge state authority; identical deterministic displacement/iframe/Flow results under existing tests; full-body dodge presentation remains visually and semantically intact; no lower-locomotion layer is introduced during displacement-owning dodge; actor facade public status APIs remain compatible; interruption/cancel paths are explicit and deterministic.
- Validation: Controller-focused lifecycle tests, then existing dodge Flow/presentation/charge/overlap/twin-stick regressions plus fixed-tick and combat interaction tests. Moment Forge only for one final existing dodge scenario in evidence mode if extraction changes presentation call ordering; otherwise deterministic checks are sufficient. One changed-file closeout.
- Task overrides: `none`
- Deferred: None of the modular-presentation opportunity block belongs here by design; preserving whole-body dodge is the intended outcome.

## Handoff

- Next action: F5 may build on the stable Dodge and facade boundaries.
- Best starting files: `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`, `OperatorDodgeController`, and the focused Dodge smokes.
- Blockers or open questions: None.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `the charged-roll smoke raced the fixed-tick sampler and was converted to explicit input-frame injection; the fixed-tick and compatibility smokes expected actor-private Dodge timers and now read the controller snapshot; changed-file validation was gated by the pre-existing review-hub-first-set-blockout-v1 TASK OVERRIDE; the isolated composite unarmed fast-chain smoke reported camera/carry fixture failures, while ranged-ready input failed at its queued parry-counter assertion`
- Root cause / contributing factors: `domain extraction intentionally removed actor-local Dodge state; test harnesses depended on raw synthetic input or private state; the live queue contains malformed review-packet metadata; the composite and parry smoke failures are outside the exercised Dodge paths`
- Prevention / pipeline improvement: `keep controller tests on public state/results and inject deterministic OperatorInputFrame values for press/hold/release cases`
- Tooling / docs drift discovered: `fixed-tick smoke timer lookups needed migration to get_dodge_runtime_status()`
- Follow-up: `manual-follow-up`
- What worked: `the focused controller and Dodge/Flow/presentation checks provide deterministic evidence while preserving chassis movement ownership`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `the dodge-tagged changed validation selects seven checks and all seven pass; additional focused fixed-tick, input-frame, action-arbitration, and guard-flow checks pass. The controller is the sole Dodge simulation-state authority; operator.gd delegates status and lifecycle while retaining chassis-only movement application. The broader changed-file result selected 58 checks, passed 16, failed only at the unrelated review_pairing_contract metadata gate, and skipped 41 downstream checks; the isolated unarmed fast-chain smoke limitation is recorded in the closing summary.`
