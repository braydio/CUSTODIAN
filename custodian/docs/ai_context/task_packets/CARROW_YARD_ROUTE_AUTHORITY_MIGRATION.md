# CARROW YARD ROUTE AUTHORITY MIGRATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-yard-route-authority-migration`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-loader-contraction`
- Locks: `carrow-yard-route`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `7287fd6`
- Goal: Preserve the approved Carrow District Transfer Frame experience while migrating Carrow Yard from its bespoke connected-map mini-router onto the canonical registered authored-level and route traversal architecture.
- Completion boundary: Done when Carrow Yard is a registered production authored destination reached through `WorldIngressSpawner`/`WorldIngressSite` and the normal one-level route wrapper; the main-world Transfer Frame preserves manual first activation then automatic subsequent entry; Carrow return travel is requested through `LevelExit2D`; mutable Carrow state survives same-runtime revisits through the normal route-state policy; and the old `GothicCompoundMap`/`GothicCompoundTravelGate` direct destination-selection path is no longer production authority.
- Current measured state: `GothicCompoundMap` still extends `Node2D`, owns `_travel_route_active` plus a gate registry, and directly exposes `enter_from_main`/`return_to_main`. `GothicCompoundTravelGate` owns destination mode, first activation, a 24-frame teleport lock, and directly calls those map methods. `ContractWorldLoader` still calls `_place_gothic_compound_connection`, and `custodian/content/levels/levels.json` contains no `carrow_yard` definition. In parallel, the repository already has `AuthoredLevel2D`, `LevelRegistry`, `WorldIngressSpawner`, `WorldIngressSite.site_scene_path`, `RouteTraversalManager`, the single-level route wrapper, and `LevelExit2D` as the canonical authored-destination path.
- Evidence: `custodian/game/world/gothic_compound/{gothic_compound_map,gothic_compound_travel_gate}.gd`; `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/content/levels/levels.json`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; `custodian/game/world/levels/{authored_level_2d,level_exit_2d,world_ingress_spawner}.gd`; `custodian/game/world/routes/route_traversal_manager.gd`; `design/04_architecture/{AUTHORED_LEVEL_AUTHORING_PIPELINE,ROUTE_TRAVERSAL_SYSTEM}.md`; `custodian/tools/validation/carrow_yard_interior_smoke.gd`.
- Task-specific authority: `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`; `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`; the post-P7 world-placement/loader ownership after `contract-world-loader-contraction`; current Carrow level/content/environment contracts.
- Work surface: Carrow production level scene/script and state hooks; level registry definition; Carrow-specific `WorldIngressSite` presentation adapter; reusable District Transfer Frame presentation component; Carrow return `LevelExit2D`; focused Carrow/route/ingress validation; removal/quarantine of obsolete production bridge code.
- Change: Migrate authority, not the level's visual content or blueprint generator. Use the canonical route/level services after P7 and keep Transfer Frame state/presentation reusable and destination-agnostic.
- Preserve: first-use explicit activation; ACTIVE presentation visible before travel; subsequent automatic body-entry travel; existing District Transfer Frame Asset V2 art; Carrow Yard blueprint/layout; East Machine House behavior and lighting/exposure; persistent main-world Operator; exact origin/camera/UI restoration; bounce/re-entry safety; mutable storage/one-shot state across same-runtime revisits.
- Non-goals: no `gothic_compound` namespace rename; no Carrow layout redesign; no new art; no WorldTransitionManager implementation; no procgen topology/ingress-placement redesign; no changes to Sundered/Ash Bell routes except shared regressions; no disk/save-file persistence beyond existing route-state policy.
- Acceptance: one canonical travel authority remains; the visual frame contains no destination-selection/teleport authority; registered Carrow entry/return/re-entry works with one persistent Operator; source and destination never process simultaneously; first activation and repeat auto-entry behavior match current UX; origin restoration and state persistence pass; direct Carrow placement/travel code is removed from production ownership without breaking focused Carrow presentation/interior tests.
- Validation: Carrow-specific route migration smoke first; existing `carrow_yard_interior_smoke.gd`; level registry contract; world-ingress physics re-entry; single-level route wrapper; origin restoration/camera-rebind; route exit binding; then changed-file closeout. Do not start with the full authored-level suite unless focused tests expose broader risk.
- Task overrides: `none`
- Deferred: historical/debug compatibility adapters only if a proven current consumer remains; broader Carrow namespace cleanup; campaign save serialization.

## Implementation Contract

