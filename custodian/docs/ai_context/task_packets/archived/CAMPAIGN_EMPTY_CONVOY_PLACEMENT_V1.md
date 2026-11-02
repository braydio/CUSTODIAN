# GENERATED CONVOY POCKET PLACEMENT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-empty-convoy-placement-v1`
- Status: `complete`
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
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0`
- Visual review: `conditional`
- Goal: Generated convoy pocket placement; deliver one playable, bounded event slice.
- Completion boundary: Place optional single convoy 12x10-or-larger safe roadside pocket using existing seed-qualified semantic claim before realization. Close only with real runtime integration and focused proof, not a disconnected demo.
- Current measured state: Generated world provides seed/intent, placement validation and streaming; there is no convoy claim/profile. Vehicle Scout wreck runtime exists but Asset V2 presentation may still be incomplete.
- Evidence: design/04_architecture/REGION_GENERATION_SYSTEM.md; custodian/game/world/procgen/landmarks/sundered_keep/; design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md
- Task-specific authority: Procgen semantic placement/route safety, event spec §4 and existing vehicle prop contracts.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: `custodian/game/world/procgen/special_rooms/special_room_runtime_inserter.gd`; `custodian/content/procgen/special_rooms/empty_convoy_v1.json`; `custodian/game/world/events/campaign/empty_convoy_site.gd`; `custodian/game/world/events/campaign/empty_convoy_site.gd.uid`; `custodian/game/world/events/campaign/empty_convoy_site.tscn`; `custodian/tools/validation/campaign_empty_convoy_placement_smoke.gd`; `custodian/tools/validation/campaign_empty_convoy_placement_smoke.gd.uid`; and `custodian/tools/validation/validation_manifest.json`.
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
- Next action: Audit the paired review after implementation lands; await coordinator control before launching it.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Commit `47fd0755203dc22fb7149889253154741c78689b` adds the deterministic optional 12x10 generated site, validates its navigable footprint and two-tile protected-semantic clearance before floor claiming, and provides the static inspectable convoy arrangement. The four-seed smoke passed with three placed sites and one safe skip, including route/ingress safety, manifest inspection, and streaming reveal idempotence. Committed-source changed-file validation passed 5/5 selected checks with complete coverage and zero failed, timed-out, skipped, or infrastructure-error checks; report `/tmp/campaign-empty-convoy-placement-validation.json`, SHA-256 `bc0db96d3a41e6cbb32ba06935eb1464c0d96a0ee1cfbfe8b63ee63d35219b50`. The smoke emitted only the existing report-classified object/resource leak warnings.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `Initial smoke iterations used untyped arrays for a dynamically called typed API, assumed a 96x80 map would contain a 12x10 navigable pocket, and attempted to free a RefCounted helper.`
- Root cause / contributing factors: `Dynamic GDScript calls enforce typed-array signatures at runtime; generated terrain at the smaller fixture size did not contain an eligible site; RefCounted objects are released by reference lifetime.`
- Prevention / pipeline improvement: `Keep fixture arguments explicitly typed, use sufficiently large generated maps for large authored pockets, and do not manually free RefCounted helpers.`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: `Four real generated seeds verified safe placement and skip behavior plus streaming idempotence before committed-source coverage validation.`
