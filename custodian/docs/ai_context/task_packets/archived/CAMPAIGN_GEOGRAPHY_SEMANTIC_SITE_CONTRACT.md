# F15-B2 · Canonical Geographic Semantic Site and Edge Binding Contract

- Packet schema: `custodian.task_packet.v2`
- Workstream: `campaign-geography-semantic-site-contract`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-campaign-geography-identity-foundation`
- Locks: `campaign-geography-semantic-contract`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-campaign-geography-semantic-site-contract`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `An address-to-generation semantic projection needs independent review to prevent a second geography authority or fictitious physical edges.`
- Reviewed main: `84c7eb1f8a2ee8c2e4936b9df9afa8ea7e1672d1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Summary backlink: `Include this exact Authoring chat URL in implementation/review/correction/closeout summaries and Next Handoff.`
- Visual review: `none`
- Goal: Provide a bounded deterministic **read-only semantic sidecar** that maps previously accepted `CampaignGeographyRegistry` addresses and logical edge IDs to **validated F02 level/profile source references and intended crossing/ingress metadata** without materializing or streaming a world.
- Completion boundary: One cohesive semantic-plan/validation authority plus a focused headless deterministic smoke (and validation manifest ownership), with two site definitions and a canonical edge in an existing B1 Domain fixture. No runtime scene staging, actor, actual terrain, new authoritative B1 topology fields, or physical transit; no competing F02 registry.
- Current measured state: B1 is accepted and archived, with `CampaignGeographyRegistry` schema 1/`geo-v1`, SHA-256 locality provenance, collision-safe Domain+Location key, defensive copies, reciprocal undirected edges and explicit directed arcs. It has **no** site purpose, source adapter, semantic cue schema or physical crossing proof. `GeneratedRegionLevel.prepare_generated_region()` takes F02 `scene_path/seed/map_size/profile/spawns` and validates its own gameplay spawn, while `LevelLoader.stage_level_async()` owns real staging. `RouteEdgeDefinition` describes route node/exit/target-spawn/transition style, which is **not** a canonical geographic edge.
- Evidence: `REVIEW_CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION_CLAUDE_SUMMARY.md` (independent PASS); `custodian/game/world/geography/campaign_geography_registry.gd`; `custodian/game/world/geography/campaign_visit_reference.gd`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/levels/generated_region_level.gd`; `custodian/game/world/routes/route_edge_definition.gd`; `custodian/game/world/routes/route_definition.gd`; F15-A geography audit/report. Do not extrapolate the separate measured local maps into a global physical seam.
- Task-specific authority: **User-approved 2026-10-10** B2 contract in `design/04_architecture/F15_B2_F14_C2_POST_B1_PLANNING_REFRESH.md`, previous D1–D7 lock in `design/04_architecture/F15_POST_AUDIT_GEOGRAPHY_AND_LIVING_WORLD_DECISION_RECORD.md`, Hall dependency register. F15 owns identifiers/topological relationship; F02 owns real level and procgen generation, spawn validity, navigation, stage and route activation; F14 owns population and REMAP-3 disk persistence. The approved B1 `geo-v1` schema must not be casually expanded.
- Work surface: Prefer a focused **RefCounted, data-only** sidecar under `custodian/game/world/geography/` (inspect existing equivalent first). Read canonical B1 resolve APIs and existing F02 level/profile/source descriptors. Add one narrow future headless Godot semantic-site fixture and exact manifest ownership; avoid edits to `proc_gen_tilemap.gd`, `route_traversal_manager.gd`, `generated_region_level.gd` or `level_loader.gd` unless an actual minimal **read-only lookup seam** is proved necessary. No autoload.
- Change: Register or compile a **separately versioned** input semantic plan per existing canonical Domain+Location key; record source kind (`generated_region` / `authored_level`), stable *typed reference* to a **real existing F02** level/profile (reject unknown references via existing registry/definitions or a source catalog that delegates to them), explicit versioned source/generator provenance, authored override precedence, source-purpose/tags and a sorted list of canonical B1 edge bindings. Verify each `edge_id`, direction and `target_location_id` by B1 lookup. Treat intended physical exit/ingress as an **unverified requirement** until F02 proves the real exit/anchor; distinguish `planned`, `verified` only when passed an explicit authentic F02 proof, and `rejected`. Default to `planned`; never implicitly mark real physical continuity `verified`. If both ends of one undirected road are declared in the plan, cross-check their correspondence, reject contradictions atomically; typed one-way authored transit must not be made reciprocal by convenience. Return stable ordered defensive-copy descriptors with collision-safe source keys; do not derive immutable terrain from Visit ID or mutate the underlying B1 registry.
- Optional semantic slots: Include **optional bounded data slots only**, with strict provenance and referential validation: Encounter Language `motif_id + truth_source_ref` tied to a declared real encounter/route/reward fact (or explicit `unresolved` not painted as true); Landmark Hierarchy `landmark_id + role(dominant/supporting/local) + location address + intended approach edges`; Spatial Compression `same landmark identity far/near` and future sightline intent without distances/LOD implementation; Mystery Budget `mystery_ref + authored_canon/unknown_origin + reveal policy` with no invented canon answer or quota; procedural ruin *only* site/room-purpose and failure-cause hint **references**, not generated props/loot/damage. An optional absent category must remain valid. Use bounded collections and deterministic sort, reject duplicate IDs and claims contradicting authored override/canon. Prefer small schema delegates rather than building Hall gameplay owners inside B2.
- Preserve: B1 `geo-v1` register semantics, acceptance fixtures, ID grammar, seed/version/hash bytes and reciprocal-arc validation; actual F02 level, procgen and route owners, camera/Operator/Archive/Hub ingress, M6 visual chunks, F14 managed actors, CampaignSession lifecycle and REMAP-3. A sidecar rejection leaves **no partial registration** and never stages or changes an actor.
- Non-goals: No **F14-C2a/C2b** reservation/reification; no physical scene activation, region streaming, chunk policy, procedural road/water generation, navigation recompute, seamless player crossing or F15-C; no pixel/km scale, LOD, biome quota, runtime assets/manifest, placement of actual encounter signs/landmarks, world events, faction knowledge, authored ruin damage, World Autopsy or save migrations. No new `geo-v2` B1 schema without separately approved migration.
- Acceptance: **B2-01** Two-location existing B1 Domain and fixed-provenance site plans normalize identically after input reordering, repeated visits and registry reconstruction; original B1 source descriptors unchanged. **B2-02** A canonical undirected B1 edge maps only to matching reciprocal site intentions (when both supplied), while directed transit remains directed; cross-Domain/unknown neighbor/edge/alias mismatch fails closed without mutation. **B2-03** Unsupported sidecar/schema or generation version, stale seed, wrong F02 level kind/source, unknown F02 source, contradictory authored override, duplicate cue/landmark/mystery references and false truth-bearing encounter cue are rejected with inspectable reasons; corrected retry can then succeed. **B2-04** Source-kind and ingress status remain explicitly *planned* until a valid real F02 proof; missing physical ingress never creates a successful world-crossing claim. **B2-05** Optional empty Hall slots work, nonempty categories use canonical typed/normalized IDs and preserve authored canon without gameplay or art. **B2-06** Zero `Node` instantiation, physical world/map generation, route movement, population mutation, new singleton or filesystem persistence; F02 owns original generator behavior. **B2-07** A new focused smoke and negative control run after editor import with exit status and PASS marker checked; register new runtime-file and smoke ownership in validation manifest, retain B1 smoke regression. **B2-08** `CURRENT_STATE.md` and design documentation identify B2 as *semantic planning only*, physical seam unproved and C2b/F15-C still outstanding.
- Validation: Before implementation check fresh `origin/main` for concurrent F02/B1 owner changes and claim/lock overlaps. Construct *one focused new* Godot SceneTree smoke (name chosen by Codex at creation) with two deterministic site definitions, reordered acceptance, all critical negative controls and a deliberate nonzero negative-control mode. Run Godot editor import **first** to populate fresh class/import cache; run new smoke with both exit code 0 and explicit PASS marker, negative mode nonzero; rerun `custodian/tools/validation/campaign_geography_identity_smoke.gd`. Map all newly added runtime/fixture files to focused test in validation manifest; run `python3 custodian/tools/validation/run_validation.py --changed --base HEAD --test <actual-test-id> --json`, index/AI-context/pairing only as required by completion, and `git diff --check`. Do not claim a full physical crossing from a data fixture or broaden to unrelated Godot suites.
- Task overrides: `none`
- Deferred: Actual physical site/road/shoreline/ingress seam stage and measured travel (F02/F15-C), logical-actor reservations (C2a), F14 real locality residency (C2b), real Encounter Language visual assets/landmark sightline budget/mystery placement, Procedural Ruin Generator, World Autopsy, signal/faction graph and persistence remain separately gated.

