# F15-B2 / F14-C2: Accepted B1 Handoff and Implementation-Narrowing Refresh

**Status:** **USER-APPROVED 2026-10-10** for **separate F15-B2 semantic-site and F14-C2a managed population-reservation packet authoring**. D1–D7 remain the prior approved overarching architecture. Approval authorizes two narrow V2 implementation/fresh-review pairs and normal validated queue publication, **not implementation in the planning workstream**. F14-C2b, F15-C, physical streaming, numeric scale and art remain independently gated.  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31  
**Source baseline:** `origin/main@03a584ee436cba35cc5f350bfc2e6e557a289fab`, 2026-10-10.  
**Accepted predecessor:** implementation `f6c86020af0af7abaf65bbe45774a6ac23d7878f`; [implementation summary](../../CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION_CLAUDE_SUMMARY.md); [fresh PASS review](../../REVIEW_CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION_CLAUDE_SUMMARY.md); [archived implementation packet](../../custodian/docs/ai_context/task_packets/archived/CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION.md). No blocking defects, material gaps, non-blocking issues or correction needed.

**Authority and related plans:** [D1–D7 approved contract](F15_POST_AUDIT_GEOGRAPHY_AND_LIVING_WORLD_DECISION_RECORD.md), [Campaign World topology doctrine](CAMPAIGN_WORLD_GEOGRAPHY_AND_TOPOLOGY.md), [prior F14-C2/F15 boundaries](F14_C2_F15_PRODUCTION_GEOGRAPHY_AND_RESIDENCY_REFRESH.md), [Hall idea dependency register](codebase_systems_audit/CODEX_IDEA_DEPENDENCY_REFRESH_REGISTER.md), [F15 roadmap](codebase_systems_audit/PACKET_ROADMAP.md). F15 geography identity, F02 scene/generation, F04 spawning, F06 visit/session, F14 fixed-step actors, F09 vehicles and REMAP-3 save/restart each retain their own owner.

**Human decision receipt (2026-10-10):** The user explicitly approved two *separately owned* designs, F15-B2 `campaign-geography-semantic-site-contract` and F14-C2a `living-world-population-slot-reservations`, with independent fresh post-land review packet pairs, targeted authoring validation and normal queue publication. The user explicitly forbade implementing them during this authoring request and preserved the C2b/F15-C/streaming/scale/art gates. Exact authoring conversation: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31 . Current source baseline for this packet-authoring pass: `origin/main@84c7eb1f8a2ee8c2e4936b9df9afa8ea7e1672d1`; repository state may advance between authoring and dispatch, so review current main again before claiming.

## F15-B2 implementation status (2026-10-11)

F15-B2 now has a versioned, bounded `CampaignGeographySemanticRegistry` sidecar over the accepted B1 registry and F02 `LevelRegistry`. It binds existing Domain/Location addresses to typed authored/generated level references and canonical logical B1 edges, sorts and defensively copies semantic descriptors, and validates optional Encounter Language, Landmark Hierarchy, Spatial Compression, Mystery Budget and ruin-reference slots. Real F02 ingress proof is not available in this slice, so every physical ingress remains `planned`; the sidecar never loads a scene, generates terrain, changes B1 topology, or claims a traversable crossing. The implementation smoke and B1 identity regression pass. F15-B2's independent review is pending. F14-C2b residency, physical seam proof, numeric scale, art and F15-C traversal remain gated.

## 1. Accepted B1 contract that all new slices must consume

`custodian/game/world/geography/campaign_geography_registry.gd` provides `CampaignGeographyRegistry` (RefCounted) with: finite bounded registries (up to 64 Domains, 128 Locations and 256 edges per Domain), 1–64-character F14-compatible ASCII IDs, schema `1`, generation version `geo-v1`, bounded nonnegative Domain seed, SHA-256-derived location seed/provenance, injective UTF-8 **byte-length-prefixed** `location_address_key(domain_id, location_id)`, deterministic sorted descriptors and defensive copies. An undirected edge requires **two reciprocal arcs sharing one edge ID**; explicit one-way transit is supported. Complete candidate validation precedes mutation. `resolve_domain` / `resolve_location` return read-only-by-copy facts. B1 edges are **logical adjacency**, **not** scene transfer triggers, physical footprints, proven roads, walkable seams, camera horizons or network signals.

