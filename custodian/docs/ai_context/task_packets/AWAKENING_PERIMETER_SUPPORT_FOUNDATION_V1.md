# PERIMETER SUPPORT FOUNDATION

- Packet schema: custodian.task_packet.v2
- Workstream: awakening-perimeter-support-foundation-v1
- Status: blocked
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
- Reviewed main: 041717c3abaa6a960e4c1849542c22365c1586f8
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Visual review: none
- Goal: Establish measured off-route camera-footprint coverage, an Asset V2-compatible **nine-family** generic perimeter pending-art contract, and a collision-free Awakening perimeter support layer that safely preserves existing presentation whenever art is absent. Zone 05 Dust Lung is explicitly excluded and owned by the dedicated Dust Lung V2 design/asset program.
- Completion boundary: Produce a deterministic coverage/gap ledger from current Layout, exact live room plate bounds and actual camera reveals; implement a compact scene presentation host with no art required and a deterministic optional support-placement description; register pending Asset V2 families and corresponding required-assets entries without pretending images exist; add focused regression coverage and docs truth.
- Current measured state: AP0 measures ten live zone plate bounds and 34 viewport samples. Four samples expose two repeated off-plate windows: 704×32 px at wake/Zone01 entry and 704×96 px at the 05→06 join. Nine generic perimeter families / 27 states are registered as unmet demand. Zone 05's former generic family is superseded by `AWAKENING_DUST_LUNG_V2.md` and is not registered by AP0.
- Evidence: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; design/04_architecture/AWAKENING_DUST_LUNG_V2.md; design/04_architecture/AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md; custodian/game/world/awakening/awakening_layout.gd; custodian/game/world/awakening/awakening_first_return.gd; custodian/scenes/awakening_first_return.tscn; design/04_architecture/AWAKENING_ASSET_MANIFEST.md; design/04_architecture/ASSET_PIPELINE_V2.md.
- Task-specific authority: design/04_architecture/AWAKENING_PERIMETER_SUPPORT_V1.md; design/04_architecture/AWAKENING_PERIMETER_ASSET_PROMPTS_V1.md; design/04_architecture/AWAKENING_PERIMETER_SUPPORT_IMPLEMENTATION_ROADMAP.md; actual live Asset V2 contract/parser and current authored Layout/runtime remain authoritative for technical details.
- Work surface: custodian/game/world/awakening/awakening_first_return.gd (orchestration only), its scene and a small new dedicated perimeter presentation module; the nine non-Dust `awakening_*_perimeter_support.asset.json` families only; **do not create `awakening_dust_lung_perimeter_support`**; custodian/content/metadata/assets/required_assets.registry.json; focused validation under custodian/tools/validation/, Asset V2 requirements/generated view, relevant ai_context docs.
- Change: Read present scene/zone and camera scale/reveal state first. Compute all camera-visible off-playfield windows at wake, established reveals, representative joins, South Reach and optional Chapel. Document per-zone extents, overlap/culling and gaps. Add a minimal predictable presentation component that can read future published support textures but is a no-op today; all support below canonical gameplay floor/Operator/foreground, no collision or fake cover. Register each of the nine remaining generic backdrop families with omni/copy/no mirror and 3 semantic static states; use real state canvas overrides or schema-supported equivalent for proposed 512×512 / 1024×512 / 256×256 sizes. If schema disallows the combined family, record an evidence-backed revised family design before authoring JSON, never bypass validators. Add pending need(s) to registry; regenerate the generated root view. The component should have zero missing-resource loads/spam when files have not been ingested, and never replace AwakeningVoidBackdrop.
- Preserve: Gameplay route authority remains in Layout, existing zone underlays/foregrounds retain exact registration and pixels, accepted Dust→connector→Locker composition is never replaced, existing 05→06 passage and Road alignment remain unchanged; missing art is never fabricated; authored camera/lighting/progression owns gameplay.
- Non-goals: No playable area expansion, no new collisions, doors, traversal permissions, quests, combat, UI, procgen, scene handoff, repeated full-frame image adjudication or arbitrary edits to immutable source art.
- Acceptance: Produce reviewed main + machine-readable camera-coverage ledger for all 10 zones, while only the nine non-Dust zones receive generic perimeter-family contracts; no performance spikes or new geometry/path/collision; absent-art boot and full route unchanged; family contracts parse and register with all 27 required states unmet while requirements view exposes demand; family/state routing and default no-op proven in tests; docs exactly distinguish plan from live. Asset V2 `source_pending` specifically means a real approved/staged source exists, so it remains false for these absent-art contracts.
- Validation: Run newly added focused deterministic area/art coverage and absent-art behavior validation; existing Awakening scene, geometry, progression, 04→05 registration and lower-upper passage checks; Asset V2 contract plan/status/doctor and needs --check; changed-file validation; git diff --check.
- Task overrides: none
- Deferred: Actual image generation and human aesthetic approval; all AP1–AP4 artwork scene binding and visual closeout; any new authored route or Gate-opened visual state; Hub region scenes.

