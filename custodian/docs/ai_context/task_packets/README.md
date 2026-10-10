# Agent Task Packets

Last updated: 2026-10-09

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.

### Authoring preflight

Before a newly authored or materially refreshed packet is changed to `Status: ready`,
validate that packet and its paired review (when applicable) with:

```bash
python3 custodian/tools/agent/validate_task_packet_authoring.py \
  custodian/docs/ai_context/task_packets/<PACKET>.md \
  custodian/docs/ai_context/task_packets/REVIEW_<PACKET>.md
```

`Review modes` are schema values, not free-form labels. The current shared contract
accepts only `code`, `architecture`, `runtime`, `visual`, `asset-pipeline`, and
`workflow`. The targeted preflight imports that enum directly from
`task_packet_contract.py`, validates pair bindings/override metadata, and is scoped
to the packet(s) being authored so unrelated queue drift cannot become an excuse to
skip local validation. Repo-wide AI-context/review-pairing validation still runs at
normal closeout.


## Active Packets

### Ready / Auto Dispatch



<!-- task_packet_index:managed:start -->
- `REVIEW_STEALTH_PERCEPTION_FOUNDATION.md` — Independently prove the shared acoustic seam is typed, deterministic, cross-family, and behavior-neutral rather than a new universal AI layer.
- `STEALTH_PERCEPTION_FOUNDATION.md` — Make Enemy and Vaultwing consume one typed receiver-side acoustic perception seam so hearing is a shared stealth/perception capability rather than duplicated...
- `ASH_BELL_HIGHLANDS_GENERATED_DESTINATION.md` — Register a distinct generated Ash-Bell Alpine Highlands route destination that can receive the Operator from the Ritualant route and reserve an outward termi...
- `ASH_BELL_RITUALANT_RUNTIME_TRUTH_CLOSEOUT.md` — Make the live Forlorn-Ritualant peaceful-resolution and base-animation contracts match the already-authoritative authored-encounter design before further pro...
- `ASH_BELL_RITUALANT_STATIC_ASSET_INTAKE.md` — Publish and wire the 12 already-reviewed Ritualant ritual-prop/chamber-dressing states through Asset Pipeline V2 without reopening encounter behavior or maki...
- `AWAKENING_PERIMETER_SUPPORT_FOUNDATION_V1.md` — Establish measured off-route camera-footprint coverage, an Asset V2-compatible ten-family pending-art contract, and a collision-free Awakening perimeter supp...
- `CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — Make ordinary campaign-ending Custodian death complete through Post recovery and reintegration instead of the R1 compatibility Game Over, while reusing the r...
- `HUB_CAMPAIGN_RETURN.md` — Close the first CampaignRegion → persistent Hub return: apply one valid CampaignOutcome to persistent Hub state exactly once, release the disposable Campaign...
- `HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` — Make Crown Transfer a real optional Hub branch into the existing registered Twin Solaria authored level and back, without turning Twin into ordinary Contract...
- `HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` — Close the first real Campaign loop as one reviewed integration: boot → full Awakening → persistent Hub → Forum Contract → optional Twin roundtrip → Muster/Po...
- `HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` — Make the Adjudication Dais the first embodied Contract decision: surface one provisional first Contract, accept it exactly once, persist that accepted scenar...
- `HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` — Make Muster Court → ordinary Continuity Port the real campaign departure path, consuming the accepted/prewarmed first Contract without duplicate generation a...
- `OPERATOR_GUARD_PARRY_COMPOSITION_POLISH.md` — Extend the proven movement-permissive guard composition to the remaining defensive presentations that already allow movement, without weakening contact weigh...
- `OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md` — Extract interaction target/build/repair/terminal field-work coordination into one focused authority and give interactables an opt-in semantic Operator succes...
- `OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md` — Make loadout/weapon-selection runtime state a focused authority, remove mutable instance state from `OperatorWeaponDefinition`, and use the established modul...
- `OPERATOR_MELEE_DOMAIN_EXTRACTION.md` — Extract melee timeline/drive/target/contact state into one focused authority and cash in the existing modular art where it genuinely improves moving combat p...
- `OPERATOR_MOBILE_GUARD_COMPOSITION.md` — Make the unarmed guard lifecycle visibly movement-permissive wherever gameplay already allows movement, so strafing is expressed as movement-owned lower-body...
- `OPERATOR_PARRY_RIPOSTE_COMPLETION.md` — Finish the one genuinely missing gameplay tail from the legacy Hit Taxonomy/Riposte effort: a dedicated semantic riposte after a successful parry when no val...
- `OPERATOR_RANGED_DOMAIN_EXTRACTION.md` — Extract primary-ranged/sidearm combat state into one ranged authority and make all movement-permissive ranged presentation use the same lower-locomotion + up...
- `OPERATOR_RANGED_STATIC_WEAPON_SOCKET_CLOSEOUT.md` — Finish the already-live Carbine hybrid socket architecture by making the static directional `WeaponSprite` the sole primary-ranged weapon renderer for author...
- `OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md` — Extract Operator damage/recovery/Field Patch survivability behavior into explicit authorities and make the movement-permissive Field Patch animation reflect...
- `OPERATOR_RUNTIME_SHELL_COLLAPSE.md` — Finish the Operator strangler migration by collapsing `operator.gd` and `operator.tscn` into a thin deterministic actor chassis over the extracted authoritie...
- `PROCGEN_ALPINE_CLIFF_PRESENTATION_V1.md` — Make the permanent Alpine exterior frontier read as a large geological escarpment physically attached to the playable plateau rather than a repeated generic...
- `PROCGEN_ARCHIVE_RESOLVE_PLAYTEST_POLISH_V1.md` — Make the live Archive Resolve frontier read as unresolved CUSTODIAN world-space rather than black streaming squares, make the graphite/brass resolve legible...
- `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` — Extract durable authored-world claim metadata and membership from `ProcGenTilemap` into one canonical registry under `custodian/game/world/procgen/authored_c...
- `PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — Re-derive the post-D1/D2/D3 generation core from live code and produce the authoritative migration contract for replacing TileMapLayer-as-working-memory with...
- `PROCGEN_LANDMARK_VOCABULARY_V1.md` — Land Phase 3 of Procgen Macro Presentation as a deterministic minor/major/hero landmark vocabulary, while folding the bounded Dressing Cluster V1 correctness...
- `PROCGEN_PERFORMANCE_SOAK_V1.md` — Run the complete optimized procgen stack through a deterministic production-size soak, compare it to the S1 baseline, and establish stable regression budgets...
- `PROCGEN_RENDER_ATTRIBUTION_V1.md` — Attribute procgen presentation node, rendered-object, and draw-call cost to concrete presentation owners before changing renderer structure.
- `PROCGEN_RENDER_LOAD_CONSOLIDATION.md` — Reduce procgen presentation node/render overhead by consolidating the highest-cost presentation-only owners identified by the attribution packet, without mov...
- `PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md` — Convert the completed V1 whole-series review and final soak evidence into the next evidence-backed procgen optimization/correction DAG, preserving stable wor...
- `PROCGEN_TILEMAP_FACADE_CONTRACTION.md` — Finish the V1 ProcGenTilemap decomplexification pass by deleting migration residue and locking the façade around coherent extracted authorities.
- `RECIPROCAL_CONTINUITY_CANON_DRIFT_GUARD.md` — Turn the already-landed Reciprocal Continuity / Ash-Bell canon correction into a fail-closed, focused regression contract so active docs/runtime cannot silen...
- `REVIEW_ASH_BELL_HIGHLANDS_GENERATED_DESTINATION.md` — Independently verify the registered Highlands generated destination against its archived contract.
- `REVIEW_ASH_BELL_RITUALANT_RUNTIME_TRUTH_CLOSEOUT.md` — Independently verify the landed Ritualant runtime-truth repair against its packet and current authored-encounter authority.
- `REVIEW_ASH_BELL_RITUALANT_STATIC_ASSET_INTAKE.md` — Independently prove the 12 approved static Ritualant assets were fetched from the exact reviewed source packages, published through Asset Pipeline V2, bound...
- `REVIEW_AWAKENING_PERIMETER_SUPPORT_FOUNDATION_V1.md` — Independently falsify perimeter support foundation completion, especially any false Asset V2 registration or gameplay/presentation authority breach.
- `REVIEW_BIDIRECTIONAL_DROPBOX_HANDOFF.md` — Independently verify the landed bidirectional Dropbox handoff against its own packet contract, especially fail-closed external-input handling, credential bou...
- `REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_REVIEW_CORRECTIONS_1.md` — Independently verify correction R0-01 without redesigning the generated-region lifecycle.
- `REVIEW_BRIDGED_FALLS_LOWER_QUARTER_HANDOFF.md` — Independently verify the final Bridged Falls -> Lower Quarter production cutover and single-state-authority claim.
- `REVIEW_BRIDGED_FALLS_PROCGEN_TOPOLOGY.md` — Independently verify that Bridged Falls is genuinely seed-generated and structurally valid, not a fixed authored corridor with cosmetic variation.
- `REVIEW_CUSTODIAN_DEATH_HANDOFF_FOUNDATION_RECOVERY_1.md` — Independently verify that the recovered R1 death handoff lands the intended campaign-level exactly-once death consequence on current main without importing s...
- `REVIEW_CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — Independently verify that R2 removes the R1 Game Over fallback only for a genuinely accepted death return, layers recovery on the reviewed H6 authority witho...
- `REVIEW_HUB_CAMPAIGN_RETURN.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` — Independently verify the landed implementation against its archived packet and live runtime.
- `REVIEW_HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` — Independently verify the landed implementation against its archived packet and live runtime behavior.
- `REVIEW_NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION.md` — Independently verify that NPA-6 moved Enemy health and death/corpse lifecycle state behind one focused owner while preserving public combat, loot, reificatio...
- `REVIEW_OPERATOR_2_5D_RUNTIME_PROMOTION.md` — Independently verify the landed implementation against its archived packet and live behavior.
- `REVIEW_OPERATOR_2_5D_WORKBENCH_PRODUCTION_QUEUE.md` — Independently verify the landed implementation against its archived packet and live behavior.
- `REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md` — Independently verify the landed implementation against its archived packet and live behavior.
- `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE_REVIEW_CORRECTIONS_1.md` — Independently verify that correction 1 binds production to the approved normalization plan and closes the Workbench registration-report evidence gap without...
- `REVIEW_OPERATOR_PARRY_RIPOSTE_COMPLETION.md` — Independently verify that the landed riposte completion adds only the missing lightweight post-parry action and does not duplicate or weaken current critical...
- `REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION_REVIEW_CORRECTIONS_1.md` — Independently verify that correction `R0-01` closes the REPLACE source-conflict window without weakening successful publication, CREATE collision refusal, or...
- `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PLAYTEST_POLISH_V1.md` — Independently verify the post-playtest Archive Resolve polish preserves AR1-AR4 authority while fixing the actual gameplay composition: graphite unresolved w...
- `REVIEW_PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` — Independently verify that D2 creates one durable authored-claim owner, preserves current authored floor/overlook/ingress behavior and M6 unload/reload semant...
- `REVIEW_PROCGEN_GENERATION_DATA_MODEL_AUDIT.md` — Independently verify that the post-D1/D2/D3 generation-data audit completely and truthfully maps the remaining TileMap-backed generation core before any abst...
- `REVIEW_PROCGEN_GENERATION_GRID_FOUNDATION.md` — Independently verify that the GenerationGrid foundation is a minimal semantic storage seam with exact TileMap-backed parity, not an accidental second generat...
- `REVIEW_PROCGEN_GENERATION_GRID_MIGRATION_SERIES_AUTHORING.md` — Independently verify that the authored generation-grid migration DAG covers the entire audited semantic-generation surface exactly once, has truthful depende...
- `REVIEW_PROCGEN_RUNTIME_OPTIMIZATION_SERIES_V1.md` — Independently review the entire landed Procgen Runtime Optimization V1 implementation and its dependency DAG after the final soak, then produce one findings-...
- `REVIEW_RECIPROCAL_CONTINUITY_CANON_DRIFT_GUARD.md` — Independently verify that the landed canon-drift guard actually fails closed on the superseded Reciprocal Continuity/Ash-Bell failure modes without turning l...
- `REVIEW_RITUALANT_NORTH_EGRESS_AND_CHAPEL_VISTA.md` — Independently verify the real camera-zone chapel reveal and post-resolution north route.
- `REVIEW_STARTUP_WORLD_ENTRY_SPINE_V1.md` — Independently verify that the App/Boot spine makes Twin Solaria and the Contract sandbox directly bootable without changing production story order or duplica...
- `REVIEW_TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — Independently verify that the landed Twin Solaria Crown Incident forensic progression satisfies the staged evidence contract without creating route/Persisten...
- `REVIEW_TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — Independently verify fail-closed Twin Solaria route adjudication without travel or presentation authority leakage.
- `REVIEW_TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — Independently verify the Route Vista sample ingest/presentation without replacing human visual approval or allowing presentation to become route authority.
- `REVIEW_TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — Independently verify that Solarium I acquisition is presentation-only, Asset V2-compliant, fail-closed, and never becomes Crown passage.
- `REVIEW_VAULTWING_RUNTIME_HARDENING.md` — Independently prove Vaultwing bond timing, restore reconciliation and relationship compatibility are fixed-step and semantically correct without duplicating...
- `REVIEW_VEHICLE_DIAGNOSIS_KNOWLEDGE_V1.md` — Independently verify that vehicle scanning produces durable, bounded mechanical knowledge and pattern evidence without becoming a resource grant, repair acti...
- `REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_ASSET_V2.md` — Independently verify that vehicle Asset V2 support is genuinely family/owner driven and the Scout family, directional seam, fallbacks, and required-assets tr...
- `REVIEW_VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1_REVIEW_CORRECTIONS_1.md` — Independently prove R0-01 is fixed and Scout R1 recovery consumes the exact fabricated assemblies through the production held interaction.
- `REVIEW_VEHICLE_PART_FABRICATION_RECOVERY_V1.md` — Independently prove that the reusable recovery spine is assembly-driven for R1+, knowledge-gates recipes rather than repairs, preserves explicit R0 direct-ma...
- `REVIEW_VEHICLE_RECOVERY_PRESENTATION_MANIFESTS_V1.md` — Independently verify the shared recovery art contracts are exact, Asset V2-native, reusable, and truthfully remain missing until real production art arrives.
- `REVIEW_VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1.md` — Independently prove that important visual-review handoffs cannot lose their questions, that human/ChatGPT answers are paired and recorded deterministically b...
- `TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS.md` — Implement Twin Solaria Slice C as a deterministic, local Crown Incident forensic progression layered onto the already-live V1 authored level, without introdu...
- `TWIN_SOLARIA_ROUTE_REVIEW_AUTHORITY.md` — Implement Twin Solaria Slice D as one focused, fail-closed route-review authority that models a candidate route, classifies evidence, enforces Home Index and...
- `TWIN_SOLARIA_ROUTE_VISTA_SAMPLES_V1.md` — Ingest the three newly pushed Twin Solaria archway-view images as neutral Route Vista sample content for Solarium I, wire a presentation-only first-pass samp...
- `TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION.md` — Implement Twin Solaria Slice E so authorized route-review state drives a readable Solarium I observational-acquisition sequence through the Outbound/Reciproc...
- `ULTRA_CODEX_PACKET_WORKER.md` — Bootstrap and prove a persistent, bandwidth-conservative Codex worker on the user's Ultra.cc "Speedboat Ops" seedbox that can autonomously claim explicitly e...
- `VAULTWING_BONDING_LOCAL_HISTORY_RECOVERY.md` — Preserve and audit the clean attached Vaultwing bonding-art worktree without losing its exact HEAD, compare its branch history with current main and the prev...
- `VAULTWING_RUNTIME_HARDENING.md` — Harden Vaultwing-local runtime ownership after shared hearing/perception lands, without recreating species-local sensing or redesigning wild combat/bond bala...
- `VEHICLE_DIAGNOSIS_KNOWLEDGE_V1.md` — Add the vehicle diagnosis/reverse-engineering layer: the Operator can service-scan real vehicles, learn named mechanical domains, collect specific assembly-p...
- `VEHICLE_FIELD_SCOUT_BUGGY_ASSET_V2.md` — Give the Field Scout Buggy a real Asset Pipeline V2 family and replace hover-buggy-specific vehicle post-processing with an owner/family-driven seam that sup...
- `VEHICLE_FIELD_SCOUT_BUGGY_CLASS_V1_RECOVERY_1_REVIEW_CORRECTIONS_1.md` — Make production Field Scout restoration use the reviewed R1 SERVICE fabricated-assembly recovery flow.
- `VEHICLE_PART_FABRICATION_RECOVERY_V1.md` — Build the reusable component-recovery spine: R0 PATCHWORK profiles may still pay raw materials directly, while R1+ profiles require fabricated replacement as...
- `VEHICLE_RECOVERY_PRESENTATION_MANIFESTS_V1.md` — Register the shared Asset Pipeline V2 contracts needed to present vehicle diagnosis, component requirements, installation, and bootstrap without creating fin...
- `VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1.md` — Make every important Dropbox visual-review handoff carry the exact reviewer questions and make review resolution pair those questions with explicit human/Cha...
- `ASSET_WORKBENCH_REVIEW_STUDIO.md` — Add a non-mutating REVIEW studio to Asset Workbench so selected Asset V2 states can be inspected at native pixel fidelity across staged source and runtime re...
- `BABY_OPOSSUM_RUNTIME_HARDENING.md` — Correct the Baby Opossum runtime state-transition and approach/retrieval semantics, tighten determinism and contract validation, and reconcile the active imp...
- `CARROW_YARD_ROUTE_AUTHORITY_MIGRATION.md` — Preserve the approved Carrow District Transfer Frame experience while migrating Carrow Yard from its bespoke connected-map mini-router onto the canonical reg...
- `CONTRACT_WORLD_ENCOUNTER_PLACEMENT_EXTRACTION.md` — Move ambient enemy/encounter marker placement policy from ContractWorldLoader into one focused placement service without moving enemy spawning or AI authority.
- `CONTRACT_WORLD_INGRESS_PLACEMENT_EXTRACTION.md` — Move authored world-ingress/destination placement from ContractWorldLoader into the canonical world-placement layer while preserving transition ownership els...
- `CONTRACT_WORLD_LOADER_CONTRACTION.md` — Collapse ContractWorldLoader back to world attach/rebind/activation orchestration after all placement domains have migrated.
- `CONTRACT_WORLD_RELAY_PLACEMENT_EXTRACTION.md` — Move ARRN relay tile selection and placement from ContractWorldLoader into the world-placement layer.
- `CONTRACT_WORLD_RESOURCE_PLACEMENT_EXTRACTION.md` — Move tutorial and expedition resource-node placement policy out of ContractWorldLoader into one deterministic placement service.
- `CONTRACT_WORLD_VEHICLE_PLACEMENT_EXTRACTION.md` — Move generated-world vehicle placement policy from ContractWorldLoader into a focused deterministic placement service.
- `KENNEY_PATTERN_LINES_SOURCE_LIBRARY.md` — Preserve the user's four downloaded Kenney Pattern Pack Lines variants as a durable, searchable, provenance-complete CUSTODIAN source-material library so fut...
- `LOOT_TOAST_HUD_CLEARANCE_V1.md` — Keep loot/pickup toasts readable and non-overlapping with the live top-left gameplay HUD by replacing the queue's stale fixed Y assumption with one narrow ru...
- `OPERATOR_GUARD_BREAK_PRESENTATION.md` — Give guard break its own committed, readable whole-body failure presentation, distinct from ordinary non-breaking recoil, without weakening the existing move...
- `OPERATOR_UNARMED_DEFENSE_SOURCE_PROMOTION.md` — Turn the newly generated unarmed-defense source-work set into reviewed, registration-correct 96×96 Operator production assets through Source Session + Asset...
- `REVIEW_ASSET_WORKBENCH_REVIEW_STUDIO_R1.md` — Independently verify Slice 2 Review Studio is a read-only extension of the landed Asset Workbench family navigator and Asset V2 truth, with exact pixel/frame...
- `REVIEW_BABY_OPOSSUM_RUNTIME_HARDENING_R1.md` — Independently verify that Baby Opossum runtime hardening fixes transition/arrival/retrieval determinism without expanding behavior architecture or weakening...
- `REVIEW_BRIDGED_FALLS_BRIDGE_GRAMMAR_AND_ASSET_V2.md` — Independently verify Asset V2 correctness, geometry registration and generated-seed bridge readability against the user-approved art lock.
- `REVIEW_BRIDGED_FALLS_VISTA_AND_WATERFALL_PRESENTATION.md` — Independently verify the technical presentation and preserve the recorded human visual decision for the Bridged Falls atmosphere.
- `REVIEW_CONTRACT_WORLD_PLACEMENT_FOUNDATION.md` — Independently verify that P1 created one minimal read-only world-placement context seam, preserved ContractWorldLoader lifecycle/orchestration authority and...
- `REVIEW_ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md` — Independently verify that the reusable 2.5D foundation makes visual elevation, ground-root sorting, semantic presentation bands, roof occlusion reuse, and co...
- `REVIEW_LOOT_TOAST_HUD_CLEARANCE_V1.md` — Independently verify that the production loot-toast queue clears the actual visible top-left HUD across normal/debug/terminal/viewport states without changin...
- `REVIEW_LORDS_OF_PAIN_TEST_GALLERY.md` — Independently verify the landed DEMO-scoped Lords of Pain test gallery against its archived implementation packet, with special attention to the seven availa...
- `REVIEW_SUNDERED_KEEP_OVERLOOK_ALTERNATE_ART_POLISH.md` — Independently verify that optional bespoke overlook plates were necessary, correctly ingested through Asset V2, improve the approved SKO-1 composition, and r...
- `REVIEW_SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md` — Independently verify that the standalone alternate genuinely proves CUSTODIAN's fixed-oblique 2.5D Sundered composition while preserving real 2D gameplay and...
- `REVIEW_SUNDERED_KEEP_OVERLOOK_RUNTIME_INTEGRATION_PLAN.md` — Independently verify that the post-standalone production integration plan chose the correct live Sundered/procgen ownership boundary, did not smuggle runtime...
- `REVIEW_TWIN_SOLARIA_DEVELOPMENT_PREVIEW_CONSISTENCY_R1.md` — Independently verify that the development-only Twin preview dimension was resolved from repository provenance without mutating or reinterpreting the authorit...
- `SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md` — Build a standalone playable alternate Sundered Keep overlook in which the real Operator occupies a compact foreground shelf/perch above a vast apparent depth...
- `TWIN_SOLARIA_DEVELOPMENT_PREVIEW_CONSISTENCY.md` — Resolve the long-standing development-only Twin Solaria preview mismatch where the preview controller/smoke expects 3500×3000 while the loaded development te...
<!-- task_packet_index:managed:end -->
This section is owned by `custodian/tools/agent/task_packet_index.py`; run it with `--write` after packet changes to populate/update the bounded managed block.