`custodian/game/world/geography/campaign_visit_reference.gd` provides a **data-only** `CampaignVisitReference` with distinct visit ID, Domain ID, entry/active Location IDs and sorted accessible edge IDs. It does **not** take over `custodian/game/state/run/campaign_session.gd` or bind a live accepted Contract.

The completed B1 smoke `custodian/tools/validation/campaign_geography_identity_smoke.gd` was run after Godot editor import, exited 0 with `CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: PASS`; expected negative control exited 1, and a separate reviewer reconstructed and adversarially tested identifiers and atomic rejection. Changed-file selection passed 1/1. At the accepted B1 baseline, no B2, C2, F15-C, geometry materialization, physical transfer or disk-save behavior was implemented; the dated F15-B2 status above records the later bounded semantic slice.

### Live owner map / confirmed missing seam

| Live source | Existing behavior | Do not mistake it for |
| --- | --- | --- |
| `CampaignGeographyRegistry` + `CampaignVisitReference` | Stable Domain/site/edge identifiers, versions, sorted adjacency and visit reference | Physical neighbor geometry, generated site purpose, loaded scene residency |
| `GeneratedRegionLevel.prepare_generated_region` | Stages one F02 generated region from `scene_path/seed/map_size/profile/spawns` and checks canonical playable spawn | B1 location identity, cross-locality seam correspondence, accepted geographic travel |
| `LevelLoader.stage_level_async/commit_staged_level` | Existing F02 staged level and actor activation/rollback, with real named ingress | Domain-scoped residency orchestration or safe F14 anchor mapping |
| `RouteTraversalManager` / `RouteSession` | Route/node edge and entry/exit lifecycle, existing fade/occluded/playable-blackout styles | Geographic edge continuity, road/water/landscape equivalence, permanent Domain Location key |
| `AbstractActivitySimulationState` / `ActorReificationCoordinator` | F14 Domain/Group/Actor identities, fixed-step handoff, **synthetic location anchors**; coordinator currently looks up `anchors.get(location_id)` | Safe Domain-qualified real locality activation (same LocationId is legal in different Domains) |
| `AmbientEnemyCamp` / `AmbientEnemySpawner` | Camp caps and `_queued_or_spawned_count`, scheduled `_spawn_queue`, callbacks and marker dedupe; `queue_enemy_spawn` accepts no managed ActorId/slot | Exactly-once reservation/cancel for a F14-managed actor |
| M6 `ProcGenTilemap` chunks / Interest Management | Presentation and activity-tier caching | Geographic place ownership, physical actor abstraction |
| `CampaignSession` / REMAP-3 | Existing session outcome and future canonical durable save boundary | An automatically persistent B1 Domain visit integrated with active gameplay |

The original real ambient spawn smoke remains constrained by **Ritualant underground-ingress resolution**, with F02/level/procgen owner. Source-inspected duplicate interleaving is still a **risk to cover**, not a reproduced game-world duplicate.

## 2. Recommended F15-B2 contract: semantics and F02 address binding, NOT world streaming

**Recommended workstream:** `campaign-geography-semantic-site-contract` (conceptual; no active implementation/review packet yet).

**One completion boundary:** a **versioned, deterministic, bounded read-only geographic materialization plan** keyed by the *existing B1 address and edge identities*. It validates prospective site purpose and edge/ingress correspondence against existing F02 level/generated-region definitions without modifying the B1 `geo-v1` topology contract, instantiating extra gameplay scenes or expanding to a real world streamer. The F02 owner remains responsible for actually generating/loading the physical region, walkability, spawn clearance, rollback and scene lifetime.

