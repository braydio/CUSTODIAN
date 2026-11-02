# Vehicle Wreck Restoration Foundation V1 — Review Corrections 1

## Result

Restoration now follows the Operator's real Interact hold lifecycle. The existing Operator interaction target starts restoration on the press edge; each simulation tick communicates whether Interact remains held and whether the same interaction is still selected. Release, target loss, range exit, death/impact, portal transitions, and open UI cancel before payment. The hold still restores the same vehicle at 40% health and spends the configured profile cost once.

The restoration smoke now drives the production Operator dispatch/update methods. It covers press, release, target loss, out-of-range refusal, continuous hold, exact one-time payment, same-instance restoration, and a reentrant completion attempt after restoration.

## Evidence

- `vehicle_wreck_restoration`: PASS.
- `vehicle_registry_contract`: PASS.
- `vehicle_runtime_lifecycle`: PASS.
- `vehicle_exit_clearance`: PASS.
- `python3 custodian/tools/validation/run_validation.py --tag vehicle --json`: PASS, 4 selected / 4 passed, complete focused vehicle set.
- `git diff --check`: PASS.
- Existing warnings: restoration smoke reports the known ObjectDB/resource shutdown leaks; lifecycle and exit-clearance smokes emit their expected blocked-exit warnings.

Deferred: broader interaction architecture work remains outside this correction.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first claim command returned no receipt; `last-claim --json` recovered the verified claim. The cold worktree required a Godot import before validation.
- Root cause / contributing factors: The dispatcher response was lost at the tool boundary, and this fresh worktree had no imported `.godot` cache.
- Prevention / pipeline improvement: Use the documented read-only `last-claim` recovery when claim output is missing; initialize imports once in cold worktrees.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: `--tag vehicle` produced one green report covering all four packet validation IDs.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b

## Next Handoff
- Next workstream: review-vehicle-wreck-restoration-foundation-v1-review-corrections-1
- Next packet state: ready
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b
- Refresh reason: none
- Next action: After this correction lands, start a fresh reviewer context and claim the paired review.
- Blockers or open questions: none