## Asset and review handoff

- Planned camera coverage: all 10 zones. Generic perimeter family registration: Zones 01–04 and 06–10 only (9 families / 27 states). Zone 05 remains current runtime fallback plus separately planned Dust Lung V2.
- Asset dimensions and states are exact proposed contracts from the prompt authority: structural_support 512×512 / distant_structures 1024×512 / edge_transition 256×256, each omni static 1 frame, true alpha where defined; the real V2 family schema owns per-state frame size. No model-generated file is assumed to exist.
- Before touching runtime, inspect current origin/main, all predecessor implementation/review receipts and the relevant existing Asset V2 family contracts; reconcile stale planning numbers with measured truth.
- No human-art blocker on this purely technical foundation. Dispatch remains dependency-gated until the existing Awakening handoff-convergence paired review archives complete.
- The predecessor Awakening handoff-convergence review is archived complete on current main. The orphaned implementation claim was resumed and fast-forwarded to `041717c3` before edits.
- AP0 implementation evidence: `custodian/docs/ai_context/reports/awakening_perimeter_support/camera_coverage_v1.json`; `awakening_perimeter_support_smoke.gd` reports 34 samples, ten zone plate records, nine families and 27 deterministic state placements. No source artwork was fabricated or ingested.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: after syncing to `origin/main@075025f4`, the required full changed-file sweep failed twice. `review_pairing_contract` reports 11 unrelated Compound review packets whose target paths are not archived as expected. `godot_import_lfs_preflight` also failed in the sweep with “standalone project should not require a Git LFS check,” although a direct rerun passed. The AP0-tagged suite passed 22/22 after sync; the pre-sync changed-file sweep had passed 49/49.
- Root cause / contributing factors: inherited validation-contract drift on current main, plus a transient/inconsistent LFS-preflight result. The failing Compound packets and the validation harness are outside this AP0 change.
- Prevention / pipeline improvement: repair the stale Compound review-pairing fixtures and make the LFS preflight deterministic in a separate scoped task, then rerun changed-file validation before landing AP0.
- Tooling / docs drift discovered: changed-file validation selects global `review_pairing_contract` and LFS preflight checks unrelated to AP0; current main has 11 stale Compound target locations. Global Asset V2 doctor also retains four unchanged designation-locker catalog-hash errors.
- Follow-up: manual-follow-up
- What worked: live Sprite2D bounds and camera reveal values produced a deterministic coverage report without changing route authority.

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh reason: none
- Next action: resolve inherited changed-file validation failures on current main, rerun the required suite, then finish AP0 and run its paired fresh-context review.
- Blockers or open questions: full changed-file validation remains red because of 11 stale Compound paired-review target paths and an inconsistent standalone Git LFS preflight failure; four unchanged awakening_designation_locker catalog-hash doctor errors remain separately inherited.
