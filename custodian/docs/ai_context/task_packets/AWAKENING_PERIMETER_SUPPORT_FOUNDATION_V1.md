# PERIMETER SUPPORT FOUNDATION

- Packet schema: custodian.task_packet.v2
- Workstream: awakening-perimeter-support-foundation-v1
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: review-awakening-handoff-readiness-art-convergence-v1
- Locks: awakening-runtime, awakening-art-registration, awakening-perimeter-support
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual, asset-pipeline
- Paired review workstream: review-awakening-perimeter-support-foundation-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Reviewed main: 63f3e38608fa6f0c5778958858dab1abd764a056
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Visual review: none
- Goal: Establish measured off-route camera-footprint coverage, an Asset V2-compatible ten-family pending-art contract, and a collision-free Awakening perimeter support layer that safely preserves existing presentation whenever art is absent.
- Completion boundary: Produce a deterministic coverage/gap ledger from current Layout, exact live room plate bounds and actual camera reveals; implement a compact scene presentation host with no art required and a deterministic optional support-placement description; register pending Asset V2 families and corresponding required-assets entries without pretending images exist; add focused regression coverage and docs truth.
- Current measured state: Runtime already builds a dark neutral AwakeningVoidBackdrop from WORLD_BOUNDS plus a 1024 margin and retains registered nine zone plates, Road modular plates, a 1502×2048 shared 04→05 composition, and the 128×96 05→06 passage. Perimeter families and 30 assets are only planned; current runtime/art/convergence and a separate fade repair must land first.
- Evidence: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; custodian/game/world/awakening/awakening_layout.gd; custodian/game/world/awakening/awakening_first_return.gd; custodian/scenes/awakening_first_return.tscn; design/04_architecture/AWAKENING_ASSET_MANIFEST.md; design/04_architecture/ASSET_PIPELINE_V2.md.
- Task-specific authority: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; actual live Asset V2 contract/parser and current authored Layout/runtime remain authoritative for technical details.
- Work surface: custodian/game/world/awakening/awakening_first_return.gd (orchestration only), its scene and a small new dedicated perimeter presentation module; custodian/content/metadata/assets/families/awakening_*_perimeter_support.asset.json; custodian/content/metadata/assets/required_assets.registry.json; focused validation under custodian/tools/validation/, Asset V2 requirements/generated view, relevant ai_context docs.
- Change: Read present scene/zone and camera scale/reveal state first. Compute all camera-visible off-playfield windows at wake, established reveals, representative joins, South Reach and optional Chapel. Document per-zone extents, overlap/culling and gaps. Add a minimal predictable presentation component that can read future published support textures but is a no-op today; all support below canonical gameplay floor/Operator/foreground, no collision or fake cover. Register each of ten backdrop families with omni/copy/no mirror and 3 semantic static states; use real state canvas overrides or schema-supported equivalent for proposed 512×512 / 1024×512 / 256×256 sizes. If schema disallows the combined family, record an evidence-backed revised family design before authoring JSON, never bypass validators. Add pending need(s) to registry; regenerate the generated root view. The component should have zero missing-resource loads/spam when files have not been ingested, and never replace AwakeningVoidBackdrop.
- Preserve: Gameplay route authority remains in Layout, existing zone underlays/foregrounds retain exact registration and pixels, accepted Dust→connector→Locker composition is never replaced, existing 05→06 passage and Road alignment remain unchanged; missing art is never fabricated; authored camera/lighting/progression owns gameplay.
- Non-goals: No playable area expansion, no new collisions, doors, traversal permissions, quests, combat, UI, procgen, scene handoff, repeated full-frame image adjudication or arbitrary edits to immutable source art.
- Acceptance: Produce reviewed main + machine-readable camera-coverage ledger for all 10 zones; no performance spikes or new geometry/path/collision; absent-art boot and full route unchanged; family contracts parse and register as SOURCE_PENDING while doctor/requirements view correctly expose unmet demand; no duplicated accepted registered composite pixels; family/state routing and default no-op proven in tests; docs exactly distinguish plan from live.
- Validation: Run newly added focused deterministic area/art coverage and absent-art behavior validation; existing Awakening scene, geometry, progression, 04→05 registration and lower-upper passage checks; Asset V2 contract plan/status/doctor and needs --check; changed-file validation; git diff --check.
- Task overrides: none
- Deferred: Actual image generation and human aesthetic approval; all AP1–AP4 artwork scene binding and visual closeout; any new authored route or Gate-opened visual state; Hub region scenes.

## Asset and review handoff

- Planned region coverage: all 10, metadata only.
- Asset dimensions and states are exact proposed contracts from the prompt authority: structural_support 512×512 / distant_structures 1024×512 / edge_transition 256×256, each omni static 1 frame, true alpha where defined; the real V2 family schema owns per-state frame size. No model-generated file is assumed to exist.
- Before touching runtime, inspect current origin/main, all predecessor implementation/review receipts and the relevant existing Asset V2 family contracts; reconcile stale planning numbers with measured truth.
- No human-art blocker on this purely technical foundation. Dispatch remains dependency-gated until the existing Awakening handoff-convergence paired review archives complete.
- This ready/auto packet is still DEPENDENCY-GATED by the existing Awakening handoff-convergence review; do not claim unless dispatcher approves. The needed external art is explicitly out of this foundation.
- Next action: When predecessor review archives complete, claim through dispatcher and implement AP0 without waiting for new art.