### Active Agent Workflow Visual Review Lifecycle

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb

- `archived/VISUAL_REVIEW_HANDOFF_LIFECYCLE_HARDENING.md` — completed P0 control-plane/tooling slice: claim receipts expose authoring/visual-review routing, finish enforces exact summary backlinks, Dropbox review manifests default to delete-after-review and carry a path-confined cleanup command, and `$custodian-next` keeps human review inside the active workstream.
- `archived/REVIEW_VISUAL_REVIEW_HANDOFF_LIFECYCLE_HARDENING.md` — complete: paired review passed (0 blocking, 5 non-blocking deferred findings R0-01..R0-05).

### Completed Persistent Checkout Sync Hardening

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

- `archived/PERSISTENT_CHECKOUT_SYNC_HARDENING.md` — complete: one fail-closed persistent-checkout sync authority owns safe coordination-main and Operator-art updates, with `csync` / `opui-sync` helpers, OPUI pre-authoring synchronization, and 25/25 changed-file validations passed.
- `archived/REVIEW_PERSISTENT_CHECKOUT_SYNC_HARDENING.md` — paired fresh-context review found blocking R0-01: status/startup hashed all 134,037 ignored root files; cycle 1 correction removes that scan and bounds checks to incoming paths.
- `archived/PERSISTENT_CHECKOUT_SYNC_HARDENING_REVIEW_CORRECTIONS_1.md` — correction cycle 1 passed fresh paired review: R0-01 fixed; 2,048 unrelated ignored files synchronized in 0.09s, collision and sparse-overlay guards remain fail-closed.
- `archived/REVIEW_PERSISTENT_CHECKOUT_SYNC_HARDENING_REVIEW_CORRECTIONS_1.md` — paired fresh-context review passed; R0-01 fixed, no cycle-2 correction required.