## Implementation order

1. Inspect B1 data contracts, existing F02 registry/route profile definitions and materialization request truth. Reconcile owner before inventing any extra mapping table.
2. Implement only the bounded **semantic projection** with explicit source-resolution/read-only guard, optional metadata slots and exact normalized failure reasons. Validate entire candidate before commit; no new topology authority.
3. Write focused deterministic plus adversarial test; prove two locations share B1 edge truth and their projected sources remain `planned`, not a fake loaded world. Include distinct Domain collision and authored override negatives.
4. Register manifest ownership, update one concise current-state paragraph, and close out with exact authoring-chat backlink, execution feedback and completion truth.

## Promotion / review gate

This pair is **draft/manual solely pending actual repository-native targeted authoring validation**, NOT an unresolved human architecture decision. User approved this slice separately on 2026-10-10. Run `validate_task_packet_authoring.py` against B2 and its exact REVIEW peer, then move both to `ready/auto` only after PASS; repeat validation, generate/check the managed index, run repo pairing/AI-context/changed-file checks and publish on current main. Do **not** claim while parked and do **not** execute B2 during authoring.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `custodian/game/world/geography/campaign_geography_semantic_registry.gd` and `custodian/tools/validation/campaign_geography_semantic_site_smoke.gd` implement and falsify the bounded data-only sidecar; the new smoke and negative control, existing B1 identity smoke, focused 1/1 changed-file validation with complete coverage, AI-context check, review-pairing check, task-packet index check, and `git diff --check` all pass. The documented boundary explicitly excludes physical proof, staging, terrain, actors, persistence and traversal.

