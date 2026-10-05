# Operator Dodge Domain Extraction — F4

`OperatorDodgeController` now owns Dodge charge/profile selection, active and
iframe clocks, Flow/chain progression, recovery/cooldown, exit carry, and
cancellation state. `operator.gd` retains integration orchestration and
presentation-only state, applies controller velocity intent through the
existing movement chassis, and remains the only owner of `move_and_slide()`.
The authored full-body Dodge, chain-link, and Dodge-fast presentations and the
independent charge/Flow FX path remain intact. Public Dodge/Flow/debug status
APIs now delegate to the controller.

Verification passed for the seven checks selected by `run_validation.py
--tag dodge`: controller lifecycle, charged long roll, charge feedback, Flow,
canonical FX, overlap telemetry, and presentation. Separate focused checks for
fixed-tick ownership, input frames, action arbitration, guard Flow, modular fast
attack, unarmed posture, and packet contract/unit coverage passed. Three adjacent
smokes were migrated from actor-private Dodge fields to controller status; the
ranged-ready smoke still fails later at its queued parry-counter assertion, and
the unarmed fast-chain smoke still reports camera/carry fixture setup failures. The charged-roll smoke previously used raw
synthetic `Input` edges across process frames, racing the live fixed-tick sampler;
it now injects deterministic `OperatorInputFrame` press/hold/release values. The
fixed-tick smoke now reads controller clocks through the public runtime
snapshot.

The required changed-file sweep selected 58 checks, passed 16, failed at the
pre-existing `review_pairing_contract` gate for malformed `TASK OVERRIDE`
metadata in `review-hub-first-set-blockout-v1`, and skipped 41 downstream
checks. The AI-context checker separately reports the pre-existing malformed
`ASSET_DOWNLOADS_INTAKE_SWEEP.md`. An isolated `operator_unarmed_fast_chain`
smoke also reported missing injected camera resolution and attack-drive carry
fixture setup; those were not changed in this Dodge slice. No review-packet,
asset, or unrelated gameplay files were edited. The broad README task-index
block was briefly generated during required index maintenance, then removed
because the repository marks initializing it as a separate migration; the
hand-maintained F4 archive entry remains.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: changed-file validation was gated by existing review metadata, while one composite smoke reported camera and attack-drive fixture failures.
- Root cause / contributing factors: review-packet metadata is outside the slice; test fixtures mixed raw process-timed input and private timer reads with the newly extracted controller boundary.
- Prevention / pipeline improvement: inject fixed input frames in input-edge tests and assert controller behavior through public status/results.
- Tooling / docs drift discovered: fixed-tick smoke required migration from actor-private Dodge clocks to `get_dodge_runtime_status()`.
- Follow-up: manual-follow-up
- What worked: seven Dodge-tagged checks plus fixed-tick, input-frame, action-arbitration, and guard-flow regressions passed.
