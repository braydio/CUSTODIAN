# CUSTODIAN | Rope & Cloth Modular Library | Full Buildout Roadmap V1

**Status:** approved program design and authored task-packet sequence; no production implementation or art approval implied.  
**Audit baseline:** braydio/CUSTODIAN main@ebfe3810eec146d7202a4378324b0f32c9e12fee (2026-11-08).  
**Authoring chat:** not-recorded (replace only with the exact user-supplied current conversation URL).  
**Implementation scope:** A library of pinned ropes, cables, chains and flexible cloth that makes otherwise static 2.5D environments respond visibly to weight and wind without taking over nav/collision authority.

## Verified starting condition

Current repository has rope-bridge anchor art, a static banner/cloth asset family and shared procedural foliage wind, but GitHub search found no dedicated gameplay-ready rope/cloth solver or reusable 2D cloth instance module. WorldEnvironmentDirector exposes wind_speed_multiplier/gust_multiplier and indoor exposure; it does not provide physical chain constraints.

## Intended gameplay/presentation payoff and operating mechanics

1. One deterministic fixed-step 2D point solver (Verlet/PBD-style, corrected by bounded distance constraints) for segmented ropes and a 2D grid extension for cloth. Fixed pins, tension, damping, gravity and cut/reset/teleport semantics belong to the presentation instance, not world physics authority.
2. Profiles declare normalized length, segments/rows/columns, gravity, stiffness, iterations, damping, wind response, maximum displacement, rest pose and attachment paths. Reject invalid/degenerate geometry; clamp steps and cost.
3. Renderers are swappable: untextured Line2D rope and links, Polygon2D/MeshInstance2D ribbon, UV-controlled banner cloth. Static anchors stay authoritative; no implicit CollisionShape2D or walkability changes.
4. Environment wind is sampled read-only from the existing presentation state and spatial seed so all ropes, foliage and weather can sway consistently. Missing director gives calm fallback. Local gust phase and spring settle reproduce for equal inputs; no second weather clock or RNG authority.
5. Editor-facing preset instances for taut cable, slack rope, hanging chain, pennant/banner and hanging sheet. Exposed pins, anchor gizmos, live simulation preview and a seeded wind-test panel; textured variants require reviewed Asset V2 art, not raw imported PNG paths.
6. Runtime uses offscreen freeze/recover, detail tiers, batched shared visual materials where possible, per-instance update budgets, optional noninteractive break/sway response; connection to a real traversable rope bridge is deferred to a separate gameplay-authored crossing system.

## Core boundaries

**Preserve:** Current region geometry/bridge collision and navigation, authored layer order, deterministic gameplay clock, Asset V2 source ownership, indoor weather exposure, foliage shared-material count, object-scaling and screen pixel crispness.

**Explicit non-goals:** Do not turn physics animation into actor collision, grapple forces, climbability, bridge structural failure, wind damage or Operator cape/rig motion. Those need separate gameplay owner and approved character-art contracts.

**Measure success:** Given pinned endpoints and seed, the same fixed-step sequence yields identical control-point coordinates with bounded total length/stretch; no NaN, runaway motion, anchor drift or visible pop on teleport/return. A reusable preset scene works in isolation and in a dev environment; 50+ visible elements require measured per-tick baseline and tiered budget, not guessed FPS.

**Art / Asset Pipeline V2:** No production PNG required for core/library presets; shape-only geometry is a supported default. Optional later stylized textures must be separately specified and reviewed through Asset V2: source_work/<area>/<registered-family>/<state>_source.png and inbox/<registered-family>/<state>.png. Do not invent new family IDs, canvas sizes or register unapproved art during these packets.

**Human-owned review:** Review for CUSTODIAN's restrained art language: convincing weight, no rubber-band overstretch, no broad glowing effects, acceptable pixel stability. A single compact real-time review loop is justified for cloth movement.

## Dependency DAG and staged production

| Slice | Workstream ID | Deliverable | Depends on review | Visual decision |
|---|---|---|---|---|
| 1 | rope-cloth-fixed-step-core-v1 | Deterministic rope solver and rendering | none | conditional |
| 2 | rope-cloth-preset-workbench-v1 | Cloth grid and reusable visual presets | review-rope-cloth-fixed-step-core-v1 | conditional |
| 3 | rope-cloth-world-presentation-v1 | World integration, wind coherence and performance | review-rope-cloth-preset-workbench-v1 | required |

### 1. Deterministic rope solver and rendering

**Implementation:** rope-cloth-fixed-step-core-v1  
**Independent review:** review-rope-cloth-fixed-step-core-v1  
**Dependency:** none  
**Primary locks:** rope-cloth-core  
**Priority:** P1