### Active Hub First-Set / First Campaign Loop Series

Design/spatial authority: `../../../design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`.
Program tracker: `../../../design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`.

Seven implementation slices are pre-authored with paired reviews. H1 `hub-first-set-blockout-v1-recovery-1` and its paired review are complete and archived with the human-approved overview. H2 `hub-awakening-context-handoff` is implemented and its paired review is the next lifecycle step. H3-H7 remain `ready/auto` and dependency-gated. Each downstream execution agent performs its own claim-time refresh from current main and landed predecessor evidence before mutation.

- H1 `archived/HUB_FIRST_SET_BLOCKOUT_V1.md` / archived review — recovery workstream `hub-first-set-blockout-v1-recovery-1`; blockout with true two-connector Sepulcher loop, Operator-clearance path proof, Port return-bay semantics and human topology approval. The paired review passed; donor history remains reachable and `agent-diagnostics/*` traces are preserved lifecycle evidence, not executable work.
- H2 `archived/HUB_AWAKENING_CONTEXT_HANDOFF.md` / review — production Awakening completion → persistent Hub with transactional rollback; paired review pending.
- H3 `HUB_FORUM_ADJUDICATION_CONTRACT_PREWARM.md` / review — explicit Dais acceptance + persistent accepted CampaignScenario/seed + one bootstrap generation.
- H4 `HUB_CROWN_TRANSFER_TWIN_SOLARIA.md` / review — optional same-Hub Crown Transfer route to production Twin and back; may run parallel with H3 after H2.
- H5 `HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` / review — READY/GENERATING/FAILED Port gating and same-prewarmed-map deployment.
- H6 `HUB_CAMPAIGN_RETURN.md` / review — exactly-once CampaignOutcome → HubState mutation, Campaign teardown, Port return.
- H7 `HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` / review — full boot→Awakening→Hub→optional Twin→Campaign→outcome→Hub proof.

Do not create v2 duplicates merely because a predecessor chose different private helpers; the downstream agent must reconcile those private seams at claim time while preserving the packet's public behavioral contract.

### Active Isometric 2.5D Presentation Realization + Operator Production Series

Design authority: ../../../design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md.  
Operator production tracker: ../../../design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md.  
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

The project has pivoted away from planned live-3D presentation experiments. The fixed-isometric 2.5D doctrine is realized inside the existing 2D runtime.

- K3D-1 remains complete/reviewed precursor evidence.
- K3D-1P kenney-isometric-blockout-playtest is complete/landed as the final walkable Kenney reference.
- isometric-2-5d-presentation-foundation is complete; its paired review still gates downstream showcase consumers.
- `operator-workbench-animation-creation` is now reviewed through its bounded service-publication correction: correction `a26982b8d`, cycle-1 re-review artifacts `0ebea7b6`, no remaining findings. WB25 may rely on New Animation as a real backend capability, including exact-pixel full-body/modular publish and DORMANT unwired truth.
- `operator-2-5d-animation-viability-audit` is complete as a read-only current-main closeout: 69 live action families remain `legacy_96`, one exact-hash relaxed-idle source is the first canonical `operator_2_5d_128` family, and 68 semantic families remain in the baseline production backlog. No second subjective review was requested.
- `operator-2-5d-canonical-visual-contract` and its paired review are complete/passed. The exact source masters, accepted canonical profile/reference, fixed root semantics, legacy-96 compatibility, guide exclusion, and absence of runtime cutover were independently verified.
- WB25-1 is complete. Its first review found one blocking workflow-projection defect (R0-01); the bounded correction landed and its fresh re-review passed with no remaining findings. Generation-aware targets, 2.5D source paths, direction workspaces and backend-derived saved creation readiness are now accepted predecessor authority.
- WB25-2 guided ingress and its cycle-1/cycle-2 corrections are complete and independently reviewed. The final cycle-2 review passed physical saved-document proof and preserved Source Session target binding, direction progress, collision, legacy-96, valid artist edits, and the no-publication boundary. WB25-3 has consumed that landed handoff and is now `ready/auto`; it owns exact existing-Workbench Art Agent attachment, generation-derived 128 profile selection, objective polish diagnostics, and scoped/undoable polish mutations.

