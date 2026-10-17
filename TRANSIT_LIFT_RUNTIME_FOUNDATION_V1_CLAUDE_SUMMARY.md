# Transit Lift Runtime Foundation V1

Workstream: `transit-lift-runtime-foundation-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Result

Implemented a reusable `LocalTransitLift2D` and stable `LocalTransitStation2D`
definition under `custodian/game/world/traversal/`. Migrated
`AwakeningTransitLift` to a compatibility subclass that retains the lower/upper
positions, prompt, art, integer station API, `transit_started` and
`transit_finished` signals, interactable ownership, and reset behavior.

The reusable owner validates unique station IDs and eligible actors, orders
next-station travel lexically by stable ID, rejects busy/unknown/off-station
requests, tracks cycle tokens, commits only successful arrivals, and cleans up
actor locks exactly once on success, cancellation, reset, actor tree exit, and
owner tree exit. Operator now exposes an independent local-transit lock source;
releasing it does not clear a separately held portal-transition lock. Ash-Bell
and Forlorn route-transition systems were not changed.

## Validation

- `local_transit_lift_lifecycle`: PASS, 24/24 assertions. Covered two-way and
  three-stop travel, deterministic order, busy/duplicate/unknown rejection,
  reset, stale-cycle callback, actor removal, owner exit, and exact lock counts.
- `awakening_first_return_progression`: PASS, including the independent portal
  lock ownership regression.
- `awakening_interactible_affordance_contract`: PASS.
- `awakening_lower_upper_spine_traversal`: PASS, 1,153 movement samples and 38
  passage samples.
- `git diff --check`: PASS.
- `run_validation.py --changed --base origin/main --json`: BLOCKED. Coverage was
  complete; 95 checks selected, 24 passed, 1 failed, and 70 were skipped by tier
  gating. The failure was `operator_2_5d_cohort_dependency_closure` at
  `operator_2_5d_cohort_dependency_closure_smoke.py:42`:
  `assert all(item["source_strip_hash_matches_correction"] for item in idle)`.
- Baseline comparison: the exact same assertion fails on the clean coordination
  checkout at `origin/main@675ccf726bb79397b7242ef3059971a6f1a39448`. It is not
  caused by this workstream and was not weakened or excluded.

Changed-file validation also noticed three unrelated `.gd.uid` sidecars created
by the Godot scan. They were classified as generated scratch and removed; the
new task-owned script UID sidecars remain with their scripts.

## Blocker

The workstream is intentionally checkpointed and not landed because mandatory
changed-file validation is red on the same unrelated clean-main baseline. No
paired review was launched because the implementation has not landed. Resume
this existing branch after the baseline assertion is resolved, then rerun full
changed-file validation before finishing and starting the paired review.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: changed-file validation stopped at an unrelated baseline source-strip hash assertion
- Root cause / contributing factors: `operator_2_5d_cohort_dependency_closure` fails identically on clean current main
- Prevention / pipeline improvement: retain main-baseline reproduction for broad validation failures; do not add exclusions or rewrite the golden without proving intent
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: focused lifecycle and Awakening integration checks gave clear ownership evidence

## Next Handoff
- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391
- Refresh reason: none
- Next action: resolve the clean-main source-strip hash blocker, resume this workstream, rerun changed-file validation, then finish and launch the paired review; independently continue with the next eligible dispatcher packet as requested
- Blockers or open questions: clean-main `operator_2_5d_cohort_dependency_closure` assertion failure
