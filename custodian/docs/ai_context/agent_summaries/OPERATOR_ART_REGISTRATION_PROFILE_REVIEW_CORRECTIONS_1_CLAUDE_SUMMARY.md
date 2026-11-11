# Operator Art Registration Profile Review Corrections 1

Bounded the production plan to a digest stored in the Source Session record. Converter replay now requires that expected digest; verification, source registration reporting, review, and handoff compare the plan bytes against it before proceeding. Explicit replanning and manual frame-registration edits advance the digest and invalidate prior verification/review state. Changing source landmarks after planning also forces a fresh plan.

The Workbench report now serializes current landmark coordinates in its existing 96×96 canvas, profile anchor/frame context, measured segment ratios when both endpoints exist, and point residuals as advisory evidence. It states that no Source Session scale normalization was applied. No QA thresholds, profile coordinates, animation art, or gameplay/runtime files changed.

The negative control moved `destination_x` by one pixel while keeping it in bounds. The external converter, Source Session verifier, registration report, review, and handoff all rejected the edited plan. An explicit bounded frame-registration revision produced a new digest and removed the stale production proof. The positive converter replay matched the internal crisp candidate byte for byte. v1 plan parsing remains available; an old session with a plan but no trusted session digest fails closed and must be replanned before protected plan use.

Validation: `operator_art_registration_profile_smoke.py`, `operator_art_source_smoke.py`, and `operator_art_agent_semantic_smoke.py` passed. The changed unit gate passed all 6 selected tests with complete changed-file coverage, including the review-pairing contract. `git diff --check` passed.

The first attempt to patch an expanded smoke assertion used stale context and made no changes; I reread the target block and applied a narrower patch. No other implementation or validation failures occurred. Unchanged areas deferred: profile calibration, automatic pose correction, and multi-character generalization.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: A patch attempt used stale smoke context and did not apply; initial changed-unit runs exposed fixture sequencing/expectation errors around content-addressed plan revision and the report's advisory status field.
- Root cause / contributing factors: The fixture expected unchanged deterministic plan bytes to change digest, tried a registration edit before re-approving a deliberately tampered plan, and asserted prose instead of the report's structured advisory status.
- Prevention / pipeline improvement: Re-read narrow patch targets; reset tampered plan through explicit planning before revising it, and assert the report's structured status. Corrected in-scope.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Focused negative controls covered each protected plan consumer.
