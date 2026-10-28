# Procedural Environmental Storytelling V1: Three Evidence Grammars

**Status:** three designs endorsed 2026-10-27; **ES-1 F02 reserved story-site identity foundation implementation approved 2026-10-28**. ES-2–ES-4 physical tableaux, art and larger campaign rollout remain separately scoped.
**Workstream:** procgen-environmental-evidence-v1
**Source baseline:** main@bb5a1b16
**Authoring chat:** https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain
**Planning companion:** [Integration Roadmap](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md).
**Canon:** [Reciprocal Continuity](../../03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md), [Procedural Lore](../../03_world/PROCEDURAL_LORE_GENERATION.md), [Faction Overview](../../03_world/factions/_FACTION_OVERVIEW.md).

## Design rule

**Proceduralize evidence, not exposition.** Every generated tableau has causally related traces of **past/original function**, **rupture**, **afterlife/reuse**, and **uncertainty**. Select a coherent causal story first, then compatible terrain, architecture, objects, evidence and optional inspect wording. Never roll independent random clutter to imply a history that cannot have happened. The visual scene should communicate former use and consequential change before any lore text is read.

First target: **ALPINE_PLATEAU** region frame, preserving distinct rocky_upland, woodland, scrubland and wetland local biomes, Alpine graphite/ochre/frost/olive palette, and Archive Resolve as reveal only. These are optional small environmental sites, not major missions. No automatic clues to the Severing's cause, Ash-Bell figures, NON-RECIPIENT or provenance-as-physical-coherence fiction.

**Initial reviewable density proposal:** 0–3 sites per eligible local region, replacing/substituting existing story-room slots rather than adding a new mandatory quota; 24 logical-cell center separation when possible; max one False Seam. These are design targets, not tested budgets.

## Style 1: The Refused Passage

**Narrative:** an evacuation checkpoint shows an orderly queue, supplies, abandoned belongings and an intact barrier deliberately ordered shut. Was closure an act of cruelty, rationing or necessary quarantine? Preserve uncertainty. It is *not* the literal authored Ash-Bell West Gate event.

**Visual grammar:** linear bureaucratic approach → queue/waiting traces → powered closure barrier → protected stores and conflicting records. Rigid concrete/steel, oxidized warning red, worn ochre route markings, frost. Require **one authority object, two distinct abandonment traces, one contradiction**.

**Proposed footprint:** **16×12 native 32px cells = 512×384 px**. Conceptual local coordinates: approach x0–5/y2–9; closure spine x6–8/y1–10; service/stores x9–15/y1–10. Preserve a real clear through-route or bypass, initially target minimum **3 cells** clear, subject to actual Operator/vehicle proof. Rotate only a semantic layout where art facing/legibility supports it.

**Variants:** emergency quarantine (source-risk order, powered gate), controlled drawdown (preserved stores, decommission marks), disputed diversion (overwritten route orders, worn waiting lines). Compatible with road fragments, service hardstand or mountain passes. Future polity dressing: **Cordon Service** / **Drawdown Councils**; Mesh only as separately typed hazard. No forced combat.

**Sample inspect wording:** "Queue marks end before the gate."; "Actuator test: nominal."; "TRANSFER HOLD: SOURCE UNVERIFIED."

**Proposed Asset V2 family:** campaign_story_refused_passage. Nine required static states: cordon_post, closure_barrier, queue_rail, passage_sign, supply_stack, abandoned_pack, identity_tray, duty_ledger, ground_scuff. One optional animated state: signal_beacon, four frames at 8 FPS.

## Style 2: The Borrowed Hearth

**Narrative:** the damaged housing of an old climate/service machine has become a painstakingly maintained shelter. Residual warmth, redirected runoff, planted beds, laundry, shared meals and repaired conduits attest to ordinary life after the collapse. The central tension is living well inside unstable infrastructure, not generic post-apocalyptic wreckage.

**Visual grammar:** asymmetric industrial shell → cultivation/water → meal/tools/sleeping place → suspended personal details. Small warm amber accents against cold Alpine palette. Require **one original-machine trace, one repair/maintenance trace, two domestic clues and one uncertain fate/resource cue**.

**Proposed footprint:** **12×12 cells = 384×384 px**. Conceptual local zones: machine/canopy x2–9/y1–5; plants/water x1–4/y6–9; table/tools x7–10/y6–9; hanging textiles x3–9/y5–7; reachable southern entrance, not a false doorway.

**Variants:** occupied (fresh tending), departed (carefully stored tools and covered supplies), failing (patch-on-patch maintenance, diminishing resources). **Occupied** is valid only if current runtime can actually support a suitable actor/ambient posture. Otherwise use the departed or failing variant. Prefer sheltered woodland, rocky upland or old service plant. Future polity dressing: **Fieldworks Compact, Orraic Orders, Witness Assemblies**. Usually peaceful/empty.

**Sample inspect wording:** "New solder on an older coolant manifold."; "One place is set. Two are cleared."; "The drain feeds the plants."

**Proposed Asset V2 family:** campaign_story_borrowed_hearth. Nine required static states: service_shell, patched_canopy, heat_collector, family_bedding, water_trough, plant_rack, repair_board, shared_meal, household_marker. One optional animated state: heat_pulse, four frames at 8 FPS.

## Style 3: The False Seam

**Narrative:** a service ruin contains incompatible construction standards, impossible-looking joints and two conflicting but credible infrastructure records. Material origin, deliberate falsification or actual continuity displacement remain distinct possibilities. No glowing rift, teleport or supernatural answer.

