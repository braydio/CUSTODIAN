# SEPULCHER GRAVE EVIDENCE + HUB PERSISTENCE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-sepulcher-grave-evidence-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `hub-event-persistence, hub-sepulcher`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-sepulcher-grave-evidence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Sepulcher grave evidence + Hub persistence; deliver one playable, bounded event slice.
- Completion boundary: Add namespaced, copy-safe HubState authored_event_records persistence with backwards-compatible restore; never overwrite campaign history/accepted scenario. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: HubFirstSetLayout defines SepulcherInteriorSample and two connector paths; HubFirstSetMap has no grave event. HubState snapshot/restore has no authored-event records; WorldEventMemory resets with a run.
- Evidence: custodian/game/world/hub/first_set/{hub_first_set_layout,hub_first_set_map}.gd; custodian/game/state/persistent/hub_state.gd; custodian/tools/validation/hub_first_set_blockout_smoke.gd
- Task-specific authority: Hub first-set map/layout, HubState persistence; event spec §1.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: HubState snapshot/restore and a focused grave controller under custodian/game/world/hub/events/sepulcher_grave/; narrow HubFirstSetMap binding; focused smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Add namespaced, copy-safe HubState authored_event_records persistence with backwards-compatible restore; never overwrite campaign history/accepted scenario. Add reachable Grave marker/interaction near SepulcherInteriorSample; implement three distinct inspections in the existing Gardens loop with immutable date, differing identity readings and explicit stage advancement. The two connector routes stay open; repeated press at one node cannot farm all three readings. Store stage in HubState, not WorldEventMemory.
- Preserve: Hub nav, both connectors, Dais prewarm, Crown/Muster routes and existing HubState keys.
- Non-goals: No adjudication/flower yet; no generic quest framework, camera takeover, new art, or alternate Hub state singleton.
- Acceptance: All three readings reachable in order using real Operator; fixed date and three identities accurate; repeated spam cannot skip; reload/snapshot restores exact stage; legacy snapshot defaults empty; other HubState fields bit-for-bit preserved.
- Validation: New small grave-stage/persistence smoke; HubState outcome+scenario regression and hub_first_set_blockout_smoke; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
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
- Next action: Complete the focused implementation, land, then run `review-hub-sepulcher-grave-evidence-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
