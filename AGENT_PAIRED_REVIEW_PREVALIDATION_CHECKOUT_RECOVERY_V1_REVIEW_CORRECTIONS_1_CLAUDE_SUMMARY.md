# Pre-validation Checkout Recovery Corrections 1

## Result

Implemented the narrow source-span provenance correction for `agent-paired-review-prevalidation-checkout-recovery-v1`. The resolver now recognizes the exact interior main-sync merge witnessed by the primary workstream trace while preserving first-parent-only authorship. It records the merge as `source_main_sync_merge`; inherited main paths do not enter the authored source span.

The original primary review run `20261025T032358Z-3b242f79acdc`, its claim, branch, worktree, and failed host-validation state were not modified.

## Validation

- New real-Git positive and hostile fixture: pass.
- Existing checkpoint/resume adversarial fixture: pass.
- Full paired-review runner unit suite: 186/186 pass.
- Canonical `paired_review_runner_unit`: pass, 1/1.
- Changed-file validation: pass, 2/2, complete coverage for `paired_review_host_validation.py` and `test_paired_review_runner.py`.
- AI-context check, packet index, review pairing, packet authoring, Python compile, and `git diff --check`: pass.
- Direct resolution of the exact primary source span: pass; merge `2981a122c2983fb946494e2ad821b5059c20fe98`, source head `80c45eb4bd3fe9d512ef8b5e29ddcca448c9a81c`, six authored source/test paths.

## Friction and evidence

The initial hostile fixture accidentally emitted both the in-place sync witness and a matching resume event. That exposed an acceptance ambiguity, so the resolver now rejects a resume trace that also claims the exact in-place sync transition. The hostile fixture was corrected and all existing checkpoint/resume tests remained green.

Changed-file validation report: `/tmp/prevalidation-source-span-changed.json`.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first hostile fixture accidentally combined two lifecycle shapes.
- Root cause / contributing factors: The fixture did not model in-place main sync as a distinct lifecycle shape.
- Prevention / pipeline improvement: Require unique checkpoint, changed-sync, and later no-op witnesses; reject conflicting resume evidence.
- Tooling / docs drift discovered: none
- Follow-up: review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1
- What worked: Real temporary Git histories made source ownership and trace mutations directly testable.

## Next Handoff

- Next workstream: review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Land the correction and run its fresh-context paired review. After that review is accepted, resume primary review run `20261025T032358Z-3b242f79acdc` through host-validation recovery.
- Blockers or open questions: none.
