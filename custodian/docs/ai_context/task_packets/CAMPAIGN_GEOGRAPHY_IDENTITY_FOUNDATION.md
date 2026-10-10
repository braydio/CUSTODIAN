# F15-B1 · Persistent Campaign Geography Identity Foundation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-geography-identity-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-campaign-geography-residency-authority-audit`
- Locks: `campaign-geography-identity`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-campaign-geography-identity-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Durable ID/seed/topology authority and cross-system identity boundary require independent deterministic contract review.`
- Reviewed main: `fb2f634bc8587cd49724c01c46c231f870470e30`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Summary backlink: `Include exact Authoring chat URL in all durable implementation, review, correction and closeout handoffs.`
- Goal: Establish the smallest deterministic, inspectable **data-only** F15 authority for persistent Domain/Location/Edge identity and visit-to-Domain references; no new geographic renderer or runtime world loading.
- Completion boundary: A focused geography model/registry module with collision-free canonical addresses, seed and generation-version provenance, validated bounded location/edge adjacency, immutable/read-only resolution and an independent CampaignVisit reference that points to the same Domain across visits; plus deterministic fixture smoke and validation-manifest ownership. No physical scene, procgen, actor, disk-save or campaign-flow migration.
- Current measured state: Accepted F15-A report finds **no production durable (DomainId, LocationId) mapping**: F14 abstract state accepts caller-supplied IDs, RouteSession owns local route/node IDs, GeneratedRegionLevel owns one generated physical region and M6 unloads visual cells only. Fixed-seed local contracts were 224×192/8,900 and 208×192/9,344 candidate reachable cells; neither measured a world footprint. `CampaignSession.session_id` hashes scenario ID and seed, **not** a visit to an enduring Domain.
- Evidence: `design/04_architecture/codebase_systems_audit/F15_GEOGRAPHY_RESIDENCY_AUTHORITY_EVIDENCE.md`; archived F15-A report and accepted review `REVIEW_CAMPAIGN_GEOGRAPHY_RESIDENCY_AUTHORITY_AUDIT_CLAUDE_SUMMARY.md` (main@83e0008e); `custodian/game/state/world/abstract_activity_simulation_state.gd`; `custodian/game/state/run/campaign_session.gd`; `custodian/game/world/routes/route_session.gd`; `custodian/game/world/routes/route_definition.gd`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/systems/simulation/actor_reification_coordinator.gd`.
- Task-specific authority: **User-approved D1–D7** in `design/04_architecture/F15_POST_AUDIT_GEOGRAPHY_AND_LIVING_WORLD_DECISION_RECORD.md` and `design/04_architecture/CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md`. F15 owns geographic identity/topology; F06/CampaignSession owns live campaign visit lifecycle; F02 owns generation/physical levels; F14 owns abstract actors and canonical fixed steps; REMAP-3 owns process-restart persistence. Hall metadata/semantic systems remain dependency-gated.
- Work surface: Prefer a small focused **new data-only geography owner** under `custodian/game/world/geography/` (or exact existing equivalent after source inspection); one focused new validation smoke under `custodian/tools/validation/` plus direct `custodian/tools/validation/validation_manifest.json` ownership mapping; update only the design/current-state references that change when the model lands. Read `campaign_session.gd`, `route_session.gd`, `abstract_activity_simulation_state.gd` as interface constraints, not permission to migrate them.
- Change: Implement a deterministic **finite v1 topology** registry with validated `domain_id` and location-scoped `location_id` (compatible with F14 bounded ASCII identity grammar); independently stable `edge_id` with explicit adjacency and reciprocal edge validation or explicitly marked one-way topology. Provide a canonical **injective/collision-free address key** (structured fields or length-prefix encoding) rather than plain dotted concatenation, including valid dotted ID pairs. Preserve generator **seed and schema/generation-version provenance** per Domain/location without using randomized process hash, runtime node instance ID or Visit seed as permanent place identity. Expose read-only descriptor and deterministic finite fixture-generation/registration/lookup with clear last-error/rejection reasons and duplicate/unknown-neighbor guards. Introduce only the **data representation** of `CampaignVisit`→stable `DomainId` and current/entry `LocationId` reference. A second visit must reuse the same Domain geography/seed and resolve identical locations; do **not** alter current `CampaignSession` lifecycle or save semantics. Initial fixture may use explicitly provided two-location Domain definitions rather than a whole-world generator. Keep bounded input and stable ordering regardless of Dictionary iteration.
- Preserve: Current `RouteSession` identity and `@world_origin` sentinel; F14's `DomainId`/`GroupId`/`ActorId` grammar and backwards-compatible snapshots; F02 level/route staging, current seed-based local maps, M6 presentation streaming, user-approved bounded-offscreen F14 clock and REMAP-3 disk-save ownership. Location IDs do not change with route visit, profile, camera, spawn or scene instance. Invalid or unknown geography never silently enters production simulation.
- Non-goals: **No F15-B2** semantic site/biome/road/water seam adapter, terrain generator, scene materialization or streaming/LOD; **no F14-C2** actor reservations, camp/spawner changes, physical handoff or reification; no F15-C traversable two-site proof; no Visit↔session runtime activation, world-map UI, authored assets, lore placement, artwork, Procgen Ruins, World Autopsy, F09 vehicle code, REMAP-3 disk migration, new clock or changed existing route/region outputs. Leave numeric world size, exact streaming mechanism and performance budgets unset.
- Acceptance: **A1** two fixed-seed finite Domain fixture definitions, each with at least two distinct locations and a declared connection, produce byte/structure-equivalent normalized IDs, seeds, version and ordered adjacency across fresh registry construction; **A2** two distinct visits referencing the same Domain preserve the same canonical location/edge identity and generator provenance without sharing a visit ID; **A3** collision-safe keys distinguish dotted-but-valid components that would alias under naive delimiters, and reject empty, illegal, overlength or duplicate IDs; **A4** unknown neighbor/edge targets, conflicting reciprocal mapping, duplicate edges, unsupported schema/generator version and bad provenance reject deterministically without partial mutation; **A5** an explicit route-node/level-ID coincidence never silently becomes geographic identity; **A6** registry remains RefCounted/data-only with **zero** gameplay scene instantiation, physical actor handoff, game-session mutation, disk write or new auto-loaded singleton; **A7** one narrow headless Godot fixture prints PASS after required editor import and has a tested failing negative control, manifest coverage maps all new runtime files to that focused smoke; **A8** current downstream F02/F14/F06/REMAP boundaries and active docs remain truthful.
- Validation: First inspect current workstream claims and actual authoritative classes. Add a **new** focused Godot geography-identity smoke (filename chosen during implementation), exercise A1–A7 with explicit rejection assertions, and register it for changed-file selection in `custodian/tools/validation/validation_manifest.json`. Run an explicit Godot editor import in a fresh worktree **before** the focused headless smoke to populate global-class/import caches. Require **both exit 0 and the fixture's PASS marker**. Then run directly relevant F14 abstract-state identity and route-definition/route-session focused fixtures **only if interfaces are actually touched**; run `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`. Complete with required task completion-truth, execution-feedback, paired review, authoring/backlink and workstream closeout gates. Do not run a broad Godot suite or assume `--quit` proves acceptance.
- Task overrides: `none`
- Deferred: B2 semantic site/seam metadata, Encounter Language, Landmark Hierarchy, Spatial Compression and Mystery Budget **mechanics are already designed but not implemented in B1**; C2a actor slot reservations, C2b geographic reification, F15-C physical traversal and all further Hall ideas stay in the dependency register; Ritualant underground-ingress rejection belongs to the existing F02 level/procgen owner and is not an A1–A8 identity test failure.

