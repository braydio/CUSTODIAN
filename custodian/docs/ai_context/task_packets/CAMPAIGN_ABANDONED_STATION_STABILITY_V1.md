# STATION SERVICES + LOCAL 90S STABILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-abandoned-station-stability-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `review-campaign-abandoned-station-site-v1`
- Locks: `procgen-authored-alpine-station`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-campaign-abandoned-station-stability-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Station services + local 90s stability; deliver one playable, bounded event slice.
- Completion boundary: On first service start a LOCAL 90 simulation-second window; service 3 nodes in any order exactly once, persisting run-scoped progress in WorldEventMemory. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Assume S1 station and three relay interactions reviewed; service clock, environmental escalation, and stability expiry are absent.
- Evidence: S1 focused smoke, existing WorldEnvironmentDirector/WorldAtmosphere2D/WorldLightingDirector APIs
- Task-specific authority: Existing world weather/lighting authorities, event spec §5 and S1 reviewed site.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: S1 station controller/service state; minimal existing presentation request seam only if supported.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: On first service start a LOCAL 90 simulation-second window; service 3 nodes in any order exactly once, persisting run-scoped progress in WorldEventMemory. Escalate with existing weather/atmosphere/lighting profile or locally scoped non-authoritative atmospheric cue, never by taking over global weather schedule. On three services before expiry reveal outward-link hazard; expiry reports STABILITY WINDOW EXPIRED and leaves campaign/extraction intact. Resume from in-run cached payload without duplicate timer/side effects.
- Preserve: Weather schedule ownership, deterministic fixed-step, normal combat and world generation.
- Non-goals: No new time system, mission-wide failure, invented weather sprites, forced station decision.
- Acceptance: Service permutations equivalent, timer exactly 90 sim seconds, expiry and success disjoint, no duplicate service; weather outside site unchanged; leaving event can't softlock campaign.
- Validation: New fixed-step station-stability smoke and S1 multi-seed + environment/lighting smoke; changed-file validation. Run changed-file validation and git diff --check only after focused smokes pass.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Dependency assumption
Assume predecessor `review-campaign-abandoned-station-site-v1` passed its post-land review and is archived complete. Consume its public event-state/runtime seams; re-read actual files at claim time and adapt private names only. Never duplicate its controller or persistence owner.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-campaign-abandoned-station-stability-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
