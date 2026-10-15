# ProcGen Ambient Real-World Spawn Recovery V1

Workstream: `procgen-ambient-real-world-spawn-recovery-v1`

## Outcome

The recovery packet is blocked and remains unlanded. No runtime implementation change remains in the worktree. Exact-seed evidence identifies both a slow required-ingress retry cascade and a later loader/test-rig activation failure. The packet cannot be completed within its current ownership boundary because `ambient-spawn-activation` belongs to active H5 work, and the packet explicitly prohibits editing H5 loader/bootstrap files. The streaming worktree was not accessed or modified.

## Evidence

- Clean-main baseline: `origin/main@2b0fc9e2db367a9c2372ee54ba2b82e9de9398cf`; `procgen_ambient_enemy_real_world_spawn` with seed `3348744079` timed out at 180.05s. Full ephemeral log: `/tmp/procgen-ambient-recovery-clean-main-seed-3348744079.log`.
- Controlled diagnostic on the same seed completed attempts 0–3 after 229.7s. Attempts 0–2 each explicitly rejected `forlorn_ritualant_underground`: no canonically connector-resolvable authored pocket after 65 deterministic candidates. Per-attempt generation/semantic timings were 35.0/41.8s, 18.8/42.6s, and 21.3/45.0s. Attempt 3 accepted at 17.5s generation + 7.6s semantic evaluation. Full log: `/tmp/procgen-ambient-attempt3.log`.
- Accepted final-map materialization took 50.2s. The real loader placed 8 markers and 8 camps, then aborted because the smoke rig's `NavigationSystem` stand-in is a generic `Node` without the required `rebuild()` method. No Grunt or PursuitFrame spawned. Full log: `/tmp/procgen-ambient-accepted-attempt.log`.
- A temporary front-queue optimization in `_runtime_floor_component()` did not change the measured timeout and was reverted. Temporary stage-split/attempt-cap instrumentation was also removed. `git diff --check` passed and the runtime diff is empty.

## Ownership and Next Step

The H5 spawn-blocker owner publication summary documents the active ambient-spawn ownership lane. Current dispatcher audit confirms `hub-muster-continuity-port-deployment` remains claimed and the ambient recovery workstream is independently claimed. Do not edit the H5 worktree, change loader/bootstrap ownership, advance the ambient paired review, or advance ProcGen streaming. Bring this evidence to the recorded H5 authoring conversation and obtain an authorized owner packet/sequence; after that lane releases, remeasure the current main and complete the accepted-map actor activation proof. The required 180-second timeout remains unchanged.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: The seed requires a multi-attempt generation loop beyond the 180-second test budget, then the integration harness aborts activation at a missing navigation API.
- Root cause / contributing factors: Three deterministic required-ingress rejections precede an accepted candidate; the smoke rig does not implement the loader's NavigationSystem contract. The first attempted queue optimization had no timing effect and was reverted.
- Prevention / pipeline improvement: Keep generation retry ownership separate from loader activation. Fix the authorized smoke/activation owner contract before expecting this real-world integration gate to prove enemy population.
- Tooling / docs drift discovered: The ambient recovery packet's prescribed integration proof cannot reach enemy activation with its current NavigationSystem test double; H5 ownership prevents repair in this workstream.
- Follow-up: manual-follow-up
- What worked: Exact-seed attempt logs distinguish deterministic ingress rejection, accepted materialization, and loader abort.

## Next Handoff
- Next workstream: hub-muster-continuity-port-deployment
- Next packet state: dependency-gated
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: The activation seam is owned by active H5; the measured ProcGen retry cascade also needs a bounded authorized correction after owner reconciliation.
- Next action: Return exact evidence to the H5 authoring conversation. Preserve both existing worktrees and wait for an authorized packet/sequence.
- Blockers or open questions: H5 ambient activation ownership remains active; no standalone correction packet authorizes changing the smoke NavigationSystem fixture. ProcGen retry correction must preserve selection order and required-ingress semantics.
