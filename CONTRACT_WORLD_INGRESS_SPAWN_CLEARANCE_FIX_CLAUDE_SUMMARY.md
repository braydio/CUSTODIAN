# Contract World Ingress Spawn Clearance Fix — Codex Summary

## What changed

- Moved registered structural world-ingress placement to immediately after map attachment/environment setup, before static-sector and actor/placement consumers. Required ingress failure now aborts before the Operator or later actors are relocated.
- Filtered compound spawn candidates through `ProcGenTilemap.is_inside_world_ingress_dressing_clearance()`. The designated `player_spawn` fallback must also be walkable and outside the same claim. If neither path yields a safe tile, Operator placement fails and contract activation takes the existing failure path.
- Added `contract_world_ingress_spawn_clearance_smoke.gd` and manifest ownership. It generates a deterministic contract map, places the real Ash Bell presentation collision and its exact dressing-clearance claim over the old preferred tile, then checks the safe replacement, deterministic repeat, fallback rejection, and loader call order.
- Updated current-state/file-index documentation and archived the task packet with completion and process-feedback receipts.

## Evidence

- `contract_world_ingress_spawn_clearance`: passed. The authored Ash Bell collision overlaps the old preferred location; the claimed rectangle excludes that tile; the Operator selects the same walkable safe compound tile on repeat; the 96px-class capsule probe is collision-clear; and unsafe `player_spawn` fallback leaves the Operator unmoved.
- `world_ingress_spawner`: passed.
- `ash_bell_lift_ingress_presentation`: passed.
- `contract_world_population_placement_smoke.gd`: passed.
- The one-seed `required_ritualant_ingress_contract_sweep` placed the required Ritualant ingress and passed its required-ingress dry-run, then failed its separate seed-0 Threadway isolation/zero-cell checks. The same failure reproduced from the project-root main checkout; the changed files do not include that Threadway path.
- `procgen_stuck_pocket_smoke.gd` failed its existing remediation assertion at line 70 in untouched ProcGen code. It is not registered in the validation manifest.
- The 100-seed sweep was stopped after several minutes; observed full contract generations take tens of seconds each. No generation or Archive Resolve behavior changed.
- `git diff --check` and packet-index validation pass.

## Deferred

The seed-0 Threadway isolation failure and the stuck-pocket remediation assertion remain outside this packet. They are recorded for follow-up rather than changing ProcGen or Threadway authority here.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: A concurrent validation session edited the same task worktree during implementation and ran duplicate smoke checks. The broad required-ingress sweep exceeded a reasonable closeout budget; its required-ingress assertions passed before a separate Threadway subcheck failed. The unrelated stuck-pocket smoke also failed.
- Root cause / contributing factors: The required-ingress sweep couples placement proof to Threadway isolation and expensive multi-profile generation; a second session shared the claimed worktree.
- Prevention / pipeline improvement: Keep required-ingress placement evidence separable from Threadway traversal checks, document a bounded sweep profile, and avoid duplicate worktree validation while an implementation owner is active.
- Tooling / docs drift discovered: `procgen_stuck_pocket_smoke.gd` exists without manifest registration; the default required-ingress sweep has no quick closeout profile.
- Follow-up: manual-follow-up
- What worked: The focused regression proved actual clearance, collision, fallback, and deterministic selection.

## Next Handoff

- Next workstream: `review-contract-world-ingress-spawn-clearance-fix`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7
- Refresh reason: none
- Next action: Run the paired fresh-context code/runtime review using the landed smoke evidence and disclose the independent seed-0 Threadway and stuck-pocket failures.
- Blockers or open questions: none for this scoped spawn-clearance fix; the independent baseline validation failures remain open.