- B2-01 through B2-08: **PASS** for the bounded semantic sidecar contract. The new deterministic smoke covers reordered plans, repeat visits and reconstructed B1 state, canonical directed/undirected edge intent, source resolution, optional typed references, atomic rejection/retry, and absence of Nodes or physical materialization.
- New smoke `custodian/tools/validation/campaign_geography_semantic_site_smoke.gd`: imported through Godot editor first; positive run exited 0 with `CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: PASS`; `--negative-control` exited nonzero with `CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: NEGATIVE CONTROL`.
- Existing `campaign_geography_identity_smoke.gd`: exited 0 with `CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: PASS`.
- Focused changed-file validation: `campaign_geography_semantic_site` passed 1/1, zero failures, complete coverage, no infrastructure errors.
- Repository checks: `check_ai_context.py` PASS; review pairing PASS (63 auto packets); `git diff --check` PASS.
- No F02 physical ingress proof exists in the inspected runtime contract; the implementation rejects `verified` claims and leaves ingress planned. No scene staging, terrain generation, actor/residency, persistence, scale or traversal was added.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial focused smoke iterations exposed fixture typing and invalid test-fixture assumptions; corrected before final validation.
- Root cause / contributing factors: Godot's typed-array boundaries and directed-edge fixture required matching existing B1 topology exactly.
- Prevention / pipeline improvement: Keep the semantic fixture typed to the live B1 API and preserve explicit positive, negative-control, and regression runs.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Focused validation manifest selection provided complete coverage and the intended single-test run.

## Next Handoff

- Next workstream: `review-campaign-geography-semantic-site-contract`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none; implementation is complete and the paired review is the immediate successor.
- Next action: Archive and land this implementation, then launch its independent review from a fresh reviewer context with `paired_review_runner.py`.
- Blockers or open questions: none for B2 implementation; physical F02 ingress proof, C2b residency, numerical scale and F15-C traversal remain separately gated.

## Independent Review

- Status: `passed`
- Review schema: `custodian.independent_review.v1`
- Reviewer provenance: `different-agent`
- Reviewed implementation SHA: `bb6b17cb8c1ff2456866fa143d2ed82adfba5ef8`
- Verdict: `pass`
- Findings: `none`
- Evidence: The paired reviewer reconstructed the implementation from this archived packet, its root summary, live source and the landed diff at `bb6b17c` (parent `4b5ba4c`). Fresh Godot import completed; the registered semantic-site smoke exited 0 with its literal PASS marker; the deliberate negative control exited 1 with its expected marker; the B1 identity regression exited 0 with its PASS marker. Focused changed-file validation selected `campaign_geography_semantic_site`, passed 1/1 with complete coverage and no infrastructure errors. Independent mutations rejected mismatched reciprocal ingress refs, forged `verified` ingress, and an unsupported F02 level, preserving the registered baseline after every rejection. `git diff --check bb6b17c^ bb6b17c` passed. Source inspection confirmed the B1 registry remains topology authority, F02 remains level/generation authority, semantic plans are atomically replaced and defensively copied, truth-bearing encounter cues remain unresolved, and the sidecar does not instantiate Nodes or stage/generate a world. No confirmed B2-01..08 defect or material evidence gap remains. No physical traversal, scale, residency, streaming or art claim was credited.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31`
