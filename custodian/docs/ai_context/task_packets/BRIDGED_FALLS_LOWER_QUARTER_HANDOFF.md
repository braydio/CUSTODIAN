# BRIDGED FALLS — LOWER QUARTER PRODUCTION HANDOFF

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-lower-quarter-handoff`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `ritualant-north-egress-and-chapel-vista, bridged-falls-procgen-topology, bridged-falls-bridge-grammar-asset-v2, bridged-falls-vista-waterfall-presentation`
- Locks: `ash-bell-route-cutover, lower-quarter-entry`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-bridged-falls-lower-quarter-handoff`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Goal: Make the generated Bridged Falls terminal a production geographic approach into the existing Lower Quarter without duplicating Lower Quarter route/session state, while preserving safe reverse traversal and the legacy campaign ingress until its final disposition is explicitly chosen.
- Completion boundary: Re-derive the correct route/session integration after BF1–BF6 land, add the Lower Quarter-side approach spawn/threshold and forward/reverse travel, prove state identity and rollback, then update production route/docs. This draft deliberately does not preselect route-to-route handoff versus canonical graph migration because current RouteStateStore keys persistent state by route ID and duplicating Lower Quarter under another route would fork authority.
- Current measured state: `ash_bell_lower_quarter` is an independent production route whose node state is stored under its route identity; its current world ingress enters `Spawn_FromWorld`. The Ritualant route is separate. On the reviewed baseline, RouteTraversalManager has no explicit cross-route handoff contract and RouteStateStore keys states by `route_id::node_id`. BF1–BF6 are assumed cleanly landed before execution.
- Evidence: `design/05_levels/ASH_BELL_LOWER_QUARTER.md`; `ASH_BELL_BRIDGED_FALLS_APPROACH.md`; `route_traversal_manager.gd`; `route_state_store.gd`; `lower_quarter_route.json`; BF1–BF6 archived packets/reviews after refresh.
- Task-specific authority: Existing Lower Quarter route remains sole Lower Quarter state/topology authority until this migration proves otherwise. RouteTraversalManager owns transition/session semantics. The final solution must retain one canonical state identity for Lower Quarter.
- Work surface: route/session handoff or graph migration seam chosen at refresh, Lower Quarter route data/entry spawn, generated Highlands terminal exit, reverse travel, route/state/rollback tests, current-state/docs.
- Change:
  1. **Mandatory pre-implementation refresh in the authoring chat.** Inspect BF1's generated-node lifecycle, BF3 north route, BF4 terminal contract, BF6 final presentation and current Lower Quarter runtime.
  2. Choose the smallest architecture that preserves one canonical Lower Quarter state identity. Acceptable directions are a first-class transactional route-session handoff or a migration to one canonical Ash-Bell route graph if live evidence shows that is simpler. Do not reuse the same Lower Quarter level under two persistent route IDs with independent RouteStateStore keys.
  3. Add an explicit Lower Quarter approach spawn/threshold aligned to the Bridged Falls geography rather than silently repurposing `Spawn_FromWorld` unless refresh proves that spawn is semantically correct.
  4. Forward travel must preserve the persistent Operator/camera and enter Lower Quarter once; reverse travel must reconstruct/restore the generated Highlands/Bridged Falls state according to the landed BF1/BF2 policy.
  5. Failure at either side rolls back without losing either route/generated state.
  6. Keep the old direct campaign `DESCEND TO THE LOWER QUARTER` ingress functional during the migration. At closeout, explicitly record whether it remains an alternate access, becomes fast travel/legacy infrastructure, or is retired. Do not delete it by default.
  7. Update `ASH_BELL_LOWER_QUARTER.md`, route diagrams, current state and file index only after runtime truth is established.
- Preserve: Lower Quarter / West Gate / Station IX authored geometry and local state; existing route state restoration; Station IX and West Gate transitions; generated Bridged Falls topology/presentation; Ritualant route.
- Non-goals: No Lower Quarter broad art overhaul. No Station IX redesign. No save-file persistence work unless proven required for the handoff. No new world manager when the refreshed live architecture offers a smaller seam.
- Acceptance: One production path exists Ritualant -> Highlands -> generated Bridged Falls -> Lower Quarter; reverse travel is safe; Lower Quarter state does not fork by entry method; West Gate/Station IX progression remains intact; forced handoff failure restores source authority; old direct ingress disposition is explicit and tested; route/docs describe actual runtime.
- Validation: This packet cannot become ready without authoring-chat refresh. After refresh, add a focused end-to-end route handoff smoke, then run `res://tools/validation/ash_bell_lower_quarter_route_smoke.gd`, `res://tools/validation/forlorn_ritualant_completion_smoke.gd`, BF1 lifecycle proof, BF4 topology proof and BF6 presentation proof as affected. Use one compact route-entry/reverse visual capture only if spawn/threshold composition requires subjective confirmation.
- Task overrides: `none`
- Deferred: Optional retirement/reclassification art for the old transit ingress if the final user decision keeps it as non-production access.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh instruction: This packet has intentionally excessive dependencies. Bring BF1–BF6 archived implementation/review receipts, the live RouteTraversalManager/RouteStateStore behavior, generated terminal identity and final visual handoff back to this exact chat. Re-author the handoff mechanism, exact work surface, acceptance and validation before changing Status to ready.

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
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: none
- Next action: Run final end-to-end/human scene review of the completed route and decide any post-program polish as separate work.
- Blockers or open questions: Final old-direct-ingress disposition is intentionally decided at BF7 refresh, not guessed now.
