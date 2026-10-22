# ROAD PROCESSION SPATIAL BEAT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-road-empty-procession-sequence-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `hub-road-procession`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-hub-road-empty-procession-sequence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Road procession spatial beat; deliver one playable, bounded event slice.
- Completion boundary: Create voluntary south-to-north spatial trigger across Road/North Processional; show exactly three ordered distant-light beats + bell/silence without ghosts, teleport, camera takeover or new lighting authority. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Road first-set reuses five production plate pairs; Road has no 3-beat empty-procession event or persisted first-seen flag.
- Evidence: custodian/game/world/hub/first_set/{hub_first_set_layout,hub_first_set_map}.gd; design/04_architecture/HUB_SPATIAL_LAYOUT.md
- Task-specific authority: Road module placement ownership, HubState, event spec §3.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Bounded procession controller in custodian/game/world/hub/events/road_procession/ and minimal map trigger integration.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Create voluntary south-to-north spatial trigger across Road/North Processional; show exactly three ordered distant-light beats + bell/silence without ghosts, teleport, camera takeover or new lighting authority. Use existing light/audio owners or local presentation only; progress should be deterministic/idempotent from persistent Hub event record. Preserve five Road module coordinates/pixels.
- Preserve: Normal player control, Dais route, Road collisions and Crown ingress.
- Non-goals: No testimony station yet, new lighting scheduler, cutscene system, new artwork.
- Acceptance: Single activation, correct south/mid/north order, safe pause/Hub leave/return, replay does not relaunch full spectacle, no plate changes, clear traversal.
- Validation: New procession-timeline smoke, Road/Hub geometry and HubState snapshot regressions; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
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
- Next action: Complete the focused implementation, land, then run `review-hub-road-empty-procession-sequence-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
