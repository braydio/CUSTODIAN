# Hub Sepulcher Grave Evidence V1

Workstream: `hub-sepulcher-grave-evidence-v1`

Implemented and integrated the first playable slice of **The Grave That Refuses Its Name**. The production Hub map now binds `SepulcherGraveEvidence`, with three distinct physical inscription points in the Gardens. Their records name Elian Vale, Marrow Sen, and an unverified claimant while retaining the invariant date `CYCLE 184 · NINTH WATCH`.

The real Operator can walk between and inspect the points in order. Interaction is limited to the next reading, checks the Operator's actual distance, and cannot be farmed by repeating input at a completed point. Partial and completed progress is stored under the namespaced `hub_sepulcher_grave_v1` record in existing `HubState.authored_event_records`. Snapshot restoration resumes the correct reading, legacy snapshots remain valid, and other HubState fields are unchanged. All three positions route from South Reach; the existing connector paths and Hub navigation remain active. The event does not touch Contract prewarm.

The implementation reused the HubState authored-event persistence already landed with Procession P1. No new persistence manager, generalized event framework, or commissioned art was added. Initial validation in this ephemeral checkout exposed a missing pre-existing generated Operator runtime texture; I reused the existing local runtime asset from another CUSTODIAN worktree, then the focused and changed-file checks passed. Those generated assets are local validation inputs and are not part of the implementation.

## Validation

- `hub_sepulcher_grave_evidence`: PASS; three readings, physical Operator traversal, replay prevention, partial/completed snapshot restoration, legacy restore, unrelated state preservation, and no Contract prewarm.
- `hub_first_set_blockout`: PASS; navigation and Operator clearance.
- `hub_forum_adjudication`: PASS; HubState outcome/scenario regression.
- `hub_road_empty_procession`: PASS; existing authored-event persistence regression.
- `run_validation.py --changed --json`: PASS; complete changed-file coverage.
- `git diff --check`: PASS.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The first runtime attempt could not compile the real Operator because one pre-existing generated runtime texture was missing from this checkout.
- Root cause / contributing factors: Ephemeral checkout setup did not materialize the local Operator runtime asset set used by existing runtime smokes.
- Prevention / pipeline improvement: Make the established Operator runtime files available to ephemeral test worktrees before real-Operator validation.
- Tooling / docs drift discovered: The packet's initial measured-state paragraph said HubState authored-event persistence did not exist, but Procession P1 had already added it on main.
- Follow-up: `hub-sepulcher-grave-resolution-v1`
- What worked: The existing HubState persistence and HubFirstSet navigation authorities covered the slice without expanding architecture.

## Next Handoff

- Next workstream: `review-hub-sepulcher-grave-evidence-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Complete the fresh-context paired review; after coordinator acceptance, dispatch `hub-sepulcher-grave-resolution-v1`.
- Blockers or open questions: Independent review acceptance is pending.