Recommended conceptual schema, **not** a prescribed Godot class/field API:
```text
LocationMaterializationPlan {
  schema_version, domain_id, location_id, geography_generation_version,
  locality_seed, source_kind: generated_region | authored_level,
  source_ref: F02 profile/level reference, authored_override_ref?,
  region_semantic_tags[], material_profile_refs[],
  edge_bindings: [{
    canonical_edge_id, from_location_id, target_location_id,
    physical_exit_ref?, physical_entry_ref?,
    ingress_validation: planned | verified | rejected,
    crossing_kind: road | trail | gate | water | authored_transit,
    alignment_intent? /* no invented numeric world offsets */
  }],
  landmark_candidates[], encounter_cue_candidates[], mystery_clue_refs[],
  optional_future_ruin: {site_purpose?, room_purpose?, failure_cause_hint?}
}
```
**Safety / versioning:** bind using `location_address_key`, re-resolve B1 Domain/Location and edge relationships on every acceptance; preserve original `geo-v1` input schema. If new permanent semantic fields are eventually promoted into B1 itself, that is a **separate explicit schema/generation migration** with deterministic compatibility tests. For B2 prefer a versioned *sidecar projection* rather than silently adding new keys or an independent geographic topology store. `F02` source references are adapters, **never alternative location IDs**. Reject stale provenance, unknown edges, source mismatch, directed/undirected confusion, contradictory authored site reservations and missing ingress with a clear reason; do not auto-convert a data edge into a playable scene transition.

**Hall mechanics, B2 schema stage only**:
- **Encounter Language:** candidate `motif_id` with `truth_source_ref` (approved encounter, safe reward or validated route state), biome presentation family and opt-in authored-site policy. A cue that promises a nonexistent encounter is rejected; no art/placement/AI.
- **Landmark Hierarchy:** candidate `landmark_id`, `dominant | supporting | local`, physical/semantic site address, prospective approach edges and authored precedence. Do not lock specific count or camera horizon without actual F15-C proof.
- **Spatial Compression:** reserved intended far/approach/near landmark identity and vista/occlusion constraints; **no** fabricated pixel horizons, world-kilometers, teleport seams, new renderer or landscape footprint.
- **Mystery Budget:** bounded non-canonical `mystery_ref` / clue provenance and reveal policy only; no random answers that contradict authored lore and no collectible quota.
- **Procedural Ruins:** **only** site/room purpose, material and failure-cause references; no damage propagation/loot/geometry/assets. Reuse existing Material Intelligence source types.

**First bounded B2 acceptance (proposed; must pass focused and independent review before C2b):** B2-1 same B1 Domain/edge, reordered semantic input and two synthetic site mappings produce identical normalized address-keyed plans across visits; B2-2 both reciprocal physical-edge binding descriptors agree or fail before any stage; directed authored transit remains explicitly different; B2-3 invalid source profile/level, unknown entry, malformed cue ownership, stale location seed or contradictory authored override reject atomically; B2-4 no `ProcGenTilemap` / `LevelLoader` / `RouteTraversalManager` mutation or new disk/Actor authority; B2-5 original B1 adversarial smoke unchanged; B2-6 **smallest F02 read-only integration/probe** proves one real existing generated ingress in a real loaded fixture only where necessary, clearly labelling unmet physical-seam proof as deferred. Do **not** require expensive multi-site generator success to pass a purely data-only contract.

**Unresolved technical gate for later scene integration:** B2's validated edge *intention* is not a guaranteed traversable boundary. Real exit position, world transform orientation, road/water continuity, safe navigation, pre-stage lifetime and Operator camera handoff need F02/route evidence before any C2b physical transfer or F15-C claim. This can be a distinct **F02 physical-ingress/seam proof** or the accepted, specifically bounded physical prerequisite in C2b after architecture choice. It is **not** implemented by B2 metadata.

