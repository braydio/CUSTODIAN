# CUSTODIAN Execution Reset V1 — Implementation Summary

Workstream: `agent-execution-reset-v1`

Authoring chat: not-recorded

## Delivered

- Added `legacy_claim_quarantine.py` with checksummed snapshot verification, exact-owner planning, generation-fenced records, a batch path, and same-host process-exit revalidation.
- Updated dispatch to keep quarantined work claimed for duplicate prevention while separating verified execution-lock occupancy from accepted-review dependencies.
- Prevented ordinary start/resume/finish from reopening quarantined identities; documented the one-way bounded contract.
- Archived seven superseded recovery proposals with `Disposition: legacy_quarantined` and `Status: blocked`, preserving their unresolved outcomes and evidence. Current claims outside the captured safe set remain untouched.
- Added regressions for current refs, claim identity, process state, lock collisions, generation behavior, branch/worktree changes, atomic races, existing local record preservation, and remote record collision. Added the quarantine suite to the validation manifest.
- Preserved the reset baseline snapshot and the Broken Warrant ignored-art backup. Original snapshot manifest SHA-256: `a25387215f15de045c3b84258a934f0a93cfcbdea20fd7acb677e43e98c466b1`.

## Quarantine recheck and scheduling evidence

Nine `refs/custodian/legacy-quarantined/*` records are already present on `origin` with the exact SHAs preserved in the local snapshot. This workstream did not publish, rewrite, or delete those refs. A fresh exact-owner plan and readback confirmed all nine record identities, original branch/claim SHAs, worktree/evidence inventories, and same-host process-exit traces. All nine owners report `exited_verified`; a separately claimed continuation review is outside this set and remains protected.

At `origin/main@134e4c2913fb`, the existing dispatcher reports one claimable auto packet and does not read the quarantine records. Running the reset dispatcher against the same fetched packet tree and remote refs reports nine `legacy_quarantined` identities and two claimable auto packets, including `agent-paired-review-claim-publication-main-advance-v1`. This demonstrates the scheduling change from the new code without changing claim identity or accepted-review dependencies.

Durable readback evidence is under:
`/home/braydenchaffee/.local/share/CUSTODIAN/execution-reset/20261020T1420Z-b5a46e829/rechecks/20261020T1840Z-existing-remote-records/`

Its evidence manifest SHA-256 is `bd361fe3d5d96527a14319a85d08596caec970d58b1a648e217bd2cb98375a85`. The original backup manifest remains unchanged.

## Productive feature proof

The existing `operator-motion-foundry-blender-2d-rig-v1` implementation landed at `origin/main` in merge commit `2e0ea6a67c4fc6b1a55078fa04ad4ee3eb3efcf1`; the persistent root checkout synchronized successfully. Blender 2D smoke and predecessor extraction checks passed, the North fast-chain VFX contract and five provenance regressions passed, and the final changed-file suite passed 44/44.

The feature's existing paired review was dispatched through its named runner but remains blocked before reviewer launch. Preserved run `20261020T164347Z-b160370ad5c5` reports `archive-only landing contains unrelated paths`; its claim and worktree remain preserved, with no review verdict. No acceptance is inferred from implementation tests.

## Validation

- `python3 -m unittest custodian.tools.agent.test_legacy_claim_quarantine custodian.tools.agent.test_dispatch custodian.tools.agent.test_workstream` — 150 tests passed.
- `python3 custodian/tools/validation/run_validation.py --test legacy_claim_quarantine_unit --json` — passed.
- `validate_task_packet_authoring.py` for the reset implementation/review pair — passed.
- `task_packet_index.py --write` followed by check — passed.
- `git diff --check` — passed.
- Exact owner/ref plan, snapshot verification, remote-record readback, and before/after dispatch audits — passed; no active or ambiguous owner was released.

The full Blender changed-file run selected 44 tests and passed all 44. At reset branch HEAD `f43f3e6e`, with `origin/main@134e4c29`, local reset dispatch reports nine verified `legacy_quarantined` identities and two claimable auto packets; legacy main reports one claimable auto packet and does not consume those records. After main sync, the focused 150-test suite passed and `legacy_claim_quarantine_unit` passed.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: high
- What went wrong: The feature review stopped before reviewer launch on an archive source-span check. Re-audit found that the nine quarantine refs had become remote while the old main dispatcher still ignored them. The first quarantine implementation also did not distinguish local candidate records from remote canonical records. The post-sync focused suite found one stale test expectation after main changed safe synchronization for unrelated untracked files.
- Root cause / contributing factors: The feature source and archive closeout shared one commit; quarantine lookup used a malformed remote-tracking ref path and could overwrite a pre-existing local record. One workstream regression still expected every untracked file to block synchronization, contrary to the newer lifecycle docs and smoke test.
- Prevention / pipeline improvement: Keep implementation and archive-only closeout commits separate. Use exact local-record reuse, compare-and-swap for new refs, exact remote ref lookup, and preservation of any pre-existing record on failed push. Assert that unrelated untracked bytes survive safe sync and that tracked edits or incoming-path collisions remain blocked.
- Tooling / docs drift discovered: Remote quarantine record existence and `main` scheduling support are separate facts; dispatcher audits now report them only when the implementation is present. The workstream test was stale relative to the root-sync contract.
- Follow-up: fixed-in-scope
- What worked: Snapshot checksums, exact process traces, preserved ref identities, and an independent local-code dispatch audit provided a measurable frontier comparison.

## Next Handoff

- Next workstream: `review-agent-execution-reset-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Fresh-context independent review of the reset implementation and after-landing dispatcher audit.
- Blockers or open questions: The Operator Blender paired review remains unresolved before reviewer launch. The separately claimed missing-disposition continuation review remains active and outside the nine quarantined records.