Operator Workbench implementation series, all pre-authored with refresh gates:

1. OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION.md + paired review — generation namespace, plan v2, target-first tree/matrix.
2. OPERATOR_2_5D_WORKBENCH_INGRESS.md + paired review — guided NEW/IMPORT and resumable direction packages.
3. OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION.md + paired review — profile-guided Aseprite polish, registration and temporal diagnostics.
4. OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md + paired review — canonical/family/sequence review plus debug Godot sandbox.
5. OPERATOR_2_5D_WORKBENCH_PRODUCTION_QUEUE.md + paired review — honest queue/dashboard and deterministic generation briefs.
6. OPERATOR_2_5D_RUNTIME_PROMOTION.md + paired review — coherent-cohort generation cutover while preserving one runtime selector/database.

WB25-1 is complete/reviewed after correction R0-01. WB25-2 is complete/reviewed after the cycle-2 correction passed its fresh paired review. WB25-3 is `ready/auto`, with its paired review `ready/auto` behind it. The planning seed remains 69 live legacy semantic families, 1 already-authored canonical family, 68 remaining baseline canonical families, and 544 baseline direction-animation strips before extra modular/weapon/FX layers. WB25-4 and later remain refresh-gated until their immediate predecessor + paired review return to the authoring chat.

The canceled kenney-orthographic-3d-feasibility and kenney-3d-to-2d-production-feasibility workstreams must not be revived.

### Active Sundered Keep Overlook Alternate Program

Program tracker: `../../../design/05_levels/SUNDERED_KEEP_OVERLOOK_ALTERNATE_ROADMAP.md`.  
Authoring / review / refresh chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

The goal is a standalone playable fixed-oblique 2.5D alternate: a small foreground shelf/perch overlooking a vast apparent depth field with the Sundered Keep as the dominant distant destination. It stays on real Operator + PlayerController + Camera2D and does not replace the production route yet.

- `SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md` — SKO-1 ready/auto behind the reviewed 2.5D foundation; composition proof using existing donor assets only.
- `REVIEW_SUNDERED_KEEP_OVERLOOK_ALTERNATE_VERTICAL_SLICE.md` — paired fresh-context runtime/composition review.
- `SUNDERED_KEEP_OVERLOOK_ALTERNATE_ART_POLISH.md` — SKO-2 ready/manual optional Asset V2 layered-art pass. This is an intentional user timing hold: claim only if SKO-1 composition passes and the user chooses bespoke art polish because donor-art fidelity remains the problem.
- `REVIEW_SUNDERED_KEEP_OVERLOOK_ALTERNATE_ART_POLISH.md` — paired SKO-2 review.
- `SUNDERED_KEEP_OVERLOOK_RUNTIME_INTEGRATION_PLAN.md` — SKO-3 ready/manual planning gate. This is an intentional user timing hold: after reviewed standalone evidence, return to the chat above only when the user chooses to begin production/procgen integration planning.
- `REVIEW_SUNDERED_KEEP_OVERLOOK_RUNTIME_INTEGRATION_PLAN.md` — SKO-3R paired fresh-context architecture/workflow review; every production packet authored by SKO-3 must remain gated behind this review.
- No production integration implementation packet is pre-authored yet.



## Active Reusable Source-Material Intake

- `KENNEY_PATTERN_LINES_SOURCE_LIBRARY.md` — ready/auto reference-only intake for all four user-downloaded Kenney Pattern Pack Lines variants (30 motifs each, 120 PNGs total), with exact-copy provenance, license/hash metadata, and a curated CUSTODIAN usage shortlist. It does not create runtime assets; production use must promote selected motifs through the owning Asset V2 family.

### Stranded Branch Recovery / Operator Fast Chain South

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73

- The unique high-resolution Fast 01 South donor master is already preserved on main at `b57ab98d` under `custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/south/fast_1_south.png`; this preservation commit does not change runtime.
- `archived/STRANDED_BRANCH_RECOVERY_CLOSEOUT.md` — P1 closeout landed. Adds fail-closed exact-SHA retirement; archive-tags and retires five reviewed stale refs. Vaultwing's attached history remains untouched and is routed to its separate manual recovery packet.
- `VAULTWING_BONDING_LOCAL_HISTORY_RECOVERY.md` — P1 ready/manual recovery. First archive-tags the exact attached local HEAD remotely, then classifies the recorded 23-commit checkpoint-to-remote range and all commits unique to current main before any worktree/branch mutation or selective salvage.
- `archived/OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY.md` — P1 implementation complete/landed at `e7402591`: seven approved Fast 01 N + Fast 02-04 N/S body masters normalized to 96×96, exact lower/upper recomposition, six true-alpha-zero Fast 02-04 N/S FX authoring placeholders, protected Fast 01 authorities unchanged, gameplay data untouched.
- `archived/REVIEW_OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY.md` — paired P1 review complete/passed with objective acceptance proven and human visual approval recorded; see `REVIEW_OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY_CLAUDE_SUMMARY.md`.

### Operator Runtime Authority Migration

Design authority: `../../../design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`.

- `archived/OPERATOR_DEPENDENCY_INJECTION_SPINE.md` — Slice F0 complete: zero absolute scene-tree lookups remain in `operator.gd`; the three mutable weapon-definition findings remain for F1.
- `archived/OPERATOR_DODGE_DOMAIN_EXTRACTION.md` — Slice F4 complete: charge, profile selection, iframe/recovery clocks, Flow/chain, exit carry, and cancellation live in `OperatorDodgeController`; full-body dodge presentation and chassis movement ownership remain intact.
- `OPERATOR_MOBILE_GUARD_COMPOSITION.md` — P1 ready/auto next implementation slice for movement-owned lower-body locomotion plus action-owned upper-body guard presentation.
- `OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md` — P1 ready/auto, dependency-gated on F0 and mobile guard composition; it owns the three remaining weapon-definition runtime-state findings.

### Active Archive Resolve Presentation Series

Design authority: `../../../design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`.

The Archive Resolve implementation series is evidence-gated. AR1/ARR1, AR2 and AR3 are complete/passed, with AR3 human visual approval and paired review closed. AR4 frontier restraint is the active presentation slice. Separately, the P0 contract-world start fail-safe and spawn-residency corrections are implemented: selection uses canonical safety independent of paint, then realizes the selected chunk before control restore; a genuinely missing safe spawn still leaves the Operator hidden and disabled. The independent paired fresh-context review is the next gate; this correction remains separate from AR4 presentation.