## 3. Recommended F14-C2a: reserve managed actors BEFORE camp/spawn queue

**Recommended workstream:** `living-world-population-slot-reservations` (conceptual; no active packet yet). **May follow accepted B1 independently of B2**, but production route integration waits for B2/F02.

An F14-managed **logical actor slot** is `(DomainId, GroupId, ActorId)` with the current `LocationId` as an association, not part of actor identity. Source of existence, condition and location remains `AbstractActivitySimulationState`; a small transient reservation broker/adapter controls **physical allocation requests only** (pending, claimed, consumed, canceled) and must not invent a second faction actor log, clock or save file. All compound keys must be collision-free and scoped; a B1 Domain+Location key alone is insufficient for actor identity.

The relevant actual race is `AmbientEnemyCamp.spawn_camp` → `AmbientEnemySpawner.queue_enemy_spawn` → deferred dequeue `_spawn_queued_enemy`: current queue stores scene, parent, position, camp ID, completion callback and ordinal, but **no managed ActorId reservation or cancellation token**. Marker-level `ambient_enemy_camp_created` prevents duplicate camp creation, **not** a later actor reification collision.

Proposed reservation outcome contract:
```text
reserve_managed_slot(domain, group, actor, current_location, camp_source, epoch)
 -> token | rejected(reason)
queue_managed_spawn(token, validated_spawn_provenance) -> accepted | rejected(reason)
consume_or_cancel(token) -> consumed | canceled | rejected(reason)
query_slot(token/actor_address) -> current status, source and epoch
```
A managed spawn must validate the F14 group record and location, hold one outstanding token, revalidate at dequeue **immediately before** any `PackedScene.instantiate()`, re-check live actor existence/reification claim, then mark exactly one consumption on successful completion. Cancellation must invalidate queued callbacks and protect against ABA/stale requests via token generation or epoch. A failed safe spawn, canceled queue, destroyed camp, and callbacks arriving late must deterministically release/cancel the logical claim and reconcile `_queued_or_spawned_count` and global pending/active limits. Do not treat a canceled queued spawn as alive or permanently spend a camp cap. Existing **unmanaged** ambient slot / encounter semantics must stay behavior-equivalent.

**C2a first validation:** two queued requests for same Domain/Group/Actor result in at most one eligible token; cancel before dequeue produces **zero physical actor and no leaked quota**; stale callback after cancellation cannot reclaim the slot; two Domains with identical Group/Actor strings remain distinct; returning F14 projected actor blocks a duplicate camp slot; repeated visit doesn't create a new managed ActorId; unmodified unmanaged marker/camp quota and two-spawn behavior pass. An isolated camp/spawner test with a **valid canonical anchor** is sufficient; the unrelated Ritualant underground-ingress fixture failure must not be mocked into a false successful production world spawn.

**Boundary:** C2a does **not** call `ActorReificationCoordinator.request_physical`, own geographic scene lifecycle or implement distance/camera-driven transfer. It prepares the exclusive allocation seam so a later C2b may commit residency safely.

## 4. Recommended F14-C2b: transactional real locality residency, after B2 and C2a

**Recommended workstream:** `living-world-locality-residency-binding`; keep **dependency-gated**, not immediately claimable.

