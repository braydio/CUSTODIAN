# ALPINE STATION GENERATED SITE + RELAYS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-abandoned-station-site-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `procgen-authored-alpine-station`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-campaign-abandoned-station-site-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Alpine station generated site + relays; deliver one playable, bounded event slice.
- Completion boundary: Seed-deterministic optional station on valid alpine_plateau world; three reachable service props NORTH RELAY, EAST CONDUIT, CORE FEED; repeating evacuation/do-not-link broadcast, no required new raster. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Alpine Plateau Region Frame/weather authority exists; procgen lacks this specific optional station landmark and three service interactions.
- Evidence: design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md; world_environment_director.gd; Region Frame/landmark owners
- Task-specific authority: Region Frame and procgen safety, event spec §5.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Optional Alpine site claim/placement under existing generated landmark/event system; station controller under custodian/game/world/events/abandoned_station/.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Seed-deterministic optional station on valid alpine_plateau world; three reachable service props NORTH RELAY, EAST CONDUIT, CORE FEED; repeating evacuation/do-not-link broadcast, no required new raster. Use accepted placement/streaming-safe hook; invalid layout skips cleanly, other biomes never spawn. One station event ID qualified by campaign run/seed.
- Preserve: Alpine generated surface/camera/nav, existing weather schedule, mission objectives, edge/cliff avoidance.
- Non-goals: No timed failure yet, coupling choice, secondary biome generator or Asset V2 family.
- Acceptance: All three service points reachable and distinct; same-seed reload stable, invalid/mismatched biomes skip; no collision/extraction obstruction.
- Validation: New Alpine station placement multi-seed smoke; existing Region Frame/procgen safety regressions. Run changed-file validation and git diff --check only after focused smokes pass.
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
- Next action: Complete the focused implementation, land, then run `review-campaign-abandoned-station-site-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
