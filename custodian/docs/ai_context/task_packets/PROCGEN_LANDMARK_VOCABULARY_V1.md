# PROCGEN LANDMARK VOCABULARY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-landmark-vocabulary-v1`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-tilemap-facade-contraction`
- Locks: `procgen-presentation`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `7287fd6`
- Goal: Land Phase 3 of Procgen Macro Presentation as a deterministic minor/major/hero landmark vocabulary, while folding the bounded Dressing Cluster V1 correctness/scalability fixes discovered during review into the same presentation slice.
- Completion boundary: Done when the existing three Rocky Upland proof clusters retain their current authored appearance through direct, promoted, streamed, unload/reload paths; cluster policy is data-driven and safe to extend beyond Rocky Upland; landmark planning/realization has one presentation-only authority; at least one minor and one major production landmark profile are live using existing approved content; hero placement is contract-complete but cannot occur without an authored hero claim; and no terrain, route, collision, navigation, biome, surface-material, or authored-claim authority moves into presentation code.
- Current measured state: `PROCGEN_MACRO_PRESENTATION_SYSTEM.md` marks Phase 3 Landmark Vocabulary as NEXT. No generic `LandmarkProfile` authority exists on current main. Dressing clusters are live as three Rocky Upland proof profiles, but streaming reveal drops `cluster_id`, pair spacing is checked only against the current profile's minimum, children are checked for gameplay safety rather than an explicit semantic-scope policy, target count is derived from whole-map area, Rocky residual foliage `0.62` is hardcoded in the procgen façade, rectangular profile masks are serialized cell-by-cell, and required-child realization is non-transactional.
- Evidence: `custodian/game/world/procgen/dressing/{dressing_cluster_profile,dressing_cluster_planner,dressing_cluster_realizer}.gd`; `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd`; current streaming reveal and dressing integration in `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/tools/validation/procgen_dressing_clusters_smoke.gd`; `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; current `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md` proof baseline; `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`; `design/02_features/procgen/PROCGEN_PLAYABILITY_PASS_V1.md`; the post-D4 procgen façade/service ownership produced by `procgen-tilemap-facade-contraction`; current biome, surface-material, route-clearance, authored-claim, foliage, prop, and streaming contracts.
- Work surface: existing dressing/foliage profile-planner-realizer code; biome presentation profile data; a focused generic landmark presentation subsystem under `custodian/game/world/procgen/landmarks/` or the equivalent post-D4 presentation owner; existing ruin `PropDefinition`/runtime realization; narrow procgen integration; focused validation; macro-presentation/current-state/index docs.
- Change: Implement the behavioral contracts below through the post-D4 owners. Do not regrow `ProcGenTilemap` with new stateful algorithms if the façade contraction exposes a cleaner service seam.
- Preserve: native 32 px semantic authority; accepted-seed determinism; current Rocky macro stamps; Surface Materials V1 and Road Semantics V2; existing route/combat/ingress clearances; current three Rocky proof cluster compositions and their visual intent; existing foliage wind/occlusion/collision policy; generic ruin prop behavior except where a specific approved prop becomes landmark-owned; current streaming semantics; missing-art fallback.
- Non-goals: no topology generation; no route redesign; no road-art correction; no new biome production vocabulary; no new landmark artwork; no fake hero art; no alpha-derived collision; no day/night/weather behavior changes; no portal/traversal props as generic landmarks; no general procgen performance/refactor work beyond the bounded presentation contracts in this packet.
- Acceptance: all cluster hardening and landmark contracts below are machine-checkable; same semantic input produces stable cluster and landmark fingerprints; direct-final and accepted-candidate materialization agree; streaming unload/reveal reproduces the same composition; no presentation planner mutates semantic input; route/playability audit stays green; production landmark cadence is bounded and non-overlapping; hero production count remains zero unless an authored hero claim exists; subjective visual approval remains human-owned.
- Validation: focused dressing-cluster smoke first; new landmark-vocabulary smoke second; macro-presentation, playability, candidate/materializer, streaming/runtime-health regressions directly affected by the final integration; then repository changed-file closeout. Do not start with the full procgen sweep. Use the live validation recipe after rebasing because this packet is dependency-gated behind the runtime-optimization refactor.
- Task overrides: `none`
- Deferred: full six-piece Rocky natural-rock cluster vocabulary pending approved reusable rock/boulder art; Woodland/Wetland/Scrubland presentation expansion; production hero-landmark art/content; environmental finish; known ruined-road dark-patch visual debt.

## Implementation Contract

### 1. Dressing Cluster hardening gate

Keep the existing cluster subsystem and correct it rather than replacing it.

Required behavior:

- Streaming realization must preserve the planned `cluster_id` exactly as direct realization does, so same-cluster tree spacing policy behaves identically in direct, promoted, and streamed worlds.
- Pair spacing must be symmetric: two placements are legal only when anchor distance satisfies the stricter minimum of the pair.
- Cluster child semantics must be explicit profile policy rather than an accidental side effect. Support at least:
  - same biome + same surface material;
  - same biome;
  - gameplay-safe only.
  Existing Rocky proof profiles use same biome + same surface material unless live evidence proves a specific authored profile requires a narrower compatible rule.
- Keep explicit irregular masks, but add a compact rectangular authoring path so regular footprint/suppression rectangles are not stored as hundreds of repeated cells. Effective masks must remain deterministic and inspectable.
- Profile/catalog validation must reject malformed production data, including duplicate cluster IDs, invalid/null children, duplicate child offsets, children outside the effective footprint, invalid compact geometry, and suppression that does not contain the footprint.
- Move Rocky-specific presentation tuning out of façade code. Residual foliage density and cluster cadence/budget belong in biome/profile/config data interpreted by runtime code.
- Cluster budgeting must scale by eligible semantic area/family rather than forcing all future biome families to compete for one whole-map target. A biome/family with no configured cluster cadence produces zero clusters.
- Required children are transactional at cluster scope. A failed required child cannot leave a half-realized authored composition behind. Optional children may fail without invalidating the whole cluster.
- Observability reports planned, realized, and failed clusters/required children without per-frame event spam.

Do not change the visual composition of the current three production proof profiles merely to make tests easier.

### 2. Landmark ownership

Add one generic presentation-only landmark authority with separate data, planning, and realization responsibilities. Local class/file names may follow the post-D4 repository seam, but ownership must remain clear:

```text
semantic world / route / claims
        ↓ read only