- Stage a location whose **B1 identity + B2 F02 materialization source** agree, then validate a real finite navigable safe anchor, relevant incoming geographic edge and user-visible continuity. Use the existing `LevelLoader.stage_level_async/commit_staged_level` and `RouteTraversalManager` contracts rather than constructing a competing scene manager.
- Commit actor abstract↔physical truth at the single existing `SimulationKernel.fixed_step_boundary` through the F14 coordinator; reject multiple claims and pending managed spawns. Keep previous physical scene and actor authoritative until target and handoff succeeded. On failure: release stage, cancel reservation, unfreeze previous source, preserve actor projection/health/route/camp counts, do not emit a false completed transition. Version/token protects late stage completion after cancellation.
- Fix/prove **Domain-qualified safe anchor resolution** before accepting multi-Domain C2b: `ActorReificationCoordinator._to_physical` presently queries `anchors.get(location_id)` alone despite same LocationId being valid under different Domains. Migrate or adapt safely with explicit `(domain_id,location_id)` canonical compound key and tests for same-name locations in two Domains. Do **not** silently break existing synthetic F14-C1 fixtures; preserve or consciously version/retire the legacy adapter.
- **No camera/M6 interest-as-residency**. Exit-time actor safety must fail closed for active attack, projectile, damage/nav request, loot/corpse/custody, unsafe anchor, contradictory Domain/Group projection or unresolved spawn. Pin source when required.
- No new F14 simulator, clock, WorldStateGraph fork, REMAP-3 save silo or source-owned `ActorId` copies. Scene state and node lifetime remain owned by F02; C2b owns only location-residency coordination with transaction results.

**C2b first proof:** two *real* resolved B1 locations in one Domain, one safe fixture-generated local scene per location; physical→abstract→physical for **one Grunt** through two canonical fixed-step transitions with preserved stable IDs, health/route state, exactly one physical actor, no queued duplicate, source rollback intact after injected missing ingress, invalid anchor and canceled stage. Separate negative: same LocationId in two Domains maps to **different** safe anchors and cannot reify wrong-domain actor. Turning off an M6 visual chunk has **zero F14 representational effect**. This proof is not yet a seamless foot journey or process-restart save guarantee.

## 5. Roadmap and dependency gates

| Sequence | Proposed packet identity / owning slice | Earliest dispatch gate | Must NOT consume |
| --- | --- | --- | --- |
| **Accepted** | F15-A geography audit and review | **complete**, no redo | Runtime reimplementation |
| **Accepted** | F15-B1 `campaign-geography-identity-foundation` and review | **complete**, read-only descriptor authority | New world streaming |
| **Next design → paired authoring** | F15-B2 `campaign-geography-semantic-site-contract` | Explicit acceptance of B2 **semantic sidecar/F02 boundary**, no new numeric scale lock. Create V2 implementation/review pair only after local authoring preflight. | Physical streaming, complete ruin art, F14 actors |
| **Parallel after B1 (separate)** | F14-C2a `living-world-population-slot-reservations` | Explicit acceptance of managed ActorId reservation at existing F04 queue, F14 single actor truth. Separate paired V2 authoring. | F02 scene handoff or simulation rewrite |
| **After reviewed B2 + C2a and real ingress proof** | F14-C2b `living-world-locality-residency-binding` | Independent passes, F02 safe ingress/scene stage evidence, domain-qualified anchor and rollback design; user-facing numeric scene budgets may remain unset | Seamless travel world renderer, new simulation clock |
| **After reviewed B2 + C2b** | F15-C `campaign-continuous-two-site-traversal-proof` | Explicit traveling-player seam, camera/terrain tests, measured walking-time and region transition criteria, artistic/canon decisions | Vehicle proof, disk-save migration, infinite world |
| **Later gated** | F09 vehicles, REMAP-3, procedural ruins/World Autopsy, Line-of-Communication, Faction Knowledge and economy | Their existing owners, real typed network/history inputs and measured triggers | Duplicate graph/clock/ledger |

**Hall status:** Encounter Language / Landmark Hierarchy / Spatial Compression / Mystery Budget: `incorporate-schema-now, defer-gameplay-placement-to-real-physical-proof`; Procedural Ruin Generator: `metadata-reserve-only`; World Autopsy, communications/faction systems, timeline/economy: `defer-with-triggers`; live Material Intelligence / History / WorldStateGraph / Interest / Observatory / Heatmaps / replay tools: `extend-current-owner-after-gap-audit`. None of these are automatically promoted by this planning refresh.