### 1. Register Carrow as a production authored destination

Create one `carrow_yard` level definition and register it through the existing level registry. Use the normal level-only ingress path so runtime traversal is the canonical in-memory:

```text
@world_origin -> carrow_yard -> @world_origin
```

Adapt the existing Carrow map to the `AuthoredLevel2D` lifecycle either directly or through the smallest clean wrapper. Do not rewrite the working blueprint generator simply to change base-class ownership.

The production level must not instantiate a persistent Operator, gameplay camera, or parallel route manager.

### 2. Separate Transfer Frame presentation from travel authority

Extract the existing layered District Transfer Frame state/presentation into a reusable component or equivalent presentation owner. It may own visual states such as inactive/available/acquiring/active/failure and the current boot/aperture animation timing.

It must not own:

- destination level/route identity;
- target scene/spawn;
- route topology;
- actor teleportation;
- loader/session state.

No new art is required. Reuse the existing Asset V2 runtime family.

### 3. Main-world Carrow ingress

Use the live generic custom-ingress seam (`WorldIngressDefinition.site_scene_path` or its post-P7 equivalent) for the Carrow Transfer Frame.

Behavioral contract:

- first use requires explicit interaction;
- play the current activation/boot sequence;
- frame reaches and visibly renders ACTIVE before route entry commits;
- successful activation persists for the relevant current-runtime world state;
- later entry uses ordinary body-entry traversal through `WorldIngressSite` without another manual interaction;
- reuse the canonical ingress return-overlap/re-entry guard rather than maintaining the bespoke 24-frame portal lock unless live evidence proves an additional independent guard is still required.

### 4. Carrow return frame

Inside Carrow, travel back to the world origin through a route-bound `LevelExit2D` (or the canonical post-P7 equivalent) with the District Transfer Frame presentation attached.

The exit requests `return_world`; `RouteTraversalManager` resolves the destination. The frame may present state but must not call `return_to_main` directly.

Use the existing arrival guard contract when needed to prevent immediate bounce.

### 5. Carrow state policy

Move mutable revisitable Carrow state into the existing authored-level route-state contract. Preserve at least currently mutable storage/depletion and one-shot state that would otherwise reset when the level instance is released/recreated.

Do not serialize live Node/camera/Operator references.

Choose the existing lifecycle/cache/state policy that preserves current-runtime revisit behavior without inventing a second persistence system.

### 6. Retire the parallel mini-router

After canonical traversal is proven:

- remove production ownership of `_travel_route_active` / travel-gate registration;
- remove direct frame calls to `enter_from_main` / `return_to_main`;
- remove or quarantine obsolete `ContractWorldLoader` Carrow-specific placement/travel compatibility that survived P7;
- preserve only a clearly named debug/legacy adapter if a real remaining consumer is proven.

Do not leave two production travel authorities live "for compatibility."

## Focused Acceptance

Prove at minimum:

1. `carrow_yard` is discoverable through `LevelRegistry` and its named entry spawn resolves;
2. the custom Transfer Frame ingress is created through the canonical ingress placement path;
3. first use requires explicit activation and ACTIVE renders before route commit;
4. subsequent main-world body entry traverses automatically;
5. Carrow return is a route-exit request, not a direct map teleport;
6. the persistent Operator instance is unchanged across entry/exfil/re-entry;
7. world-origin branches, camera state, and UI restore exactly on exfil;
8. return overlap/arrival guard prevents immediate bounce;
9. mutable Carrow state survives leave/revisit according to declared state policy;
10. no frame/map-local mini-router remains in production authority;
11. Carrow environment/interior smoke behavior remains unchanged.

## Documentation Closeout

Update only runtime truth made stale by the migration:

- Carrow implementation/design note;
- `CURRENT_STATE.md`;
- `FILE_INDEX.md`;
- any architecture ownership map or validation ownership entry that still describes the bespoke connected-map bridge as production authority.

Do not rewrite the generic authored-level/route architecture docs unless implementation reveals an actual contract mismatch.

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

- Next action: Wait for `contract-world-loader-contraction`, then rebase on live main and implement against the resulting world-placement/loader seam rather than restoring the pre-P7 loader code.
- Best starting files: post-P7 ContractWorldLoader/world placement service; `WorldIngressSite`; `AuthoredLevel2D`; `RouteTraversalManager`; current Carrow map/gate; focused Carrow smoke.
- Blockers or open questions: Dependency-gated by `contract-world-loader-contraction`; no art blocker.