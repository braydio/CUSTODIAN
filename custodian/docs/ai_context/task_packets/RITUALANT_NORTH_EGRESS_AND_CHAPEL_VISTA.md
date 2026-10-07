# RITUALANT — NORTH EGRESS + DISTANT CHAPEL PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ritualant-north-egress-and-chapel-vista`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-highlands-generated-destination`
- Locks: `ritualant-underground-route, ritualant-camera-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-ritualant-north-egress-and-chapel-vista`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Goal: Make the Ritualant authored Underground a true through-route: preserve the south/lift relationship, fix the arrival chapel-vista regression, and open the north throat into the generated Highlands only after encounter resolution.
- Completion boundary: Wire the real camera-zone arrival path so `DistantChapelProxy` appears during LANDING_VISTA/UPPER_DESCENT and retires at DEEP_CAVERN; replace the north seal's post-resolution presentation-only fade with a safe traversable route seam into the landed `ash_bell_highlands` destination while keeping the unresolved encounter physically blocked.
- Current measured state: The live underground scene starts `DistantChapelProxy` at alpha 0 and the existing smoke proves visibility by directly calling the profile-change handler rather than proving the real zone/director activation path. `LowerQuarterSeal` fades after completion but the north boundary remains blocked and has no production route exit. The Highlands destination does not exist on the reviewed baseline but is assumed landed cleanly before execution.
- Evidence: `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md`; `design/05_levels/ASH_BELL_BRIDGED_FALLS_APPROACH.md`; live `forlorn_ritualant_underground.{gd,tscn}`; `authored_camera_zone_{2d,director_2d}.gd`; Ritualant underground/completion smokes.
- Task-specific authority: The authored Underground scene owns local geometry/camera/presentation; `RouteTraversalManager` owns route transitions; BF1/BF2 own generated destination activation; encounter completion state owns whether the north route can open.
- Work surface: Ritualant Underground scene/script, camera-zone integration, route definition/exit binding, north-throat collision/presentation, focused route/presentation tests.
- Change:
  1. Fix initial/arrival camera-profile resolution so a real Operator arriving at `Spawn_DescentLanding` produces LANDING_VISTA without direct test-only handler invocation.
  2. Preserve chapel proxy lifecycle: visible through LANDING_VISTA and UPPER_DESCENT; fade/retire at DEEP_CAVERN and remain absent for chapel gameplay.
  3. Add a north route exit/threshold behind the existing seal. It is disabled and physically blocked until the canonical Ritualant site-completion state is true.
  4. On resolution, preserve the earned seal reveal, then clear only the intended northern traversal blocker and enable the route exit into the exact BF2 Highlands entry spawn.
  5. Backtracking from Highlands must return to a safe northern Ritualant arrival spawn without replaying encounter one-shots or reopening unresolved state.
  6. Add end-to-end validation that walks the real camera director/zone path and the post-resolution north exit. The pre-resolution negative control must prove north traversal is impossible.
- Preserve: South lift return/exfil, chapel combat/dialogue/fountain state, LowerQuarterSeal art/fade intent, current arena/camera bounds except bounded north-throat edits, generated Highlands lifecycle from BF1/BF2.
- Non-goals: No Bridged Falls topology. No Lower Quarter handoff. No new Ritualant combat/art. No changes to dialogue/lore.
- Acceptance: Real landing activates the chapel proxy without direct handler calls; proxy retires only at the intended deep-cavern profile; unresolved north remains blocked; resolved north opens exactly once and transitions to Highlands; reverse traversal returns safely; encounter state does not regress/replay.
- Validation: Refresh in the authoring chat before promotion. Then extend/rewrite the existing Ritualant underground smoke so the camera director is exercised end to end; run `res://tools/validation/forlorn_ritualant_completion_smoke.gd` and the BF1/BF2 route-node proofs. Use one compact Moment Forge landing/north-throat capture only if objective state checks cannot settle visibility/layering.
- Task overrides: `none`
- Deferred: Bridged Falls generated topology and final Lower Quarter cutover.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh instruction: Bring BF1/BF2 landed/reviewed contracts and exact Highlands spawn/return identities back to this chat; re-derive the route-edge/spawn/camera details before setting ready.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill>`
- Completion boundary satisfied: `<fill>`
- Acceptance satisfied: `<fill>`
- Superseded/legacy production path disposition: `<fill>`
- Evidence: `<fill>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill>`
- Friction severity: `<fill>`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `<fill>`

## Handoff
- Next workstream: `bridged-falls-procgen-topology`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: Generated Highlands and north-egress route identities are now live and must be reflected in BF4 before topology work.
- Next action: Return landed evidence here and refresh BF4/BF5 assumptions.
- Blockers or open questions: none assumed if dependencies land cleanly.