**Assets:** No new visual assets required or authorized now. When a later visual grammar is approved, use Asset Pipeline V2 with `asset_drop/inbox/<family>/<source_name>`, exact live repository destination, required pixel dimensions, real alpha, frame counts, family schema, sourcing/attribution and validation. Do not invent manifests without a real asset family.

## 6. Concrete design sign-off questions and publication instructions

**Approved package (2026-10-10):** (1) F15-B2 is a **versioned semantic sidecar / F02 address-binding contract**, not a new physical-world streamer or mutation of `geo-v1`; (2) F14-C2a is a **managed actor reservation/queue-cancellation boundary** that can proceed independently after accepted B1; (3) F14-C2b stays **unpublished** until real F02 ingress/seam proof and independently reviewed B2+C2a; (4) exact streamed chunk/page size, world kilometers, biome scale, camera LOD and art remain deferred to physical-play evidence. User confirmed this package on 2026-10-10. Packet promotion still requires **green repository-native authoring validations**, generated index and published current-main verification; the approval by itself does not establish mechanical eligibility.

**Execution-authoring instruction following approval:** inspect fresh `origin/main` and `dispatch.py audit` to avoid duplicate workstreams/locks, read root/local AGENTS + current V2 authoring/review templates, author **only B2 and C2a separately** (not a joint giant packet), first `draft/manual` and paired independent review each. Run `validate_task_packet_authoring.py` for each pair before promotion, then if green set pair `ready/auto`, revalidate, run `task_packet_index.py --write` / check, pairing, AI-context and changed-file checks, and land via the normal safe workstream/PR path. No actual implementation begins by this design-document merge. A reviewer for B2/C2a remains fresh context after each implementation archive.

**Implementation validation sketch (not run by this planning task):**
```bash
# In separate claimed worktrees AFTER B2/C2a packet publication:
godot --headless --editor --path custodian --import --quit
# Focused new smoke(s) must then run with exit 0 + literal PASS marker.
python3 custodian/tools/validation/run_validation.py --changed --json
python3 custodian/tools/agent/validate_review_pairing.py
python3 custodian/tools/agent/check_ai_context.py
python3 custodian/tools/agent/task_packet_index.py
git diff --check
```
Keep fixture IDs/asset metadata exact; avoid needless full Godot sweeps. Current code has no B2 or C2a tests, so do not cite nonexistent test filenames as existing.

## 7. Documentation-drift audit, 2026-10-10

- F15-B1 was **implemented and independently accepted**, not merely `draft/manual`, `ready/auto` or waiting for review. Older roadmap headings/status and design prose must update forward-looking B1 states, without rewriting historic task packets/summaries.
- Original F15-A player-scale measurement is **local map** only; B1 identity smoke is **data-only**. No two-site walk, physical seam, visit/session activation or production actor residency was proved. Keep F15-C as outstanding.
- `AbstractActivitySimulationState` shares B1's allowed ID grammar; `ActorReificationCoordinator` anchor lookup is unscoped by Domain; the spawner queue has no managed ActorId/cancel token. These are **B2/C2 interface gaps**, not retroactive B1 review failures.
- Existing M6 is still presentation cache only and Godot global-class initialization is required before diagnosing a fresh-worktree parse cascade. The original Ritualant required-ingress failure is still owner-specific; revisit only if relevant to the targeted C2/scene acceptance, not as a reason to re-run completed F15-A/B1.
- A `CampaignGeographyRegistry` edge is not a physical road, terrain alignment or signal/communications graph; do not call F15-B1 a fully traversable world.
- This **design record** introduces no art/runtime/schema migration/benchmark or authority transfer. **Approval is now recorded**, and separately authored V2 packets are permitted subject to targeted authoring validation and safe publication. This text is not itself a dispatchable packet.

**Next:** validate the two **independent** authored V2 implementation/review pairs using the official targeted repository validator (both parked then promoted), regenerate/check the managed queue index, pairing, AI-context and changed-file checks, publish each pair on current main through normal PR/dispatcher rules; **no implementation during authoring**. Preserve C2b/F15-C gates.