- `archived/PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — AR1, complete/landed presentation-only request/commit/unload spine and one batched flat diagnostic veil.
- `archived/REVIEW_PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE.md` — ARR1, complete: passed with 0 blocking defects; RFR1 R0-04 closed; next-slice items R0-01..R0-04 recorded on the archived AR1 packet.
- `archived/PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2 implementation landed on `085a38a5`; archived receipt records renderer/visual proof missing, so do not treat it as fully accepted.
- `archived/PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1.md` — complete renderer/visual closeout recovery with authoring-chat Dropbox approval recorded.
- `archived/REVIEW_PROCGEN_ARCHIVE_RESOLVE_SHADER.md` — AR2 paired review complete/passed.
- `archived/CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX.md` + `archived/REVIEW_CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX.md` — P0 implementation/review complete-passed: final Operator spawn must be canonically valid, runtime-walkable, outside ingress clearance, and in `ProcGenTilemap.get_main_playable_component()`; 0 blocking defects / 0 material evidence gaps. Review R0-03's missing full `_on_contract_generated()` real-compound/registered-ingress proof is intentionally carried into AR3's integration validation rather than a correction packet.
- `archived/CONTRACT_WORLD_OPERATOR_VOID_SPAWN_FAILSAFE_CORRECTION.md` — P0 implementation complete: one accepted-component snapshot, deterministic safe fallback, final position round-trip guard, install-trace source/tile evidence, and hidden/disabled catastrophic failure; focused loader regressions and S1 quick passed; paired fresh-context review also passed with no findings.
- `archived/CONTRACT_WORLD_OPERATOR_SPAWN_RESIDENCY_CORRECTION.md` — P0 implementation complete: canonical spawn selection is independent of paint residency, the selected tile is realized through existing streaming lifecycle/payload/commit authority before Operator control restore, mutation coverage rejects the old filter, and true no-safe failure remains fail-closed.
- `archived/REVIEW_CONTRACT_WORLD_OPERATOR_SPAWN_RESIDENCY_CORRECTION.md` — paired fresh-context review complete; proves selection/presentation separation and preserves true no-safe-cell fail-closed behavior.
- `archived/REVIEW_CONTRACT_WORLD_OPERATOR_VOID_SPAWN_FAILSAFE_CORRECTION.md` — paired fresh-context review passed with no findings; the real-loader fallback and catastrophic failure paths passed focused checks and fallback mutation control.
- `archived/PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3 complete: bounded semantic echo, one-time ingress resolve, lighter reacquisition; landed and subsequently human-approved from the gameplay-scale contact sheet with no presentation tuning required. Paired review `REVIEW_PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` is next; retain the review-manifest dirty-tree commit mismatch as evidence-hygiene context only.
- `archived/PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT.md` — AR4 complete: distance + LOS + camera frontier with time-based pacing; landed at current tuning, visual verdict waived to playtest.
- `archived/REVIEW_PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO.md` — AR3 paired review complete: passed, 0 blocking defects, 3 non-blocking; AR4 frontier restraint is next.

The post-MR6 ProcGenTilemap rewrite packets carry temporary preservation guards
so extraction/contraction work cannot move or absorb the reveal seams before the
AR packet set is refreshed.

### Persistent Recovery Series

- Planning / refresh chat: https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search
- `archived/CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md` — R1 is complete: Operator death now resolves an active CampaignSession once before the temporary Game Over fallback; no-session worlds keep the safe fallback without inventing a campaign.
- `REVIEW_CUSTODIAN_DEATH_HANDOFF_FOUNDATION_RECOVERY_1.md` — formal R1 paired review remains ready/auto.
- `CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — R2 is `ready/auto` and dependency-gated on the formal R1 review plus reviewed H6 `hub-campaign-return`; its claiming execution agent self-refreshes the exact integration seams from those landed authorities. R2 owns exact death-outcome correlation, fallback suppression only after accepted generic return, Operator reintegration, and life-scoped death-latch re-arm. It must not duplicate H6 HubState mutation or Campaign->Hub return.
- `REVIEW_CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — paired post-land R2 review, dependency-gated on R2.
- Program tracker: `../../../design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`.
- Design authority: `../../../design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`.
- Whenever a recovery implementation/review says its successor needs architecture/design refresh, the closing summary and user-facing reply must surface the exact planning / refresh chat URL above. Do not silently re-author the recovery sequence from chatless live state.

### Agent Workflow Automation

- F11-A is now locked and executable: `CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md` plus its paired review own the missing fresh external reviewer-launch seam.
- The intended boundary is a synchronous wrapper above `workstream.py finish`: preflight Codex, claim the exact review through the existing dispatcher, launch `codex exec --ephemeral` in the claimed review worktree, preserve supervision evidence outside the worktree, and return the durable `Next Handoff` to the parent flow.
- Do not change live successor instructions to require the runner until the implementation lands and passes its paired review; current fresh-context review behavior remains valid during bootstrap.

### Active Non-Player Actor Runtime Refactor Series

Non-player actor planning / refresh chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

- Program tracker / architecture authority: `../../../design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.
- Expected program size: 11 implementation packets spanning standard combat-agent decomplexification, then commanded allies, fauna, encounter/social NPCs, static autonomous agents, and final compatibility cleanup.
- Current first-wave packet state:
  - `archived/ENEMY_MARINE_DASH_ABILITY_EXTRACTION.md` — NPA-1 implementation landed after all 23 changed-file checks passed; `MarineDash` owns the complete lifecycle and typed tuning with exact 26-field parity.
  - `REVIEW_ENEMY_MARINE_DASH_ABILITY_EXTRACTION_RECOVERY_1.md` — paired NPA-1 review is ready after implementation landing; verifies the 26-value parity, public request seam, host-service boundary, and full selected closeout.
  - `archived/ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — NPA-2 implementation landed with 25/25 selected changed-file checks passing; `SavagePounce` owns pounce state/timing and typed tuning, while the two-hit chain remains scoped to NPA-3.
  - `REVIEW_ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md` — fresh NPA-2 review passed with zero findings on branch `eec8419f6`; landing remains pending because an unrelated `living-world-abstract-activity-foundation` pairing defect blocks the required repository-wide check.
  - `archived/ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — NPA-3 implementation landed with its selected focused and changed-file checks passing; `SavageChain` owns six chain-only config values and three runtime fields while generic cadence/first-hit/contact authority remains available for NPA-4.
  - `archived/REVIEW_ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md` — paired NPA-3 fresh-context review passed with zero findings; implementation closeout recorded 31/31 changed-file checks.
  - `archived/NPA_4_STANDARD_ENEMY_MELEE_EXTRACTION.md` / archived paired review — NPA-4 complete; fresh review landed at `8817908b1` with zero defects/gaps/findings and nine focused runtime checks green. `StandardEnemyMelee` is the sole ordinary-melee transaction authority.
  - `archived/NPA_5_ENEMY_REACTION_POSTURE_EXTRACTION.md` / archived paired review — NPA-5 complete; the fresh-context review passed at `f5dc6da50` with zero findings.
  - `NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION.md` — refresh-complete NPA-6 implementation packet; moves Enemy health/death/corpse transitions and one-time loot payload assembly into one focused lifecycle owner while retaining the existing corpse collector and carrier boundaries. Implementation and paired review are dependency-gated on NPA-5 review and NPA-6 implementation respectively.
- Author NPA-7+ against reviewed landed predecessor seams rather than freezing speculative shared actor APIs. The target is composition over six actor families, not a universal NPC superclass.

### Ash-Bell / Ritualant Scene Closeout

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c

- `ASH_BELL_RITUALANT_RUNTIME_TRUTH_CLOSEOUT.md` — ready/auto P1 repair for the surviving passive Fountain stabilization path plus the Ritualant idle/kneel 7f-vs-8f semantic contract drift.
- `REVIEW_ASH_BELL_RITUALANT_RUNTIME_TRUTH_CLOSEOUT.md` — dependency-gated fresh-context post-land review of that runtime/asset truth repair.
- `ASH_BELL_FORLORN_RITUALANT_PRODUCTION_ART_CLOSEOUT.md` — remains draft and now depends on the reviewed runtime-truth slice; return here after review to lock/generate the remaining art and audio rather than guessing source/cadence contracts.

### Ash-Bell / Forlorn-Ritualant Production Art Closeout

- `archived/ASH_BELL_FORLORN_RITUALANT_AUTHORED_ENCOUNTER.md` — authored-route migration and Encounter Completion V2 runtime are landed; historical mixed code+art packet is no longer executable.
- `ASH_BELL_FORLORN_RITUALANT_PRODUCTION_ART_CLOSEOUT.md` — draft/manual Asset V2 closeout for the remaining production art; unresolved human-owned cadence/direction/source decisions keep the packet parked. Known locked targets include an 8f 128×128 rise (1024×128), 32×48 procession-cell intent, 64×96 apparition intent, and static ritual props at 96×96 / 32×32 / 32×64 / 16×16. Walk/drag/turn/reaction direction/frame/FPS contracts remain deliberately unresolved and must be human-locked before claim.
- The current required-assets registry remains the open-need authority. Do not resume the archived encounter packet or hand-copy new art into legacy runtime paths.

### Cross-cutting Stealth / Vaultwing Pre-NPA-8 Chain

Design authority: `../../../design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md`.
Actor/facet authority: `../../../design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`.

The architecture boundary is now approved. Hearing is a shared perception facet, not a Vaultwing-owned mechanic. The executable chain is deliberately serial:

1. `STEALTH_PERCEPTION_FOUNDATION.md` — P0 ready/auto; S0 + narrow S1 typed acoustic event/observation seam for Enemy + Vaultwing.
2. `REVIEW_STEALTH_PERCEPTION_FOUNDATION.md` — fresh-context paired review; no user refresh required when it passes.
3. `VAULTWING_RUNTIME_HARDENING.md` — P1 ready/auto and dependency-gated on the reviewed stealth foundation; owns fixed-step bond clocks, restore reconciliation, allegiance-sensitive compatibility, and proven Vaultwing residue only.
4. `REVIEW_VAULTWING_RUNTIME_HARDENING.md` — fresh-context paired review and intentional stop boundary.

After step 4, autonomous execution stops at the recorded `non-player-fauna-bonded-command-convergence` planning gate. NPA-8 is intentionally **not authored yet**; it must be re-derived from reviewed stealth + Vaultwing seams and the then-current earlier NPA program so no speculative universal actor API is frozen early.

## Completed Bidirectional Dropbox Handoff

- Authoring chat: https://chatgpt.com/share/6ac306f1-f2a0-83e9-9823-86add3c01c91?ogimg=plain
- `archived/BIDIRECTIONAL_DROPBOX_HANDOFF.md` — P1 implementation complete/landed. Adds immutable `CUSTODIAN/implementation_inputs/<workstream>/<handoff-id>/`, manifest/hash/path verification into non-production staging, preserves `CUSTODIAN/visual_review`, and passes real rclone plus ChatGPT Dropbox connector PNG/ZIP round-trips.
- `REVIEW_BIDIRECTIONAL_DROPBOX_HANDOFF.md` — paired P1 post-land fresh-context code/architecture/workflow review; becomes eligible after this implementation lands and archives, with hostile-manifest, credential-boundary, and live-provider evidence checks.
- The packet authorized the one-time rclone/Dropbox setup and unique sacrificial transport tests; successful remote smoke evidence is retained through paired review.

## Completed Operator Workbench Publish Readiness Cycle 2 Correction

- `archived/OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1_REVIEW_CORRECTIONS_2.md` — Cycle 2 closes R0-01 by binding Workbench publication paths to the selected animation plan and rejecting initial or pre-mutation manifest retargeting; all five focused Workbench validations pass.
- `archived/REVIEW_OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY_REVIEW_CORRECTIONS_1_REVIEW_CORRECTIONS_2.md` — Fresh-context paired cycle-2 review passed; R0-01 is fixed with no additional findings. The next existing Workbench packet is the human-authorized browser Preview disconnect-ownership correction.

## Completed Operator Workbench FX Layer Adoption

