# ROAD WITNESS TESTIMONY + REVISIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-road-procession-testimony-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `review-hub-road-empty-procession-sequence-v1`
- Locks: `hub-road-procession`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-hub-road-procession-testimony-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Road witness testimony + revisit; deliver one playable, bounded event slice.
- Completion boundary: After P1's third light beat reveal one witness station with 3 separable readings (victory procession, evacuation, empty road); on all 3 mark observed exactly once; later Hub revisit offers at most one short bell per entry and never repeats sequence. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume P1 implemented and independently reviewed in the post-Awakening Hub first-set runtime, including three reachable stage triggers and single-owner persistent HubState record. Testimony and one-bell revisit remain absent.
- Evidence: P1 archived packet/review, HubState event persistence smoke
- Task-specific authority: Event spec §3; reviewed P1.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Reviewed P1 controller in post-Awakening HubFirstSetMap; physical station in the already walkable Road/North Processional; same HubState record owner, never Awakening prototype.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After P1's third light beat reveal one witness station with 3 separable readings (victory procession, evacuation, empty road); on all 3 mark observed exactly once; later Hub revisit offers at most one short bell per entry and never repeats sequence. Preserve contradictory accounts, do not render a literal spectral crowd.
- Preserve: P1 three-beat timing, 5 Road plates, uninterrupted navigation.
- Non-goals: No apparition sprites, dialogue-tree engine, additional world-state manager or global audio rewrite.
- Acceptance: Three witness readings are reachable with real Operator in Hub host without blocking ForumSouth or Dais, completed exactly once in HubState, and on subsequent Hub revisit at most one short bell occurs without replaying three-beat sequence; no scene transfer to Awakening and no collision/nav change.
- Validation: New testimony/revisit smoke + P1 timeline + Hub route and HubState persist regressions. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Playable world boundary
P2 consumes P1's reviewed Hub route and controller. The five Road plate pairs are existing south-route visuals; do not claim production-art coverage of North Processional or move physical station into the Awakening Road prototype.

## Dependency assumption
Assume predecessor `review-hub-road-empty-procession-sequence-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-hub-road-procession-testimony-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
