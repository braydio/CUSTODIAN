# Hub Sepulcher Grave Resolution

Workstream: `hub-sepulcher-grave-resolution-v1`

## Result

Implemented the G2 grave resolution on the existing production-bound
`SepulcherGraveEvidence` controller and `HubState` authored-event record.
After all three readings, the Operator can physically select exactly one of:

- `ATTEST: PROVENANCE CONFLICT`
- `LEAVE UNRESOLVED`

Either outcome persists once, suppresses further resolution choices, and keeps
the three original readings available for rereading. Restoring either outcome
on a later visit shows a restrained pale growth at the slab. The new growth and
choice presentation add no collision owner and do not touch Contract prewarm or
accepted scenario state. No new art asset or generalized event framework was
added.

The predecessor grave smoke now reflects G2's reread contract: it verifies all
three completed readings remain inspectable and that rereading does not change
the persisted evidence.

## Verification

- `hub_sepulcher_grave_resolution`: PASS; both outcomes, repeated-input
  idempotence, HubState restore, later-visit cue, rereads, Hub navigation, no
  collision owner, and unchanged Contract state.
- `hub_sepulcher_grave_evidence`: PASS.
- `hub_first_set_blockout`: PASS; 13,142 walkable cells and 52 merged boundary
  rails.
- `run_validation.py --changed --json`: PASS, 9/9 selected checks, complete
  changed-file coverage.
- `git diff --check`: PASS.
- Moment Forge: not run; the acceptance is bounded state/persistence and
  non-colliding local presentation, covered by structured runtime assertions.
- Subjective visual review: not triggered; no art-direction decision is part of
  the packet acceptance.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The predecessor G1 smoke expected completed readings to become unavailable, conflicting with G2's reread acceptance; its assertion was updated and the regression passed.
- Root cause / contributing factors: G1's original no-replay assertion predated G2's requirement to keep all three physical readings inspectable.
- Prevention / pipeline improvement: Keep predecessor regression assertions aligned when a declared successor extends behavior while preserving existing evidence.
- Tooling / docs drift discovered: `none`
- Follow-up: `fixed-in-scope`
- What worked: Existing physical interaction and HubState snapshot/restore seams supported the choices and return cue without a new state manager or collision authority.

## Read-only F14-C2a Dependency Diagnosis

The C2a packet currently depends on
`review-living-world-entity-reification-handoff`. That archived review's
recorded verdict is `findings` with R0-01, R0-02, and R0-03. The follow-up
correction review
`review-living-world-entity-reification-handoff-review-corrections-1` is
archived `passed`, but its target is the correction workstream, not the original
review target named by C2a. The dispatcher therefore correctly reports no
verified passing outcome or target receipt for the exact declared dependency.
This is a dependency/refresh mismatch for the authoring chat to resolve. The
existing C2a claim, branch, dirty worktree, and lock were not accessed or
modified.

## Next Handoff

- Next workstream: `review-hub-sepulcher-grave-resolution-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `n/a`
- Refresh reason: `none`
- Next action: Run the paired review from a fresh context after the implementation lands and archives.
- Blockers or open questions: `none`
