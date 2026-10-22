# GENERATED CONVOY POCKET PLACEMENT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-placement-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `procgen-authored-convoy`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-campaign-empty-convoy-placement-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Generated convoy pocket placement; deliver one playable, bounded event slice.
- Completion boundary: Place optional single convoy 12x10-or-larger safe roadside pocket using existing seed-qualified semantic claim before realization. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Generated world provides seed/intent, placement validation and streaming; there is no convoy claim/profile. Vehicle Scout wreck runtime exists but Asset V2 presentation may still be incomplete.
- Evidence: design/04_architecture/REGION_GENERATION_SYSTEM.md; custodian/game/world/procgen/landmarks/sundered_keep/; design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md
- Task-specific authority: Procgen semantic placement/route safety, event spec §4 and existing vehicle prop contracts.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Separate optional convoy event placement claim/realization under custodian/game/world/procgen/landmarks/ or established generated-event owner; focused seed smoke.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Place optional single convoy 12x10-or-larger safe roadside pocket using existing seed-qualified semantic claim before realization. Layout: three outward-facing static wreck silhouettes, empty central cargo cradle, inspectable manifest stub, open escape. No global mandatory quota; invalid seed/site deterministically SKIPs without failing world generation; streaming reload retains same fingerprint. Static shapes/approved existing art only.
- Preserve: Route ingress, objectives, biome/material surfaces, navigation/collision, other landmarks and accepted seed.
- Non-goals: No convoy combat, salvage, new vehicle raster, restorability, topology rewrite or spawned hostile units.
- Acceptance: Fixed-seed replay stable, multi-seed safety valid, no overlapping required objectives/paths/clearance, absent valid pocket -> safe no-op; unload/reveal repeat same placement.
- Validation: New convoy-placement fixed multi-seed smoke; existing procgen placement/nav/streaming validations, changed-file closeout. Run changed-file validation and git diff --check only after focused smokes pass.
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
- Next action: Complete the focused implementation, land, then run `review-campaign-empty-convoy-placement-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.