## Exact minimal execution boundary

1. **Source reconciliation:** verify no competing Domain/Location registry landed after this packet's `Reviewed main`. If one did, incorporate into that authoritative source rather than creating a parallel registry; stop and return for a human scope refresh if it changes approved D1–D7.
2. **Model/registry:** code the data authority and canonical identity contract. A seed defines persistent Domain locality geography, a Visit only references it. Keep descriptor serialization **representation-only** (for eventual REMAP-3 use), not persistence implementation.
3. **Test:** create two deterministic Domain fixtures plus re-instantiation and malformed-input negative controls. The initial test should run fast and should not load full expensive contract maps.
4. **Integration restraint:** add only the smallest evidence-backed read-only conversion seam, if any; do **not** wire actual routes/scenes/actors or modify `campaign_session.gd` merely to demonstrate an interface.
5. **Documentation:** update the accepted design record and `CURRENT_STATE.md` only with the actual newly implemented scope, marking all physical residency and traversal behavior **not yet implemented**.

## Packet publication / preclaim gate

**Promotion receipt:** The user authorized `ready/auto` promotion after validation against the current main snapshot, and authorized the B1 claim only after the publication PR is merged and both packets plus the index are verified on current `main`. This publication branch must not claim or implement B1. Never hand-edit the managed index.

## Next Handoff

- Next workstream: `review-campaign-geography-identity-foundation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: `none; D1–D7 already approved and B1 is explicitly bounded`
- Next action: After the publication PR merges, verify both packets and the managed index on current `main`, then claim only `campaign-geography-identity-foundation` through the dispatcher.
- Blockers or open questions: `Publication PR must merge before verification and B1 claim; no implementation work occurs on this publication branch.`
