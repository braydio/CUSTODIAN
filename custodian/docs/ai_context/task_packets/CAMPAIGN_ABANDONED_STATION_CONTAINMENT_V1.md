# STATION CONTAINMENT CHOICE + COMPLETION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-abandoned-station-containment-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `review-campaign-abandoned-station-stability-v1`
- Locks: `procgen-authored-alpine-station`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-campaign-abandoned-station-containment-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Station containment choice + completion; deliver one playable, bounded event slice.
- Completion boundary: After 3 services in time present exactly two choices: MAINTAIN CONTAINMENT / EVIDENCE PRESERVED and SHUT DOWN COUPLING / EVIDENCE INCOMPLETE. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume S1 site + S2 local timer/service states fully reviewed. No final Hold/Shutdown choice or durable in-run readback.
- Evidence: S2 stability smoke, WorldEventMemory, Reciprocal Continuity Doctrine
- Task-specific authority: Custodian Mandate/Reciprocal Continuity, event spec §5, reviewed S1/S2.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Station controller decision/readback and run-scoped event payload; focused completion smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: After 3 services in time present exactly two choices: MAINTAIN CONTAINMENT / EVIDENCE PRESERVED and SHUT DOWN COUPLING / EVIDENCE INCOMPLETE. One choice completes event once in WorldEventMemory and shows corresponding readback; changing route/world does not silently create a campaign-wide outcome. On prior expiry decision stays unavailable and site is inspectable. No actual reciprocal Port opened.
- Preserve: S1/S2 weather/timer and local failure; global CampaignOutcome, HubState and extraction ownership.
- Non-goals: No new continuity physics engine, proven origin of anomalies, new CampaignOutcome schema, compulsory story lock.
- Acceptance: Both choices independently tested; no duplicate completion across repeat interactions and run revisit; no choice following expiry; all exits/normal objectives remain available.
- Validation: New containment resolution smoke, S1/S2 and mission/WorldEventMemory regressions; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-campaign-abandoned-station-stability-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-campaign-abandoned-station-containment-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