- `archived/OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md` — Explicit saved `vfx`/`fx` adoption for existing semantic animations, with schema-derived CREATE/REPLACE, review, optional mirror, and transactional rollback.
- Workstream: `operator-workbench-fx-layer-adoption`
- Implementation summary: `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION_CLAUDE_SUMMARY.md`
- Next workstream: `review-operator-workbench-fx-layer-adoption`

## Completed Operator Workbench Preview Disconnect Ownership Correction

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

- `archived/OPERATOR_WORKBENCH_BROWSER_PREVIEW_DISCONNECT_OWNERSHIP_CORRECTION.md` — P0 human-authorized R2-01 correction complete; live preview acceptance is bound to the issuing bridge connection/session, including same-document reconnects.
- `archived/REVIEW_OPERATOR_WORKBENCH_BROWSER_PREVIEW_DISCONNECT_OWNERSHIP_CORRECTION.md` — paired fresh-context review passed actual disconnect and identical-session reconnect controls; `operator-workbench-fx-layer-adoption` is the ready immediate successor.

## Selection

- Skip packets for narrow, low-risk, single-session work.
- `../AGENT_TASK_PACKET_TEMPLATE.md` is the canonical authoring specification for new packets. New packets use `Packet schema: custodian.task_packet.v2`.
- Use the compact template when scope, constraints, acceptance, evidence, or deferred work needs a durable record.
- Add full-packet sections only for high-risk, multi-session, architecture, ownership, migration, or substantial handoff work.
- Do not create a packet merely because several files change.

## Legacy Completed Records

