# ROAD WITNESS TESTIMONY + REVISIT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-road-procession-testimony-v1`
- Status: `draft`
- Dispatch: `manual`
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
- Current measured state: Assume P1 reviewed lighting/bell sequence and Hub record. Witness accounts and one-bell revisit are deferred to this packet.
- Evidence: P1 archived packet/review, HubState event persistence smoke
- Task-specific authority: Event spec §3; reviewed P1.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: P1 procession controller, compact physical witness station and HubState scoped record.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After P1's third light beat reveal one witness station with 3 separable readings (victory procession, evacuation, empty road); on all 3 mark observed exactly once; later Hub revisit offers at most one short bell per entry and never repeats sequence. Preserve contradictory accounts, do not render a literal spectral crowd.
- Preserve: P1 three-beat timing, 5 Road plates, uninterrupted navigation.
- Non-goals: No apparition sprites, dialogue-tree engine, additional world-state manager or global audio rewrite.
- Acceptance: Three testimonies individually readable; completion persisted and reversible only by explicit state reset; single revisit bell, no re-triggers on collider spam; controls/navigation unaffected.
- Validation: New testimony/revisit smoke + P1 timeline + Hub route and HubState persist regressions. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

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