**Visual grammar:** two coherent architectural vocabularies join at a misregistered seam; contradictory wear, threshold and records are separately legible. Require **two physical discrepancies plus one documentary/provenance discrepancy**, all physically discoverable.

**Proposed footprint:** **12×9 cells = 384×288 px**. Conceptual zones: structure A x0–5/y1–7, structure B x6–11/y1–7, seam x5–6. A blocked stair or door must **remain correctly blocked** by real collision/navigation even when architecture appears contradictory. Provide one, preferably two, reachable evidence viewpoints.

**Variants:** imported_structure (only when explicit matching continuity origin exists), topology_overlap (only with real compatible anomaly metadata), overwritten_history (a fully mundane possibility involving changed labels/materials and incompatible records). Rare: proposed maximum one per eligible region. No canonical cause reveal; usually quiet.

**Sample inspect wording:** "The second frame has no matching foundation."; "Both maintenance stamps are genuine."; "SOURCE INTEGRITY: CONTRADICTORY."

**Proposed Asset V2 family:** campaign_story_false_seam. Nine required static states: mismatched_joint, twin_threshold, misregistered_plaque, foreign_panel, stair_stub, double_drain, paired_fasteners, archived_marker, seal_fissure. One optional animated state: intermittent_signal, four frames at 8 FPS, a faulty diagnostic rather than physics.

## Proposed Asset Pipeline V2 contract (not registered)

Propose **3 independent world_prop families** with a provisional 192×192-pixel native RGBA family canvas, true alpha and stable contact registration. Each static state is one 192×192 frame; optional animated strip is **4×1 frames × 192×192 = 768×192**, 8 FPS. Total **27 required static + 3 optional animated states**. Small objects may use transparent padding; large structures must be composed from modular pieces, never stretched. Asymmetric signs and structures need a real facing-state decision; do not assume arbitrary sprite rotation or mirroring.

Proposed paths for every family ID and state ID:

    custodian/asset_drop/source_work/campaign/<family_id>/<state_id>_source.png
    custodian/asset_drop/inbox/<family_id>/<state_id>.png
    custodian/content/metadata/assets/families/<family_id>.asset.json

Proposed runtime domain: sprites/environment/props/procgen. **Exact schema, facing, asset canvas and consumer remain pending live Asset V2 review**. Raw generated source is not runtime; V2 controls canonical runtime names. No PNGs, family contracts, requirements-registry updates or ingestion are authorized by this design record. Do not hand-edit generated REQUIRED_ASSETS.md.

## Current runtime seam, drift and preservation

At main@bb5a1b16: story_room_template.gd and story_room_placer.gd supply deterministic metadata (including metadata_only_v1); story_room_geometry_stamper.gd can claim basic reserved floor rectangles but does not create composed scenes; intent/region_footprint_reserver.gd, roads/procgen_road_authority.gd and accepted_world_export.gd provide supporting reservation/route/export data. AmbientActivityAnchor supports actual actor activity but not fictional habitation by itself. **CampaignGeographySemanticRegistry (F15-B2)** is data-only Domain/Location site binding, not a physical placer/streamer. ProcGenTilemap is a large integration façade: do not grow a second narrative authority into it.

Live faction/story profile data still uses prototype **iconoclast, cult_mechanist and scavenger** strings; these are compatibility state, **not** current canonical polities. FI-001/FI-002 migration or explicit safe adapter is a prerequisite for canonical polity-conditioned tableau dressing. **Legacy Interdiction Mesh is a hazard layer, not an eighth polity**. Existing Empty Convoy and Abandoned Station authored-event placement claims take precedence and must not be duplicated. No new save authority, actor AI, geography, world clock, collision/nav or quest system.

The April REGION_GENERATION_SYSTEM phase table predates October F02 story/reservation work; the WORLD_ASCENT next-geometry note also needs distinction between existing rectangle claiming and absent causal dressing. Update these as documentation drift, not as a claim that all region-generation phases are implemented.

## ES-1 integration review update (2026-10-27)

The [source-grounded interaction and geography review](PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md) recommends composing these grammars **inside a reserved F02 story-room intent node**, optionally scoped to an existing verified F15-B1/B2 parent Location. It identifies a current split between graph-reserved floor rectangles and independently selected `metadata_only_v1` story markers, which must be joined rather than allowing duplicate site positions. It also selects two repeatable `WorldReadoutInteractable`-compatible clue points as a first-pilot interaction contract, reusing the Operator's existing group/nearest-distance selector and HUD. The human decision has since **approved the ES-1 foundation only**; no ES-2 physical site, persistent geography or art is implied.

## Acceptance target and Next Agent Slice (ES-1 foundation approved)

First pilot **Refused Passage**: repeated seed/profile/site ID yields identical causal choice, layout/clue/inspect identity and transforms; different seeds vary coherently; invalid footprint **skips without rejecting a valid world**. All clue points accessible to a real Operator; no blocking required road, spawn, objective, extraction or vehicle route. Streamed reveal/re-entry stable. Quantitative geometry/alpha checks before tightly cropped human camera-read review.

**ES-1 authorized next goal:** implement the single F02 intent-node/actual reserved-rectangle story identity join and deterministic safe-skip/export contract through `custodian/docs/ai_context/task_packets/PROCGEN_ENVIRONMENTAL_EVIDENCE_V1.md` and its paired review. Claim/dispatch authority is unchanged. **ES-2** remains the first physical Refused Passage tableau with two native HUD readouts; **ES-3** adds Hearth/Seam, and **ES-4** the Asset V2 art/campaign proof. ES-1 is deliberately small and is not the end state.