<!-- legacy_completed_archive:start -->
- [`ASH_BELL_LOWER_QUARTER_FIRST_PASS.md`](archived/ASH_BELL_LOWER_QUARTER_FIRST_PASS.md) — Ash-Bell Lower Quarter First Playable Blockout: active spec; generic custom ingress seam; campaign ingress; exact route/level registries; shared merged-boundary blockout and local interaction components; all three authored sc...
- [`ASH_BELL_THREADWAY_POLISH.md`](archived/ASH_BELL_THREADWAY_POLISH.md) — Ash-Bell Threadway Presentation And Routing Polish: Full-width per-cell resolve lifecycle, directed deterministic wave, authored-only visual floor, organic safe routing/curved widening, occlusion cleanup, focused validation, and...
- [`COMBAT_RESOURCE_FEEDBACK.md`](archived/COMBAT_RESOURCE_FEEDBACK.md) — COMBAT RESOURCE FEEDBACK: Expanded authoritative status and threshold math; added debounced transition/failure events and observability; wired weapon JSON sound access/schema/data; attached local-only pr...
- [`COMMAND_PRESSURE_SCENARIO_V1.md`](archived/COMMAND_PRESSURE_SCENARIO_V1.md) — COMMAND PRESSURE SCENARIO V1: design authority; inert scenario launch/isolation; exact authored layout/resources/repair ports; live Power/Sector/ResourceLedger/WaveManager/Enemy/terminal integration; derived...
- [`CONTROLLER_INPUT_HARDENING.md`](archived/CONTROLLER_INPUT_HARDENING.md) — Controller Input Hardening: active design authority and audit; InputMap/controller migration; prompt service and action-driven Black Reliquary prompt path; inventory prompt consolidation; pause cancel/hint...
- [`DEV_OBSERVATORY_AUDIT_REMEDIATION.md`](archived/DEV_OBSERVATORY_AUDIT_REMEDIATION.md) — DEV OBSERVATORY AUDIT REMEDIATION: Stable ranged taxonomy/request metrics; shared attack-chain IDs; dodge/Field Patch/stamina telemetry; director/legacy and node ownership gauges; structured world-state/history m...
- [`DEV_OBSERVATORY_SESSION_EXPORT.md`](archived/DEV_OBSERVATORY_SESSION_EXPORT.md) — Developer Observatory Session Export: Extended the existing autoload with stable/timestamped JSON export, F10 input, JSON-safe Variant conversion, metadata/scene/session payloads, success/failure telemetry, absolute...
- [`ENEMY_GRUNT_ASSET_V2_RUNTIME_MODULARIZATION.md`](archived/ENEMY_GRUNT_ASSET_V2_RUNTIME_MODULARIZATION.md) — Enemy Grunt Asset V2 Migration + Runtime Modularization: current-HEAD re-audit; V2.1 enemy schema/family confirmed and expanded; hash-backed inbox migration; transactional 27-input/54-output ingest; semantic animation set/controller;...
- [`ENEMY_SAVAGE_RUSHDOWN_PROFILE.md`](archived/ENEMY_SAVAGE_RUSHDOWN_PROFILE.md) — ENEMY SAVAGE RUSHDOWN PROFILE: Scene/profile stats, WaveManager default profile, chain, pounce, guard-cost override, focused profile/runtime smokes, grunt regressions, full ingest no-op validation, normal pro...
- [`FABRICATION_TERMINAL_HIERARCHY_FIT.md`](archived/FABRICATION_TERMINAL_HIERARCHY_FIT.md) — Fabrication Terminal Hierarchy And Fit: Runtime and view-model changes, documentation drift remediation, and focused headless validation.
- [`GRUNT_FALCON_PUNCH_READABILITY.md`](archived/GRUNT_FALCON_PUNCH_READABILITY.md) — Grunt Falcon Punch Readability: Retuned the live grunt scene with a `0.75s` target-tracking tell, committed leap, forgiving contact envelope, stop-short travel, contact and enemy separation, independent cooldo...
- [`MELEE_SOFT_TARGETING_AND_RANGE_READABILITY.md`](archived/MELEE_SOFT_TARGETING_AND_RANGE_READABILITY.md) — Melee Soft Targeting And Range Readability: deterministic scoring/reach resolver, passive target preview, per-link immutable solution, additive 3/4/5 px dagger drive caps, 12/13/14-degree correction, progressive procedura...
- [`MODULAR_NEXT_ACTIONS_AND_DEV_MODE.md`](archived/MODULAR_NEXT_ACTIONS_AND_DEV_MODE.md) — Modular Next Actions And DevMode: DevMode autoload/capabilities and debug-system gates; canonical pair/chain source paths; fit center threshold; report-only backfill; next-actions JSON/Markdown helper; HTML reco...
- [`OBSERVATORY_WORLD_TELEMETRY_FOUNDATION.md`](archived/OBSERVATORY_WORLD_TELEMETRY_FOUNDATION.md) — OBSERVATORY WORLD TELEMETRY FOUNDATION: - Added authority docs for the five-system foundation and selected active design-tree locations that match current repo conventions instead of reviving the retired `design/20_fe...
- [`OPERATOR_ALIGNMENT_REPAIR_V2_HARDENING.md`](archived/OPERATOR_ALIGNMENT_REPAIR_V2_HARDENING.md) — Operator Alignment Repair V2 Hardening: Code fixes applied to `modular_alignment_repair.py` (runtime-path provenance keys, `find_exact_v2_pair_jobs`, bounded connector helper set, `connector_confidence >= 0.35` gate,...
- [`OPERATOR_FIELD_PATCH_V1.md`](archived/OPERATOR_FIELD_PATCH_V1.md) — OPERATOR FIELD PATCH V1: Added `use_field_patch` input on keyboard `P`; added Operator Field Patch tuning, carried count, timed commit, health restore, movement slow, status API, restock helper, damage/...
- [`OPERATOR_FRAME_AWARE_WEAPON_SOCKETS.md`](archived/OPERATOR_FRAME_AWARE_WEAPON_SOCKETS.md) — Operator Frame-Aware Weapon Sockets: Generated-data loader, canonical eight-way resolver, phase-1 JSON, definition schema/data, frame layout, muzzle/ejection getters, authored plus procedural recoil, direction-awar...
- [`OPERATOR_MODULAR_INGEST_HARDENING.md`](archived/OPERATOR_MODULAR_INGEST_HARDENING.md) — Operator Modular Ingest Hardening: Generalized modular layer routing and post-process selection; added action-family source buckets; normalized generic modular actions into stable runtime modules; generated/impor...
- [`OPERATOR_WORKBENCH_CANVAS_MIGRATION.md`](archived/OPERATOR_WORKBENCH_CANVAS_MIGRATION.md) — Operator Workbench Canvas Contract Migration: Center-copy transform, scopes, coordinate dependency audit, staged `frame_canvas` manifest, CLI and Shift+R review/apply flow, dirty live-document guard, committed runtime-catal...
- [`PARRY_CRITICAL_BRANCHING_AND_VFX.md`](archived/PARRY_CRITICAL_BRANCHING_AND_VFX.md) — PARRY CRITICAL BRANCHING AND VFX: Added authored grunt enter/hold/recover registrations and phases; preserved the post-knockback enemy root and suppressed ordinary targeting through standalone recovery; realigne...
- [`PROCGEN_PRETERRAIN_DIAGNOSTICS_EXTRACTION.md`](archived/PROCGEN_PRETERRAIN_DIAGNOSTICS_EXTRACTION.md) — PROCGEN PRETERRAIN DIAGNOSTICS EXTRACTION: Added four context-driven diagnostic services; converted `ProcGenTilemap` collection, diagnostics, component, and repair functions into façade adapters; reduced the coordinator...
- [`PROCGEN_STUCK_POCKET_AUTHORITY.md`](archived/PROCGEN_STUCK_POCKET_AUTHORITY.md) — PROCGEN STUCK POCKET AUTHORITY: runtime collision-owner overlay; navigation consumption; tree/ruin wiring; route/structure/combat clearances; forgiving trunk defaults; deterministic two-exit pocket remediation...
- [`RANGED_COMBAT_BALANCE_AND_STEALTH.md`](archived/RANGED_COMBAT_BALANCE_AND_STEALTH.md) — RANGED COMBAT BALANCE AND STEALTH: Typed/capped ammo and pickups, persistent magazines, range/falloff, movement accuracy, per-weapon heat/overheat, generic noise events, enemy hearing, LOS-loss search/leash, auth...
- [`RUNTIME_READY_ASSET_DROP.md`](archived/RUNTIME_READY_ASSET_DROP.md) — Runtime-Ready Asset Drop: Added the persistent drop tree, mirrored and sidecar routing, conflict-safe apply, explicit replacement, source archives, JSON receipts, optional Godot import, smoke validation,...
- [`RUNTIME_STUTTER_PERFORMANCE_PASS.md`](archived/RUNTIME_STUTTER_PERFORMANCE_PASS.md) — Runtime Stutter Performance Pass: Hidden Observatory sampling gate and consolidated tree walk; deferred streaming rebuilds; shared spatially bounded foliage work; dormant tier workload suppression; throttled int...
- [`SUNDERED_KEEP_FRONTAGE_CORRECTNESS.md`](archived/SUNDERED_KEEP_FRONTAGE_CORRECTNESS.md) — SUNDERED KEEP FRONTAGE CORRECTNESS: Final-floor frontier collision and physical smoke; frontage commit-line/apron semantics and seed bypass smoke; continuous Keep-targeted camera envelope, apex hold, scale adjustm...
- [`SUNDERED_KEEP_MAPPER_CONSOLIDATION.md`](archived/SUNDERED_KEEP_MAPPER_CONSOLIDATION.md) — Sundered Keep Mapper Consolidation: consolidated approach-rail, underlay-rail, marker, palette, underlay-stamp, drag-paint, undo/redo, feature relocation, and siege placement tools into `sundered_keep_mapper.tscn`...
- [`SUNDERED_KEEP_ROUTE_MASTER_APPROACH.md`](archived/SUNDERED_KEEP_ROUTE_MASTER_APPROACH.md) — SUNDERED KEEP ROUTE MASTER APPROACH: Pipeline warning added for future unsupported Operator modular melee block/hitreact loadouts. Inbox blocking hitreact filenames were made explicit as `unarmed`. The approach now...
- [`TERMINAL_SENSORS_INTELLIGENCE_V1.md`](archived/TERMINAL_SENSORS_INTELLIGENCE_V1.md) — TERMINAL SENSORS INTELLIGENCE V1: active design; stable and bounded stale-contact read model; pure contact/forecast fidelity projection; EnemyDirector/ARRN view model; FRAGMENTED semantic-sector minimap markers;...
- [`TERMINAL_TYPOGRAPHY_SYSTEM.md`](archived/TERMINAL_TYPOGRAPHY_SYSTEM.md) — TERMINAL TYPOGRAPHY SYSTEM: IBM Plex font binaries and OFL provenance are vendored; guarded loading, semantic helpers, hierarchy, sizes, clipping, no-wrap filters, and typography smoke are implemented. Typ...
- [`TERRAIN_GAMEPLAY_ART_RUNTIME_VISUALS.md`](archived/TERRAIN_GAMEPLAY_ART_RUNTIME_VISUALS.md) — Terrain Gameplay Art Runtime Visuals: Source-map entries 60–123 and opt-in runtime usage debugging added. TerrainBuilder/compound industrial ramps select Ascent Pack wide ramps; surviving compound-connector floor an...
- [`VIGIL_PATTERN_DAGGER_ATTACK_DRIVE.md`](archived/VIGIL_PATTERN_DAGGER_ATTACK_DRIVE.md) — VIGIL-PATTERN DAGGER ATTACK DRIVE: generic drive and per-link profiles; weapon-owned body/weapon/FX resources; two weapon-specific pipeline layers; canonical 156×96 outputs; dagger default; optional cleaver overr...
- [`WORLD_ORIGIN_BRANCH_ISOLATION.md`](archived/WORLD_ORIGIN_BRANCH_ISOLATION.md) — WORLD ORIGIN BRANCH ISOLATION: Shared grouped-branch snapshot/isolation/restoration; static and dynamic branch classification; Vista authority cleanup; leaking-sector visual/collision regression; full-route p...
<!-- legacy_completed_archive:end -->

## Workflow

1. Decide whether a packet adds enough value to justify maintaining it.
2. If so, copy `../AGENT_TASK_PACKET_TEMPLATE.md` into this folder.
3. Rename it after the task in uppercase snake case, for example `VALIDATION_RECIPES.md`.
4. Review current `origin/main`, fill the V2 contract fields, and delete unused optional expansion sections.
5. Do not set `ready` until the completion boundary, evidence, work surface, acceptance, validation, dependencies/locks, and review intent are implementation-ready.
6. Keep the packet current when scope, blockers, acceptance, validation, or deferred work materially changes.
7. Before `complete`, add the structured `Execution Feedback` receipt and mirror it in the required closing summary.
8. Mark it `complete` only after implementation, required docs updates, feasible validation, feedback, and completion notes are done.

## V2 Packet Contract

New packets use `Packet schema: custodian.task_packet.v2`. Legacy packets
without a schema remain valid and are not bulk-migrated.

A ready V2 packet must carry enough live evidence and scope control for a fresh
agent to execute it without reconstructing intent from chat history. At minimum
it records the reviewed main SHA, coherent completion boundary, measured current
state, concrete evidence, task-specific authorities, work surface, change,
preservation/non-goals, measurable acceptance, focused validation, and deferred
work. The template's Authoring Quality Gate is the canonical checklist.

A packet should reference technical truth already owned by code/data/schema
rather than copying it. Packet text owns the task closure contract, not duplicate
runtime configuration.

For presentation-heavy packets, author objective visual validation first. If
material subjective judgment will still remain after those checks, route one
compact external handoff through
`custodian/tools/iteration/publish_review_artifacts.py` and
`custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`. The execution agent should
return the Dropbox manifest path and reviewer questions, not perform a redundant
aesthetic critique of its own captures.

## Execution Feedback

Every V2 packet gets a compact process receipt before completion:

```text
Feedback schema: custodian.task_feedback.v1
Outcome: success | partial | blocked
Friction severity: none | low | medium | high
What went wrong
Root cause / contributing factors
Prevention / pipeline improvement
Tooling / docs drift discovered
Follow-up
What worked (optional)
```

The useful signal is failure/friction and prevention. "What worked" may be one
short line or omitted.

If a repeatable medium/high-severity workflow issue is found, either fix the
small safe correction in the current scope or name/create a follow-up before the
packet becomes complete. The required closing summary mirrors the same fields so
unpacketed tasks also leave process feedback.

## Dispatch

Use the canonical queue states: `ready/auto` is executable once dependencies, locks, pairing, and validation clear; `ready/manual` is executable only by explicit claim; `draft/manual` is intentionally parked and records its concrete refresh or human-decision reason in the body/handoff. Active V2 `draft/auto` is invalid. Keep dependency-gated mechanical work `ready/auto` so it becomes claimable as soon as dependencies archive `complete`.
`dispatch.py status` separates READY, CLAIMED, DEPENDENCY/LOCK BLOCKED, MANUAL READY, PARKED DRAFT, and INVALID/RECOVERY. The Ready/Auto README index lists valid ready/auto packets, including those waiting on ordinary dependencies.
For an identity-level audit including exact claim eligibility, dependencies,
review pairing, and local/remote branch and worktree evidence, run
`python3 custodian/tools/agent/dispatch.py audit` (`--json` for stable records).
The bounded `dispatch.py repair --plan` previews named mechanical metadata
repairs; `--archive-completed` additionally previews legacy files only when
their status and non-empty completion receipt prove closure. Apply preserves
bytes and updates authoritative packet-path references. Neither command deletes
branches, claims, or worktrees.
`dispatch.py status` reads packet truth from fetched `origin/main`; use
`dispatch.py claim-next --agent <agent-id>` (for example `--agent claude` or
`--agent codex`) to claim the highest-priority eligible auto packet, or
`dispatch.py claim <workstream-id> --agent <agent-id>` for explicit selection
(including manual packets). Omitting `--agent` falls back to the
`CUSTODIAN_AGENT_ID` environment variable, then a neutral `unspecified` —
never a silently assumed agent brand. Initial claims and direct starts share
unique remote Git claims and per-workstream local mutexes so separate clones
cannot acquire the same task; interrupted
claims require explicit operator recovery. `Priority` is `P0`–`P3` (default `P2`),
`Depends on` lists workstream IDs that must be complete and archived on main,
and `Locks` lists narrow contention IDs. A missing `Dispatch` remains manual.
Claims create/resume exactly one existing `agent/<id>` workstream and do not
edit packet state on main; normal lifecycle progression and archival happen
on the task branch. A successful claim's `CLAIMED` banner and
`CUSTODIAN_DISPATCH_RESULT_JSON:{...}` line are the assignment authority. The
receipt also carries packet authoring-chat provenance, visual-review mode,
canonical Dropbox workstream root, and the `delete-after-review` default so an
autonomous claimant receives the human-review route together with assignment; if
that output is lost, recover it read-only with `dispatch.py last-claim` (or
`--json`) rather than inferring ownership from worktree/branch activity.
Continuous workers and cross-machine leases are deferred.

The local dispatcher mutex is separate from packet eligibility. `claim` and
`claim-next` fail fast with `LOCAL DISPATCH BUSY` when another process sharing
the Git common directory is in the assignment-critical section. To wait
intentionally, pass `--lock-wait-seconds N`; the wait is bounded and defaults
to zero. Never delete `dispatch.lock` or terminate its holder: `flock` locks
the inode, and unlinking a held file can allow two independent mutexes.

Three blocked states must not be conflated:

1. `LOCAL DISPATCH BUSY` is local process contention; retry after the active
   assignment finishes.
2. A packet `Locks:` conflict makes that candidate ineligible while a claimed
   packet holds the same logical lock.
3. A `dispatch-claims/<id>` ref without `agent/<id>` is interrupted remote
   recovery state and requires explicit inspection.

The dispatcher reads packet truth from fetched `origin/main`; a stale local
`main` checkout alone does not block assignment. Diagnostic refs are
best-effort and publish after the assignment-critical mutex is released, so a
slow diagnostic push cannot hold up unrelated local claims. Diagnostic
publication failure does not change the canonical claim or last-claim receipt.

For interactive Codex, the repository provides the repo-local
`$custodian-next` skill. It is also selectable from `/skills` and may appear
directly in the slash picker. It does not change dispatcher eligibility: it
continues an already-active workstream, otherwise prefers the durable immediate
`Next Handoff` in the same series, respects refresh/manual/dependency gates,
and uses global `claim-next` only when no same-series successor exists.

## Packet Handoff And Authoring-Chat Provenance

Newly authored or materially refreshed V2 packets record
`Authoring chat: <ChatGPT conversation URL | not-recorded | n/a>`. When the
user provides the originating conversation URL, preserve it exactly. Agents
must never derive or invent ChatGPT conversation URLs.

Every completed packet/review reports the immediate successor in its own
program/DAG through the required `Next Handoff` fields: next workstream,
packet state, refresh owner, whether ChatGPT/user planning refresh is required,
authoring-chat URL, refresh reason, next action, and blockers. The durable
`<TASK>_CLAUDE_SUMMARY.md` is the persistent copy of that handoff.

A ready/eligible named successor with
`ChatGPT/user planning refresh required: no` is an **autonomous continuation**,
not a user relay point. The agent/worker claims that successor itself and
continues through the same-series implementation/review/correction chain.
Paired reviews still require a fresh reviewer context, but that context switch
does not require the user to carry the prior summary.

Dependency-driven refreshes default to `Refresh owner: execution-agent` and happen
at claim time from current main plus landed predecessor evidence. Use
`Refresh owner: chatgpt-user` only when a genuine unresolved design choice
requires the user's judgment before implementation can proceed. At that boundary
the agent stops and surfaces only the exact recorded Authoring/Refresh chat URL,
the copyable workstream ID, and the persistent summary path; the user opens the
linked conversation and pastes the workstream ID. Mechanical refreshes that do
not change scope, ownership, sequencing, acceptance, visual direction, or design
interpretation remain execution-agent work.

Historical packets without an authoring URL remain valid; surface
`Authoring chat: not-recorded` and ask the user to provide the originating
chat URL if they have it. For current packeted work, `workstream.py finish`
programmatically rejects a committed closing summary that omits a recorded exact
Authoring/Refresh chat URL.

## Visual Review Handoff And Retention

New/materially refreshed packets declare `Visual review: none | conditional | required`.
`conditional` means objective checks run first and a subjective handoff is created
only if a material question survives; `required` means the packet cannot close
without the recorded ChatGPT/user decision.

The authoring conversation supplies the exact review route: `Authoring chat`, the
Dropbox root `/CUSTODIAN/visual_review/<workstream>/`, a bounded evidence budget,
and exact reviewer questions. Execution/review agents publish with
`publish_review_artifacts.py --important --reason ... --authoring-chat <url>`,
return the emitted manifest path to that exact authoring conversation, and pause
the same workstream at the subjective decision boundary. ChatGPT web should use
the connected Dropbox source to inspect the exact manifest path rather than
requesting duplicate media.

Cloud review media defaults to `delete-after-review`. After the decision is
recorded, the same workstream runs the emitted `cleanup_command`; explicit
`--retain-after-review` is required to keep the run. Durable Git evidence keeps
the manifest/run id, decision, and cleanup/retention result, not the bulk media.

## Paired Review Default And Independence

For newly authored or materially refreshed V2 implementation packets, use `Review: auto` by default when independent review can materially improve confidence. This includes runtime/state-machine/persistence/streaming changes, architecture extraction or migration, production asset-pipeline/tooling mutations, performance changes that must preserve semantics, validation/workflow infrastructure, substantial bug fixes, and objective technical presentation work. `Review: none` is a low-risk exemption for documentation-only truth repair, tiny mechanical patches with obvious local effects and direct regression coverage, disposable probes, or similarly inspectable changes; record a concrete `Review rationale: low-risk exemption: ...`. Do not disable review merely to reduce queue length.

Paired review requires a **fresh reviewer context**. A different agent/context is preferred when available, but a different model family is not mandatory. The same model/agent family may review prior work only from a newly started context/workstream with no transient implementation reasoning carried forward, reconstructing the target from the archived packet, closing summary, live code, design authority, tests, and fresh traces/mutations. Record `Reviewer context: fresh` and `Reviewer provenance: different-agent | same-agent-fresh-context` in the durable review artifacts. Continuing the implementation conversation/session is self-review and does not satisfy the paired-review contract.

Legacy packets are not bulk-retrofitted. When new work materially depends on an older unreviewed/legacy seam, re-check the surviving live authority and focused behavior during authoring; use paired review for the new slice when that seam is high-risk, unclear, or central to acceptance.

## Paired Review And Correction

Post-land review intent is decided when the implementation packet is created. For newly authored or materially refreshed V2 engineering packets, `Review: auto` is the risk-based default described above; `Review: none` is the explicit low-risk exemption. It uses ordinary dispatcher primitives
(`Dispatch`, `Depends on`, `Locks`) rather than a second scheduler, and
happens after validated implementation already landed on `main` — it is never
a `workstream.py finish` blocker.

- Declare `Review: auto` on the implementation packet and create a paired
  review packet from `AGENT_REVIEW_PACKET_TEMPLATE.md` on `main` in the same
  change. The review packet declares `Kind: review`, `Review: none`,
  `Depends on: <implementation-id>`, and `Review target workstream:
  <implementation-id>`, `Review target packet:
  custodian/docs/ai_context/task_packets/archived/<implementation-packet-filename>`,
  `Status: ready`, and `Dispatch: auto`.
- `dispatch.py`'s review-pairing consistency guard
  (`custodian/tools/agent/validate_review_pairing.py`) fails closed for any
  active `Review: auto` packet whose pair is missing, wrong `Kind`, wrong
  `Review`, not ready or auto-dispatchable, or whose dependency/target
  workstream/canonical archived target-packet path does not match. The packet
  path must identify the exact implementation packet filename under the
  canonical `archived/` directory; missing and traversal paths are rejected.
  Historical packets that omit review metadata (`Review: none`, the default)
  are never required to pair.
- The review becomes dispatcher-eligible once its implementation dependency
  is `complete` and archived, exactly like any other dependency — no new
  eligibility mechanism.
- A reviewer works from fresh `origin/main` in its own workstream, never
  modifies reviewed implementation/runtime code, and appends a durable `##
  Independent Review` receipt to the archived implementation packet:

  ```md
  ## Independent Review

  - Status: `pending | passed | findings | human_required`
  - Review workstream: `review-...`
  - Reviewed on main: `<short SHA/current target>`
  - Reviewer context: `fresh`
  - Reviewer provenance: `different-agent | same-agent-fresh-context`
  - Review modes: `...`
  - Blocking defects: `N`
  - Material evidence gaps: `N`
  - Non-blocking issues: `N`
  - Optional improvements: `N`
  - Correction finding IDs: `R0-01, ... | none`
  - Next-slice finding IDs: `... | none`
  - Human-decision finding IDs: `... | none`
  - Detailed review summary: `<reviewer closing-summary path>`
  - Follow-up workstream: `none | <correction-id>`
  ```

- Each finding has a stable cycle-scoped ID (`R<cycle>-<NN>`), class
  (`blocking_defect`, `evidence_gap`, `non_blocking_issue`,
  `optional_improvement`), domain (`implementation`, `pipeline`), affected
  acceptance, evidence, disposition (`correction`, `next_slice`, `deferred`,
  `human_required`, `no_action`), and rationale. Re-review retains an existing
  ID when reporting `fixed`, `unresolved`, or `regressed`; new findings use the
  current cycle's next ID.
- Correction threshold: confirmed acceptance/correctness defects and evidence
  gaps that prevent confidence in required acceptance become correction work.
  Other evidence gaps, non-blocking issues, and optional improvements are
  recorded for next-slice/deferred unless separately justified. Subjective
  design, canon, art-direction, or game-feel decisions use `human_required`.
  Do not turn taste, speculative optimization, or cleanup into a correction.
- Implementation findings stay separate from pipeline/process findings.
  Record the latter through `custodian.task_feedback.v1`; fix a small safe
  repeatable workflow problem in-scope or name a follow-up for medium/high
  severity.
- Use `AGENT_CORRECTION_PACKET_TEMPLATE.md` for correction work. It records a
  narrow delta against exact finding IDs and affected acceptance; it does not
  repeat the original feature design. Its paired review uses the ordinary
  finite review-cycle mechanism.
- A paired post-land review packet must include the bounded `TASK OVERRIDE:`
  that authorizes staging, committing, and pushing only its durable review
  receipt, required closing summary, review-packet lifecycle/archive metadata,
  and bounded correction/re-review packets. It must explicitly forbid editing
  the reviewed implementation and unrelated work. Dispatcher validation