landmark profiles + catalog
        ↓
deterministic landmark planner
        ↓
landmark realization using existing prop/presentation runtime
```

The landmark system may claim presentation/dressing clearance. It may not create or modify gameplay terrain, route topology, collision/navigation authority, biome, surface material, or authored world importance.

### 3. Landmark tiers

Support stable tiers:

- `MINOR`: repeatable orientation/readability landmark;
- `MAJOR`: uncommon regional composition anchor;
- `HERO`: unique or near-unique authored/world-purpose feature.

Hero placement is fail-closed: a HERO profile may realize only from an existing authored/semantic hero claim. Random open floor can never manufacture a hero landmark.

### 4. Candidate semantics and clearance

Prefer existing meaningful semantic candidates rather than scanning arbitrary floor for "cool places".

Ordinary minor/major candidates may consume compatible route/playability pocket roles such as branch, resource pocket, or vista. They must reject arrival/exit pads, safe pockets, combat clear/spawn space, story insertion space, world-ingress clearance, authored/story/faction claims, macro-presentation claims/clearance, dressing-cluster occupied/suppression space, incompatible roads/hardstand, wall/chasm/ocean, required cells, and other landmark blocker/clearance footprints.

Use live post-D4 claim/route APIs rather than copying dictionaries into another authority when a canonical query exists.

### 5. Landmark profile contract

Profiles must express, directly or through existing referenced resources:

- stable landmark ID and tier;
- presentation/prop resource;
- biome/material/pocket eligibility where applicable;
- explicit blocker/presentation footprint and dressing clearance;
- deterministic weight/limit/spacing;
- whether an authored anchor is mandatory.

Never infer semantic collision/blocker masks from image alpha.

### 6. Initial production proof

Do not create new art in this slice.

Reuse existing approved ruin content for the first ordinary landmark proof if it still satisfies the live prop contract after rebase. Preferred candidates are the existing `obelisk` and `rotunda_01` definitions for one MINOR and one MAJOR profile. If either has become unsuitable on live main, use another already-approved non-traversal ruin prop and record the reason.

A prop promoted to intentional landmark ownership must not also remain in ordinary random ruin scatter at the same semantic frequency. Reconcile the generic spawn set or eligibility so the same prop is not both "memorable landmark" and random pepper.

Do not use `portal_ring_01` or any other traversal-semantic prop as a generic landmark.

Production HERO profiles may remain empty in this packet. Synthetic validation must prove the contract can accept an authored hero claim and rejects unclaimed hero placement.

### 7. Generation/materialization/streaming integration

Preserve the current architecture rule that rejected candidates do not realize presentation nodes.

For accepted worlds:

1. final semantic authorities exist;
2. macro presentation is planned;
3. cluster and landmark plans are derived from immutable semantic state;
4. runtime realization uses those plans;
5. residual/random dressing fills what remains;
6. final blocker/route audit remains authoritative.

Integrate through the canonical post-D4 accepted-world/materialization and streaming seams. Do not revive retired candidate-runtime compatibility paths.

Direct-final and accepted-candidate materialization must produce identical landmark fingerprints for the same semantic state. Streaming unload/reveal may hide/remove presentation nodes, but re-reveal must reconstruct the same landmark and cluster children without rerolling.

### 8. Cadence

Cadence is data-driven and semantic-area-aware, not camera-driven.

The design target remains roughly one memorable environmental read every one to two normal gameplay screen widths, but generation must use stable world-space spacing/eligible semantic area rather than live camera visibility.

Keep minor/major/hero limits independently configurable. Do not hardcode one Rocky-specific cadence into orchestration code.

## Focused Acceptance

Add or extend tests to prove at minimum:

1. the existing large Rocky two-tree cluster realizes both trees direct and streamed, survives unload/re-reveal, and keeps the same deterministic child identity;
2. mixed profile spacing uses the stricter pair minimum;
3. compact rectangular profile geometry is equivalent to the current effective masks and explicit irregular masks still override it;
4. malformed/duplicate cluster profile/catalog contracts fail validation;
5. child semantic scope is enforced;
6. cluster targets derive from eligible semantic area/config and a biome with no cluster cadence remains at zero;
7. required-child failure rolls back that cluster only;
8. landmark planner is deterministic and does not mutate input dictionaries/resources;
9. MINOR/MAJOR candidate roles and all protected clearances are enforced;
10. random HERO placement is impossible and synthetic authored HERO placement is accepted;
11. production landmark props do not simultaneously remain ordinary random scatter authority;
12. no terrain/route/collision/navigation/biome/surface-material fingerprint changes when landmark presentation is toggled;
13. direct accepted-world materialization and streaming reconstruction retain the same landmark/cluster fingerprints;
14. final route/playability audit stays green.

## Visual Evidence Economy

Non-visual acceptance comes first.

After structured checks pass, produce one fixed-seed gameplay-scale comparison with landmarks disabled/enabled. Prefer one compact contact sheet or at most two full-frame stills. The visual review should answer only:

- do MINOR/MAJOR reads appear intentional rather than repeated stamps;
- do clusters remain subordinate to landmarks and macro terrain;
- do routes/combat pockets remain legible;
- does total clutter stay controlled.

Do not auto-approve subjective composition. Record the evidence path and leave aesthetic approval to the user/reviewer.

## Documentation Closeout

When runtime truth changes:

- mark Phase 3 in `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md` validated only after acceptance passes;
- update the existing `PROCGEN_MACRO_PRESENTATION_V1.md` ledger truth rather than creating a second macro umbrella ledger;
- update `CURRENT_STATE.md` and `FILE_INDEX.md` only for new live owners/contracts;
- keep Phase 4 as the next presentation/content expansion unless live evidence changes that plan;
- preserve the known ruined-road visual-debt note unless separately resolved.

## Completion Truth

Complete before setting `Status: complete`.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes | no`
- Completion boundary satisfied: `yes | no`
- Acceptance satisfied: `yes | no`
- Superseded/legacy production path disposition: `removed | intentionally-preserved | n/a`
- Evidence: replace with concrete files/tests/runtime evidence for the final disposition

## Execution Feedback

Complete before `Status: complete`.

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none | ...`
- Root cause / contributing factors: `none | ...`
- Prevention / pipeline improvement: `none | ...`
- Tooling / docs drift discovered: `none | ...`
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`
- What worked: optional

## Handoff

- Next action: After `procgen-tilemap-facade-contraction` is complete, rebase on live main, re-audit the resulting procgen presentation/claim/materialization seams, then implement this packet without restoring pre-D4 façade ownership.
- Best starting files: the active macro-presentation authority, current dressing cluster files/tests, post-D4 procgen façade/service ownership, playability pocket classifier, existing prop runtime/definitions.
- Blockers or open questions: Dependency-gated by `procgen-tilemap-facade-contraction`; no art blocker for MINOR/MAJOR proof; production HERO content intentionally deferred.
