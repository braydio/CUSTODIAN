Warning: truncated output (original token count: 31877)
Total output lines: 936

====================================
    braydenchaffee@archdesk
  🐧 Sat Oct 31 01:55:44 EDT 2026
====================================
🕒 Uptime:   14 hours, 43 minutes
💽 Disk:     807G/916G
💾 Memory:   26Gi/31Gi
# Agent Task Packets

Last updated: 2026-10-17

Task packets are optional, task-scoped risk-control and handoff files for CUSTODIAN agents.

### Automatic task packet authoring handoff

For a newly authorized V2 implementation/correction packet and its paired
post-land review, set `- Authoring handoff: auto` on **both** and publish them
together to `origin/main` as `draft/manual`. The push-triggered
`.github/workflows/packet-authoring-handoff.yml` runs the targeted
`packet_authoring_handoff.py` tool. It validates the pair, promotes both
to `ready/auto`, checks their queue and referenced validation scripts,
updates the bounded Ready/Auto index, then commits and fast-forward pushes
only the two packets and the generated README.

This is opt-in: no marker means no automatic promotion. Do **not** opt in
planning/human-decision holds, blocked reviews, or unreconciled refreshes.
Failures stop without publication, force pushing, claiming or overriding
locks. An hourly retry checks only remaining explicit opt-ins, so a main-branch
race does not require another user/Codex preflight. The GitHub action runs authoring, **not local Codex execution**;
`dispatch.py` remains the sole execution/dependency/lock authority.
A normal Codex dispatcher worker can claim later if the live audit says
eligible. CI write permission and allowed non-force main push are required.

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

**Index semantics:** the following Ready/Auto list reflects authored
metadata, not the dispatcher's live eligibility. A packet can appear here
while dependencies, locks, original claims or review acceptance block it.
Use `python3 custodian/tools/agent/dispatch.py audit --json` for the live
executable count and `python3 custodian/tools/agent/queue_frontier.py` on
that audit for a read-only ranking of root blockers. New packets must include
their existing required tools/files in the same main publication as the
packet and its paired review, not as chat-only downloads.




