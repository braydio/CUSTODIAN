# FORUM HEARING EVIDENCE PLINTHS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-forum-hearing-evidence-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `hub-forum-hearing, hub-event-persistence`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-forum-hearing-evidence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Forum hearing evidence plinths; deliver one playable, bounded event slice.
- Completion boundary: Place 2 evidence plinths and damaged relay in navigable Forum perimeter, physically separated from Dais; show exact PORT A-17 orders and contradictory signatures from event spec; track each of 3 unique inspections in HubState authored_event_records (G1 API when landed; if independent, add an equivalent narrow HubState extension only after checking main). Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Forum Dais already accepts campaign contracts; no independent old-hearing evidence nodes currently exist. HubState accepted_scenario owner must remain exclusive.
- Evidence: custodian/game/world/hub/{hub_adjudication_dais,hub_campaign_selection_authority}.gd; custodian/game/world/hub/first_set/hub_first_set_map.gd
- Task-specific authority: Hub Forum spatial design, Custodian Mandate, event spec §2; live Dais integration.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Separate bounded hearing controller under custodian/game/world/hub/events/forum_hearing/; narrow FirstSetMap host; HubState scoped record.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Place 2 evidence plinths and damaged relay in navigable Forum perimeter, physically separated from Dais; show exact PORT A-17 orders and contradictory signatures from event spec; track each of 3 unique inspections in HubState authored_event_records (G1 API when landed; if independent, add an equivalent narrow HubState extension only after checking main). No Contract, bootstrap, or Dais method calls.
- Preserve: Dais interaction priority, accepted scenario and prewarm count; Forum ingress/exit clearance.
- Non-goals: No hearing decision yet, new independent persistence manager, cinematic camera, art commission.
- Acceptance: 3 distinct reachable inspections persist through Hub transitions; Dais behavior and generation_count unchanged throughout hearing interaction; no duplicate prompts or collision obstruction.
- Validation: Focused 3-inspection hearing smoke; hub_forum_adjudication_smoke, HubState persistence, Hub blockout; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Root slice of an independent event chain; implement against live main without waiting for other authored events.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-hub-forum-hearing-evidence-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