**Change:** Implement pinned-point deterministic rope solver, bounded integration/constraints, gravity/damping/seeded motion, rest/teleport reset and Line2D renderer. Expose opt-in calm/default weather-wind read-only hook. Keep simulations presentation-only, and add zero-length, pin loss, delta spike and offscreen tests.

**Acceptance:** Identical profile+seed+step inputs produce identical coordinates; endpoints remain pinned, constraint stretch bounded, idle fallback on missing wind works, teleport/reset produces no impulse, no collision/nav nodes added and no asset files required.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; new rope solver deterministic/failure smoke; changed-file validation.

**Next deferred:** 2D cloth grid, presets/editor, world integration and textured Source V2 assets.

### 2. Cloth grid and reusable visual presets

**Implementation:** rope-cloth-preset-workbench-v1  
**Independent review:** review-rope-cloth-preset-workbench-v1  
**Dependency:** review-rope-cloth-fixed-step-core-v1  
**Primary locks:** rope-cloth-core, rope-cloth-presets  
**Priority:** P1

**Change:** Add grid cloth constraints, pinned edge/corner variants, UV-safe geometry updates and presets: taut cable, slack tether, chain, banner/pennant and hanging sheet. Expose wind/length/damping parameters, anchor gizmos, strict resource validation and recoverable scene ownership. No asset dependency in default solid-material renderers.

**Acceptance:** Each five presets can instantiate, tick and reset on its own; cloth corners and rope endpoints remain pinned, texture coordinates stable, missing texture degrades visibly but safely, and none alters active world collision.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; new cloth grid, preset scene and color/UV validation smokes; changed-file validation.

**Next deferred:** Placement in live environments, capes/rigs, interactive bridge physics.

### 3. World integration, wind coherence and performance

**Implementation:** rope-cloth-world-presentation-v1  
**Independent review:** review-rope-cloth-world-presentation-v1  
**Dependency:** review-rope-cloth-preset-workbench-v1  
**Primary locks:** rope-cloth-world-integration, world-presentation  
**Priority:** P2

**Change:** Bind weather wind/exposure through read-only adapter; build three reproducible dev gallery configurations: hanging cable, banner, and suspended chain; add visibility/LOD/offscreen suspension, scene exit cleanup and deterministic resume; profile p50/p95 CPU and GPU on representative visible counts. Provide placement recipe for later authored/procgen zones.

**Acceptance:** Wind agrees with foliage direction under fixed weather, interior shielding/calm works, reset across scene transitions preserves root pins, detail tiers cap work, and measured performance plus one compact human motion review passes. Zero navigation and interaction rules changed.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; new gallery lifecycle, interest management and performance profile smoke; changed-file validation.

**Next deferred:** Gameplay bridge, grappling hook, lift cable force and Operator cape animation; any later production textures require Asset V2 intake.

## Integration and file ownership

- New library code and tests are **planned outputs**, not already published runtime features. Workstream packets name the recommended repository-relative owners and exact focused baselines.
- Required inputs for each packet are this document plus the current-main source owners named in its Evidence section; no chat-only schemas, reference ZIPs or art are needed to claim the first slice.
- Every implementation stage gets a separate post-land fresh-context review. The implementation workstream does not self-approve its review. Only the first implementation/review pair opts in to automatic authoring preflight; successors remain draft/manual pending predecessor review and a refreshed repository/claim audit.
- Before any new production texture, family or runtime art route, inspect design/04_architecture/ASSET_PIPELINE_V2.md, the registered family schema and the actual consumer. New art requires source/alpha/dimension/animation contracts, human review, and explicit source_work/inbox routing.
- Deterministic tests and source/geometry/contracts precede visual inspection. Material aesthetic decisions require a minimal ROI/short-motion handoff. The default is no new full-screen recording or unnecessary LFS generation.

## Documentation drift and change hygiene

Rope bridge anchor sprites are visual props, not proof of physical rope simulation. Current docs must distinguish any newly animated bridge decorations from the existing traversal/collision system; never upgrade the bridge to a physics surface by documentation alone.

This document is a forward plan, not a claim that every planned stage is implemented. On each stage closeout, reconcile impacted live design, CURRENT_STATE.md, FILE_INDEX.md, actual code, test ownership and asset registry truth. Do not rewrite unrelated historical state or bypass independent reviews.

## Release / stop conditions

1. Never assume a partial implementation is ready/auto without the current packet authoring preflight and remote publication receipts.
2. The review of every stage must archive PASS before the dependent stage becomes claimable. A review finding keeps the original workstream identity and enters its bounded correction/re-review lifecycle.
3. A human/ChatGPT visual decision is mandatory for final subjective polish; technical PASS does not imply aesthetic approval.
4. If a new runtime gameplay authority, unapproved art family, or incompatible schema is necessary, stop and return the smallest explicit decision/proof to the authoring chat instead of silently inventing ownership.
