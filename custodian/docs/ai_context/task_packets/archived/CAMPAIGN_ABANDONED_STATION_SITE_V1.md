# ALPINE STATION GENERATED SITE + RELAYS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-abandoned-station-site-v1`
- Status: `complete`
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
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
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
- Blockers or open questions: Independent paired review remains the required next workstream.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `CAMPAIGN_ABANDONED_STATION_SITE_V1_CLAUDE_SUMMARY.md`; committed-source changed validation 20/20; station smoke and Region Frame regression PASS.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The initial placement smoke used the lower-level ProcGen map and did not model the campaign route-distance/reservation contract. The default changed-file validation also compares the worktree to HEAD, so a committed-source report required --base origin/main.`
- Root cause / contributing factors: `The feature integration lives at ContractWorldLoader above ProcGenTilemap, and the validator default targets uncommitted changes rather than the claimed branch delta.`
- Prevention / pipeline improvement: `Keep planner eligibility based on explicit level_data route/reservation fields and runtime walkability. For finish-bound committed-source proof, invoke run_validation.py --changed --base origin/main --json.`
- Tooling / docs drift discovered: `No repository tooling defect. The initial test fixture was corrected to use a small deterministic candidate field while retaining generated-map multi-seed construction.`