<!-- task_packet_index:managed:start -->
- `AGENT_NEXT_EXECUTION_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md` — Make scoped general fallback fail closed unless the dispatcher supplies a candidate identity that can be checked against the requested scope.
- `AGENT_OPERATOR_IDLE_RETARGET_SOURCE_SCOPE_ATTESTATION_V1.md` — Let the preserved independent technical review validate the exact two source files omitted from the original archived Task 015 source declaration, without re...
- `CARROW_MAPPER_TRANSACTIONAL_EDITING_V1.md` — Give Carrow reversible, transactional editing and reliable per-room draft/save bookkeeping.
- `COORDINATION_ROOT_DIRTY_PREVENTION_RECOVERY_V1.md` — Stop task/agent tooling from leaving the persistent CUSTODIAN coordination checkout dirty, and give the user a safe, observable, low-effort way to recover un...
- `LIVING_WORLD_POPULATION_SLOT_RESERVATIONS.md` — Guarantee **at most one pending or consumed physical allocation per F14-managed logical actor identity**, including cancel, rollback, stale callback and camp...
- `MAPPER_CANVAS_NAVIGATION_V1.md` — Give reusable mapper scenes reliable editor-camera pan, zoom, fit and focus without modifying canonical game projection.
- `MAPPER_SOURCE_WRITE_SAFETY_V1.md` — Disambiguate draft save, finishing geometry, and explicit production source apply across mapper scenes.
- `OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md` — Seal the `operator.gd` actor/chassis ownership boundary **before F2/F3/F5/F6 extraction**, preventing new or reinstated gameplay-domain authorities while exi...
- `PAIRED_REVIEW_DIRECT_TAIL_RECEIPT_CLOSEOUT_V1.md` — Make the exact scoped-snapshot archive-to-source-tail history verifiable and prevent canonical review receipt formatting from stranding an otherwise valid in...
- `REVIEW_AGENT_EXECUTION_RESET_V1.md` — (no Goal recorded)
- `REVIEW_AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md` — Independently falsify the bounded historical Grunt SIX-file exception (three Markdown + three source/data), particularly forged attestation, pre-approval byp...
- `REVIEW_AGENT_LEGACY_CLAIM_SCOPED_SNAPSHOT_V1.md` — Independently verify that scoped preservation captures every byte required to restore one exact protected claim without depending on unrelated mutable Git LF...
- `REVIEW_AGENT_NEXT_EXECUTION_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md` — Independently establish that R0-01 is fixed: scoped general fallback fails closed without weakening dispatcher authority or the pair budget.
- `REVIEW_AGENT_OPERATOR_3D_MODEL_TO_SPRITE_SOURCE_SCOPE_RECOVERY_V1.md` — Independently establish that the exact historical source-scope exception is authentic, narrowly bounded, review-gated and cannot bypass ordinary paired-revie...
- `REVIEW_AGENT_OPERATOR_IDLE_RETARGET_SOURCE_SCOPE_ATTESTATION_V1.md` — Independently verify that the one historical source-scope exception is exact, inert before accepted review, and unable to broaden ordinary source-path valida...
- `REVIEW_AGENT_PAIRED_REVIEW_ARCHIVED_RECEIPT_CAPTURE_RECOVERY_V1.md` — Independently verify exact-run receipt-capture reconciliation without fabricating PASS, changing reviewer evidence, weakening canonical validation or touchin...
- `REVIEW_AGENT_PAIRED_REVIEW_BRACED_WORK_SURFACE_V1.md` — Independently prove that exact braced Work surface expansion restores legitimate source-span review validation without weakening provenance or widening host-...
- `REVIEW_AGENT_PAIRED_REVIEW_CHECKPOINT_RESUME_MERGE_PROVENANCE_V1_REVIEW_CORRECTIONS_1.md` — Independently close finding `R0-01` by falsifying the checkpoint-resume merge and owned-source negative cases with real Git histories.
- `REVIEW_AGENT_PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md` — Independently verify that the two missing historical merge witnesses are accepted only through authenticated conflict-resolution evidence while ordinary sour...
- `REVIEW_AGENT_PAIRED_REVIEW_DECLARED_DOC_ARCHIVE_GATE_V1.md` — Independently verify that only exact Markdown paths declared in the archived implementation packet's Work surface extend source-bearing archive eligibility.
- `REVIEW_AGENT_PAIRED_REVIEW_EXCLUDED_COVERAGE_EVIDENCE_RECOVERY_V1.md` — Independently falsify the host-validation recovery coverage fix before any original held review is retried.
- `REVIEW_AGENT_PAIRED_REVIEW_EXCLUDED_COVERAGE_EVIDENCE_RECOVERY_V1_REVIEW_CORRECTIONS_1.md` — Independently verify the correction's immutable policy provenance, attestation binding, selection/ownership accounting and fail-closed report closeout.
- `REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md` — Independently falsify failed-host-report replacement, generated Grunt import-sidecar classification, unsafe deletion, source mutation hiding, unbounded retri...
- `REVIEW_AGENT_PAIRED_REVIEW_FINDINGS_CLOSEOUT_V1.md` — Independently falsify the new nonpassing administrative-closeout, accepted-review dependency and same-run recovery contracts without touching the preserved R...
- `REVIEW_AGENT_PAIRED_REVIEW_FINISH_INDEX_CODEX_EXITED_PASS_RECOVERY_V1.md` — Independently falsify the exact-run PASS recovery before any mutation of the preserved review claim or evidence.
- `REVIEW_AGENT_PAIRED_REVIEW_GODOT_CACHE_ACCESS_V1.md` — Independently prove the paired-review sandbox gains only the CUSTODIAN validation cache access it needs while retaining real Godot concurrency controls and r...
- `REVIEW_AGENT_PAIRED_REVIEW_HOST_VALIDATION_RECOVERY_V1_REVIEW_CORRECTIONS_1.md` — Independently verify that correction 1 safely enables recovery planning and apply for the exact historical W1 claim without changing its preserved evidence o...
- `REVIEW_AGENT_PAIRED_REVIEW_MISSING_ARCHIVED_DISPOSITION_CONTINUATION_V1.md` — Independently verify that the new continuation-02 recovery can complete only the exact protected review attempt after its first continuation omitted canonica...
- `REVIEW_AGENT_PAIRED_REVIEW_NOOP_MAIN_SYNC_TRACE_V1.md` — Independently falsify the no-op main-sync trace exception and prove it doesn't weaken provenance or source-span security.
- `REVIEW_AGENT_PAIRED_REVIEW_POST_MERGE_FOLLOWUP_PROVENANCE_V1.md` — Independently falsify source-span attribution across canonical archive, exact sync merge, and bounded post-merge follow-up commits without weakening trace pr...
- `REVIEW_AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md` — Independently prove the exact eight-file P1 historical source authorization cannot become a reusable bypass or silently rewrite the existing P1 review.
- `REVIEW_AGENT_PAIRED_REVIEW_SOURCE_SPAN_MAIN_SYNC_RECOVERY_V1.md` — Independently falsify main-sync trace binding and source-span integrity without touching either preserved review run.
- `REVIEW_AGENT_PERSISTENT_TASK_ADMINISTRATOR_REVIEW_SCOPE_RECOVERY_V1.md` — Independently falsify the EXACT one-path historical source-scope exception before allowing the already-claimed original administrator implementation review t...
- `REVIEW_AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md` — Independently falsify the P0 task-administrator observer/low-token Codex operator before its later delegation/recovery authority is contemplated.
- `REVIEW_AWAKENING_COLLISION_MAPPER_AUTHORING_BRIDGE_V1_REVIEW_CORRECTIONS_1.md` — Independently verify that the correction closes R0-01 and R0-02 with lossless real save/reopen and trustworthy exact draft handoff while preserving draft-onl...
- `REVIEW_CARROW_MAPPER_TRANSACTIONAL_EDITING_V1.md` — Independently verify the landed result of give Carrow reversible, transactional editing and reliable per-room draft/save bookkeeping.
- `REVIEW_COORDINATION_ROOT_DIRTY_PREVENTION_RECOVERY_V1.md` — Independently falsify the prevention/snapshot/recovery claims, specifically that automatically recovering routine root contamination never loses user-owned b...
- `REVIEW_LIVING_WORLD_POPULATION_SLOT_RESERVATIONS.md` — Independently verify managed spawn **at-most-once** reservation, cancellation/replay safety and camp/global quota convergence at the real F04 scheduler queue...
- `REVIEW_MAPPER_CANVAS_NAVIGATION_V1.md` — Independently verify the landed result of give reusable mapper scenes reliable editor-camera pan, zoom, fit and focus without modifying canonical game projec...
- `REVIEW_MAPPER_SOURCE_WRITE_SAFETY_V1.md` — Independently verify the landed result of disambiguate draft save, finishing geometry, and explicit production source apply across mapper scenes.
- `REVIEW_OPERATOR_CHASSIS_AUTHORITY_SEAL_V1.md` — Independently determine whether the landed seal genuinely blocks `operator.gd` rebloat without becoming a paperwork-only metric or breaking legitimate Operat...
- `REVIEW_PAIRED_REVIEW_CARROW_CLAIMED_WORKTREE_RECOVERY_V1.md` — Independently falsify any path that reconstructs a missing claimed checkout without exact identity, ownership/evidence proof, immutable original reports, bou...
- `REVIEW_PAIRED_REVIEW_DIRECT_TAIL_RECEIPT_CLOSEOUT_V1.md` — Independently challenge the direct-tail source-base authentication and coordinator-owned receipt formatting/recovery without weakening quarantine or reviewer...
- `REVIEW_PAIRED_REVIEW_POST_MERGE_SOURCE_SPAN_WITNESS_V1.md` — Independently challenge the source-span verifier's two newly evidenced no-op witness topologies without weakening strict source provenance.
- `REVIEW_PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1.md` — Independently establish that missing-checkout recovery cannot reconstruct or launch a reviewer without authentic exact-run provenance, safe evidence disposit...
- `REVIEW_PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1_REVIEW_CORRECTIONS_1.md` — Falsify the new interior main-sync source-span merge acceptance and confirm it unblocks canonical validation without widening source ownership.
- `REVIEW_QUEUE_EXECUTION_FRONTIER_RESTORATION_V1.md` — Independently falsify the live queue-frontier restoration, eligibility classifications, and preservation of existing claims and review gates.
- `REVIEW_WORKSTREAM_FINISH_INDEX_CONFLICT_RECOVERY_V1.md` — Independently verify that the Protected lifecycle correction accepts only the exact authenticated managed-index conflict-and-repair sequence, correctly bound...
- `REVIEW_WORKTREE_BACKLOG_CENSUS_AND_SAFETY_LEDGER_V1_REVIEW_CORRECTIONS_1.md` — Independently determine whether correction cycle 1 resolves original finding R0-01 for W1's read-only inventory acceptance, without changing or erasing the o...
- `REVIEW_WORKTREE_BACKLOG_DIRTY_AND_UNIQUE_PRESERVATION_V1.md` — Independently verify the worktree backlog worktree backlog dirty and unique preservation v1 implementation against exact proof of no lost work, no stolen cla...
- `WORKTREE_BACKLOG_DIRTY_AND_UNIQUE_PRESERVATION_V1.md` — Prove that all original dirty work and unique unlanded HEAD history have byte-safe recovery copies before any archive, adoption or retirement decision.
- `AGENT_BLOCKER_CAPTURE_HOOKS_V1.md` — Capture actionable workflow interruptions automatically at existing owner-controlled lifecycle boundaries.
- `AGENT_BLOCKER_INBOX_PUBLISHER_V1.md` — Publish strict, redacted, persistent blocker events into dedicated ops/blocker-inbox branch without affecting dispatcher or reviewer outcomes.
- `AGENT_BLOCKER_RECOVERY_RECONCILIATION_V1.md` — Support ChatGPT on-demand blocker triage, root-cause grouping and evidence-verified incident closure without autonomous claim or reviewer authority.
- `AGENT_BOUNDED_TASK_CONTEXT_V1.md` — Stop Codex from repeatedly flooding its context with full repository-wide queue search and massive authority-document dumps while preserving accurate task/AG...
- `AGENT_LONGFORM_REVIEW_AND_GATE_HARDENING_V1.md` — Review and human gate truth through the existing CUSTODIAN workflow authorities.
- `AGENT_LONGFORM_SESSION_CORE_V1.md` — Real CLI and durable accounting through the existing CUSTODIAN workflow authorities.
- `AGENT_LONGFORM_TELEMETRY_AND_STANDARD_ADOPTION_V1.md` — Truthful usage and standard execution reuse through the existing CUSTODIAN workflow authorities.
- `AGENT_LONGFORM_VALIDATION_ECONOMY_V1.md` — Explainable validation planner through the existing CUSTODIAN workflow authorities.
- `AGENT_ORPHAN_RECOVERY_FENCED_PARKING_V1.md` — Automatically release a confirmed dead Codex session's **execution lock**, preserve its unfinished branch/worktree/evidence and make it resumable, without do...
- `AGENT_VALIDATION_EVIDENCE_FRESHNESS_V1.md` — Explain precisely when a previously green validation report is still evidentially relevant and why a changed-tree/post-sync sweep must rerun, without caching...
- `ASH_BELL_HIGHLANDS_GENERATED_DESTINATION.md` — Register a distinct generated Ash-Bell Alpine Highlands route destination that can receive the Operator from the Ritualant route and reserve an outward termi...
- `ASH_BELL_LIFT_DEV_QUICK_LAUNCH.md` — Launch the real playable CUSTODIAN runtime directly outside the Ash-Bell surface lift from a developer-only named preset, without replaying the campaign or u...
- `ASH_BELL_RITUALANT_RUNTIME_TRUTH_CLOSEOUT.md` — Make the live Forlorn-Ritualant peaceful-resolution and base-animation contracts match the already-authoritative authored-encounter design before further pro...
- `ASH_BELL_RITUALANT_STATIC_ASSET_INTAKE.md` — Publish and wire the 12 already-reviewed Ritualant ritual-prop/chamber-dressing states through Asset Pipeline V2 without reopening encounter behavior or maki...
- `ASH_BELL_SURFACE_LIFT_V2_PRESENTATION_INTEGRATION.md` — Replace the Ash-Bell lift's legacy industrial presentation with approved rail-free deck/projectors/safety-field VFX across surface and underground, leaving e...
- `AWAKENING_GATE_LATERAL_OVERLOOKS_ART_INTEGRATION_V1.md` — Wire the six user-selected Gate-of-Dust overlook art sources to the **reviewed existing west/east lateral blockout** in `custodian/scenes/awakening_first_ret...
- `AWAKENING_GATE_LATERAL_OVERLOOKS_BLOCKOUT_V1.md` — Extend the **existing** Awakening First Return Godot scene with two real, traversable, deliberately small Gate-of-Dust side overlooks: a west retaining terra...
- `AWAKENING_MAPPER_PROPOSAL_WORKFLOW_V1.md` — Make Awakening's actual-collider inspection and collision-proposal editing a direct, selectable workflow.
- `CARROW_MAPPER_AUTHORING_WORKSPACE_V1.md` — Make Carrow's six-mode three-room authoring workspace discoverable, efficient and usable at narrower viewport sizes.
- `CARROW_YARD_MARBLE_PERIMETER_SOURCE_INTAKE_V1.md` — Stage and verify the selected real ruined-marble Carrow source slices and provide six reproducible native-scale Godot assembly examples for human seam, camer...
- `CODEX_ART_IMPORT_ASSET_V2_HANDOFF.md` — Finish the reusable source_work→normalized inbox→Asset V2 plan/status/doctor interface with verified artifacts and provenance while preserving the Operator-s...
- `CODEX_ART_IMPORT_MCP_CONTROL.md` — Give Codex a discoverable, low-token, safe MCP interface to inspect, normalize, register, preview and QA source sheets using the single shared import service.
- `CODEX_ART_IMPORT_QUALITY_GATES.md` — Make production-readiness observable and fail-closed with structural/pixel evidence, preview artifacts and stable quality reports before any handoff.
- `CODEX_ART_IMPORT_SEMANTIC_REGISTRATION.md` — Normalize visual scale, centering, foot/root baselines and shared registration without erasing intended frame motion or anchoring equipment to the body incor...
- `COMBAT_ATTACK_TELL_CONTACT_ALIGNMENT_V1.md` — Every live attack-capable actor presents a readable attack cue whose committed contact/damage phase agrees with gameplay timing; legal parries can actually i...
- `COMPOUND_ARCHETYPE_PLAYABLE_PROOF.md` — Prove enter/circulate/operate/exit/revisit without blockers for both Type A and Type B.
- `COMPOUND_INTERIOR_TRAVERSAL_INTEGRATION.md` — Integrate the two reviewed archetypes with real persistent-world entry/return and environment behavior, reusing Type B vertical transfer from its accepted co...
- `COMPOUND_RECOVERY_ASSAULT_OBJECTIVES.md` — Direct intermittent enemy assaults through real reachable routes to actual compound infrastructure.
- `COMPOUND_RECOVERY_BUILD_RESTORATION.md` — Place and commission an existing Capacitor Bank as additional infrastructure through valid sites in either compound.
- `COMPOUND_RECOVERY_DAMAGE_COUPLING.md` — Apply physical assault damage to power, defense and fabrication systems with actual service degradation.
- `COMPOUND_RECOVERY_END_TO_END_PROOF.md` — Verify full defend, damage, resource-choice, repair/build and restoration cycle in both archetypes.
- `COMPOUND_RECOVERY_FIELD_REPAIR.md` — Repair infrastructure by locally holding the existing Operator repair control and paying finite resources.
- `COMPOUND_SECURE_ACCESS_FIXTURES.md` — Introduce one shared functional secure threshold/access-panel fixture for both archetypes.
- `CUSTODIAN_POST_RECOVERY_REINTEGRATION.md` — Make ordinary campaign-ending Custodian death complete through Post recovery and reintegration instead of the R1 compatibility Game Over, while reusing the r...
- `DOWNLOADS_ASSET_RECONCILIATION_V1.md` — Audit the user's entire real Downloads directory against Dropbox source lanes and live CUSTODIAN runtime, classifying every byte before any removal or move.
- `DOWNLOADS_VERIFIED_CLEANOUT_V1.md` — Execute the reviewed Downloads tidy-up, retain Kenney isometric source under dev/, preserve missing unique project inputs in Dropbox and remove verified clut...
- `ENEMY_HEALTH_BARS_AND_PURSUIT_FRAME_PRESENTATION_V1.md` — One wounded enemy must never recolor other actors' health/power bars; Pursuit Frame must present the correct attack facing and all existing, playable state/r...
- `HUB_CAMPAIGN_RETURN.md` — Close the first CampaignRegion → persistent Hub return: apply one valid CampaignOutcome to persistent Hub state exactly once, release the disposable Campaign...
- `HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md` — Close the first real Campaign loop as one reviewed integration: boot → full Awakening → persistent Hub → Forum Contract → optional Twin roundtrip → Muster/Po...
- `HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT.md` — Make Muster Court → ordinary Continuity Port the real campaign departure path, consuming the accepted/prewarmed first Contract without duplicate generation a...
- `HUB_SEPULCHER_GRAVE_RESOLUTION_V1.md` — Sepulcher grave attestation + pale growth; deliver one playable, bounded event slice.
- `MAPPER_VALIDATION_FEEDBACK_V1.md` — Close validation/save feedback loop with actionable issues and honest statuses across the mapper family.
- `NPA_SHOWCASE_BROKEN_WARRANT_ACTOR.md` — Create one distinctive Broken Warrant hostile archetype with real melee/reactions/death/corpse/loot and no duplicate Enemy mechanics.
- `NPA_SHOWCASE_ESCORT_FRAME_M7_ACTOR.md` — Create one real M-7 escort unit as a distinct actor skin/profile over reviewed CombatDrone/AlliedInfantryDroid, with manager-owned command identity.
- `NPA_SHOWCASE_EXISTING_VAULTWING_PROOF.md` — Make the existing Common Vaultwing a reliable wildlife/relationship demonstration without adding companion commands prematurely.
- `OPERATOR_3D_ANIMATION_BATCH_EXECUTOR_V1.md` — Provide a real in-game visual checkpoint for the experimental 3D Neutral Idle candidate, followed after human judgment by a deterministic, resumable candidat...
- `OPERATOR_3D_IDLE_RETARGET_REFINEMENT_V1.md` — Refine the landed Mixamo-to-Operator idle retarget so both clips retain their improved arms and knee flex while their stance width, grounding, contact, and c...
- `OPERATOR_3D_VISUAL_FIDELITY_CANDIDATE_V2.md` — Produce one bounded, source-versioned Operator 3D visual-fidelity candidate that better matches the accepted 128px full-body artwork in neutral stance, propo...
- `OPERATOR_ELEVATION_TRAVERSAL_ENFORCEMENT_V1.md` — Make existing ElevationMap/ProcGen edge truth physically constrain Operator local motion without creating a second movement or collision authority.
- `OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md` — Extract interaction target/build/repair/terminal field-work coordination into one focused authority and give interactables an opt-in semantic Operator succes...
- `OPERATOR_MELEE_DOMAIN_EXTRACTION.md` — Extract melee timeline/drive/target/contact state into one focused authority and cash in the existing modular art where it genuinely improves moving combat p...
- `OPERATOR_MOTION_FOUNDRY_SOURCE_BRIDGE_V1.md` — Safely export an exact current Operator 2.5D motion candidate as untrusted source-work for existing Source Session and Workbench, without inventing a second...
- `OPERATOR_PARRY_RIPOSTE_COMPLETION.md` — Finish the one genuinely missing gameplay tail from the legacy Hit Taxonomy/Riposte effort: a dedicated semantic riposte after a successful parry w…19877 tokens truncated…ION.md`](archived/OBSERVATORY_WORLD_TELEMETRY_FOUNDATION.md) — OBSERVATORY WORLD TELEMETRY FOUNDATION: - Added authority docs for the five-system foundation and selected active design-tree locations that match current repo conventions instead of reviving the retired `design/20_fe...
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
directly in the slash picker. It does not change dispatcher eligibility. An
unqualified invocation completes at most one implementation plus its required
paired review, then stops. Explicit
continuous-chain requests require a finite pair budget and follow only eligible
named handoffs. It resumes a verified active workstream and respects
refresh/manual/dependency gates; global `claim-next` is used only for an explicit
general-next request. See `custodian/tools/agent/next_execution_boundary.py`.

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
`ChatGPT/user planning refresh required: no` may be followed autonomously only
when the invocation explicitly requested a bounded continuous chain and has
remaining pair budget. An unqualified invocation stops after one implementation
and its required review. Paired reviews still require a fresh reviewer context,
but that context switch does not require the user to carry the prior summary.

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

Choose review by risk, reversibility, verification quality, and blast radius, not file count or the label `runtime`. Express work may skip a packet and paired review for a narrow, reversible low-risk single-session change while retaining focused checks and Git safety. Standard is the ordinary bounded-engineering path: use a compact packet when durable scope or acceptance helps, and default to `Review: none` when focused checks directly prove correctness and scope; record a concise concrete risk rationale without special exemption ceremony. Protected work keeps `Review: auto` and fresh independent acceptance for consequential persistence/save-load, concurrency, irreversible operations, authority cutovers, dispatch/review/validation enforcement, dangerous asset-pipeline writes, or material evidence uncertainty. Human-owned visual/canon decisions remain human-owned. Do not use `Review: none` for convenience or queue avoidance, and do not change existing published review decisions retroactively.

Paired review requires a **fresh reviewer context**. A different agent/context is preferred when available, but a different model family is not mandatory. The same model/agent family may review prior work only from a newly started context/workstream with no transient implementation reasoning carried forward, reconstructing the target from the archived packet, closing summary, live code, design authority, tests, and fresh traces/mutations. Record `Reviewer context: fresh` and `Reviewer provenance: different-agent | same-agent-fresh-context` in the durable review artifacts. Continuing the implementation conversation/session is self-review and does not satisfy the paired-review contract.

Legacy packets are not bulk-retrofitted. When new work materially depends on an older unreviewed/legacy seam, re-check the surviving live authority and focused behavior during authoring; use paired review for the new slice when that seam is high-risk, unclear, or central to acceptance.

## Paired Review And Correction

Post-land review intent is decided when the implementation packet is created. For newly authored or materially refreshed V2 engineering packets, use the three-path policy above: Standard work defaults to `Review: none` when focused evidence is sufficient, while Protected work uses `Review: auto`; Express work may omit a packet and paired review. It uses ordinary dispatcher primitives
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

- `REVIEW_LOOT_TOAST_HUD_CLEARANCE_V1.md` — Independently verify that the production loot-toast queue clears the actual visible top-left HUD across normal/debug/terminal/viewport states without changing pickup semantics or creating a generic layout engine.
