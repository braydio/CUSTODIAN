# ES-1 · Environmental Evidence, Existing Interaction and Geographic Ownership

**Status:** **Option B ES-1 foundation implemented and validated (2026-10-28); fresh-context paired review pending post-land**. Full physical tableaux, new art, ES-2–ES-4, and permanent cross-visit geography remain separately scoped.
**Workstream:** procgen-environmental-evidence-v1
**Date:** 2026-10-27
**Source audit:** main@ce2772f7ccf450d179b73da1dcdda051e0dcb2e2
**Authoring chat:** https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain
**Parent design:** [Three Evidence Grammars](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md).
**Roadmap:** [Integration Roadmap](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md).
**Boundary:** F15-B1/B2 geography and F02 accepted-world geometry, original actor interaction, Asset V2 and canon remain single-owner authorities.

## 1. Pre-ES-1 audited state (2026-10-27): what already existed

### Geographic identity and semantics

- `game/world/geography/campaign_geography_registry.gd` (F15-B1) validates finite Domain/Location IDs, canonical edges, locality seeds and injective `location_address_key(domain_id,location_id)`; logical edges are not physical crossings.
- `game/world/geography/campaign_geography_semantic_registry.gd` (F15-B2) stores read-only, versioned, LevelRegistry-resolved site metadata keyed to a **B1 Location**: `source`, `effective_source`, `site_purpose`, `semantic_tags`, `mysteries`, `ruin_reserves`, landmarks and planned edge bindings. It does not construct a scene, identify every individual ruin on the floor or implement persistence.
- Semantic `mysteries` distinguish `authored_canon` (requires typed F02 level-tag fact) and `unknown_origin`; neither is a free pass to generate physical anomalies. `ruin_reserves` are typed site/failure references, **not** a completed ruin/story generator.

### Physical procgen truth

- `game/world/procgen/intent/ascent_spine_builder.gd` generates `WorldgenIntentNode.STORY_ROOM` branch nodes connected by `STORY_APPROACH` edges; it guarantees a fallback story branch in eligible ascent graphs, initially radius 8 tiles. It does not pick a finished narrative evidence style.
- `intent/region_footprint_reserver.gd` exports `worldgen_reserved_regions[]` with stable graph `id`, `kind`, actual clipped `rect`, `center`, `band_id`, `style_id`, `faction_id`, `story_id`, and `required`. It floors reserved graph-node space and route paths. The actual rectangle (not a nominal template radius) is the candidate envelope.
- `story/story_room_geometry_stamper.gd` iterates **only** `worldgen_reserved_regions[kind=story_room]`, invoking the existing tilemap floor-claim method; its `_story_rooms` argument is unused. It stamps floor, not story props or inspect points.
- `story/story_room_placer.gd` **independently** samples generated floor cells by progress chance, >128 distance, legacy nearest faction ID and 20-cell anchor separation. It emits `story_room_sites[]` marked `metadata_only_v1`, with no intent-node ID or reserved-rectangle reference; `ProcGenTilemap._place_story_rooms` currently mounts a placeholder marker at those independent anchors. The stamped rectangles and metadata markers are **not consistently bound together**.
- `proc_gen_tilemap.gd::_fill_tilemaps()` constructs base world/intent and applies terrain/road; later it invokes faction site placement, story metadata placement, floor stamping and further route repairs. Both `worldgen_reserved_regions` and `story_room_sites` pass through `generation/accepted_world_export.gd` as separate detached level-data fields. Ruin/foliage protection currently refers to the independently selected metadata centers, not the entire reserved story geometry.
- `game/world/procgen/authored_claims/README.md` still calls itself a scaffold. The queued `PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md` (D2, ready/auto at audit) explicitly **excludes worldgen-intent reservations** from the new authored-floor/overlook/ingress registry. Do not merge story reservations into D2 or mutate its claimed scope; recheck live main and dispatch status when implementation is authorized.

### Operator and player-facing evidence

- `game/actors/operator/operator.gd` already scans group `interactable` during its simulation update and invokes `can_interact(actor)`, `get_interaction_position()`, `get_interaction_distance()`, `get_interaction_prompt()`, then `interact(actor)` on the interact action. Global Operator maximum range is **84px** (native procgen scale: 32px per cell); nearest eligible Node2D wins by distance. **There is no line-of-sight or authored-priority test in this selector**; competing adjacent prompts and an object behind a wall are real risks. No Operator edit is proposed.
- `game/world/interactions/world_readout_interactable.gd` is generic, already reusable, registers itself with the group, defaults to **72px** interaction range, supports `single_use=false`, and emits short readout text through the existing `/root/GameRoot/CustodianHUD` latched interaction (4s). Its `is_acknowledged` is transient **per node**; it is not a durable clue discovery ledger.
- `game/world/levels/authored/ash_bell/common/world_evidence_interactable_2d.gd` is an authored Area2D evidence object with one-shot recovery signal and custom root-level full-screen overlay. Its recovery state and UI should **not** be reused wholesale for repeatable ambient lore.
- `game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd` supplies three ordered interaction points and a HubState authored-event record, demonstrating explicit authoritative event progression; that hub-specific save mechanism should not be copied into a procgen environment site.

## 2. Options and recommended choice

| Option | Geography | Interaction | Strength | Why not the V1 default |
| --- | --- | --- | --- | --- |
| **A: Each tableau is an F15 Location** | Register separate geographic nodes and links per micro-site | Author individual events | Persistent topological identity | Unnecessary permanent topology/edge cardinality, violates B2 data-only seam, requires F15 migration. Reject for ambient tableaux. |
| **B: Child evidence site on existing F02 reserved story node** **PREFERRED** | Existing B1/B2 Location is the parent when bound; intent-node ID and actual reserved rect identify the *local* site | Two generic WorldReadoutInteractable points plus physical props | Reuses already-carved approach, stable per-cell site identity, no new graph, natural optional skip | Requires explicit join/migration to remove competing independent metadata anchor placement and focused reachability tests. |
| **C: Metadata-anchor/post-accept prop scattering** | Reuse independent StoryRoomPlacer cell, no authored reservation | Readout close to marker | Quick prototype | Center-only clearance, misleading checkpoint/door geometry, story and floor stamp drift; unsuitable for structural styles. Fallback only for pure visual hints with no footprint. |

**Approved ES-1 decision (2026-10-28):** adopt B for the first narrow implementation, retaining its limits. A tableau is a **region-local child** of the active F02 generated region. If an existing B1/B2 Domain/Location context is available, use its established address/seed as the scope; **do not** register a new F15 Location or create a second semantic registry for each tableau. If no F15 context exists in current contract-world generation, generate/replay a region-local site without claiming cross-visit Domain persistence.

## 3. Recommended site record (proposed V1 payload, not current API)

A *detached deterministic composition descriptor* should be produced by one existing F02/story owner for each accepted site, without state mutation. Candidate fields:

```text
EnvironmentalEvidenceSiteV1 {
  schema: "custodian.environment_evidence_site.v1",
  grammar_id: "refused_passage" | "borrowed_hearth" | "false_seam",
  grammar_version: "v1",
  f02_level_source_ref,      # existing generated-region source, no new Level ID
  parent_geography_address?, # B1/B2 scope only if explicitly resolved
  generation_seed,           # existing effective accepted F02 seed
  intent_node_id,            # exact existing graph node.id
  reserved_rect,             # copied and validated from the exact node claim
  site_fingerprint,          # SHA256 canonical typed/length-prefixed identity+plan
  original_function, rupture, afterlife, evidence_confidence,
  variant_id,               # coherent, deterministic profile selection
  placed_prop_slots: [{slot_id, state_id, cell, offset_px, facing, blocking}],
  readouts: [{clue_id, cell, offset_px, title, text_key}],
  blocked_cells, clear_cells, protected_through_lane,
  optional_provenance_ref?   # only when typed canonical source supports it
}
```

**Site identity:** namespace **existing parent generated-region identity + actual intent node ID + planner/grammar generation version** with byte-length-prefixed or equivalently collision-safe encoding before SHA256. Do not use just `story_id`, bare `cell`, `Node.get_instance_id()`, display names or runtime object path. A content-grammar change must version its deterministic fingerprint. Replay must not advance global RNG or change previously accepted terrain.

**Data-flow sketch:**

```text
F15 B1/B2 Domain + Location    F02 accepted generated-region source
          \                        /
           optional verified scope
                    |
      Existing F02 story intent graph
       + reserved story_room rectangle
                    |
       pure bounded evidence-site plan
   (causal profile + safe footprint + clues)
                    |
       existing F02 world acceptance checks
                    |
         accepted plan export/realization
                    |
        world props + HUD readout nodes
                    |
      existing Operator "interactable" group
```

The diagram describes a proposed adapter, **not a currently implemented call graph**. F15 does not create the graph. Existing `story_room_sites` and `worldgen_reserved_regions` are separate outputs today; future implementation must replace/converge the legacy metadata projection with **one authoritative site identity**, not append an unrelated third story position. Preserve old consumers during a bounded migration with a clear retire step.

## 4. Exact ES-2 Refused Passage pilot proposal

- **Eligibility:** only one accepted `worldgen_reserved_regions[]` entry with `kind == story_room`, a known graph `id`, and a measured clipped rect large enough for the **16x12-cell** proposed footprint. A radius-8 story node produces a nominal 17x17 rect, but clipping, surrounding route, protected ingress and actual collision may invalidate it. A `STORY_APPROACH` edge is **not automatically** a road or hardstand; the checkpoint layout should require a credible road/service surface from existing semantics or skip. Never force a story by carving extra accepted terrain.
- **Selection:** optional 0/1 pilot site per eligible generated region, deterministic variant from the effective seed + intent node ID + version. No new faction gating in ES-2 until FI-001/FI-002 or a documented compatibility adapter; first scene can use unmarked historic checkpoint administration.
- **Geometry:** a real 3-cell candidate clear traversable lane through/by the closure; inspect positions on reachable floor and on the accepted main playable component. No prop/collision on spawn, ingress/return, mission objective, extraction, main route, authored site, vehicle lane, CHASM or void. Existing reservation/accepted-world/road authorities decide.
- **Visual evidence:** barrier/official post, queue/abandoned belongings, orderly supply stack and one contradictory ledger/sign. Preserve all four causal layers without collecting a document.
- **Interaction:** two WorldReadoutInteractable-compatible **repeatable** sources, e.g. `duty_ledger` and `identity_tray`. Set `single_use=false`; use the existing 72px default and Operator's 84px cap. Proposed readout anchors at least 3 cells apart and at least 5 cells from any mandatory gate/level-exit interaction, subject to actual footprint/camera tests. No objective completion or authored-event signal from reading. Props are visible even if player never presses Interact. No new full-screen overlay or HUD implementation.
- **State:** material layout, clue texts and variants regenerate deterministically from the site plan. No claim of cross-visit persistence until F15 scene-binding and REMAP-3 lifecycle support are validated. Ordinary readout acknowledgment remains temporary; no synthetic permanent discovery record.
- **Physics:** do not add a new physics collision body for a visually nonblocking inspect anchor; collision/blockers are declared only for appropriately materialized solid props and reflected through existing blocker/nav mechanisms. No interaction behind opaque wall.
- **Missing art:** test with clearly labeled existing in-game props/minimal developer primitives only if user authorizes a code pilot; this document creates no fake Asset V2 completion.

## 5. Implementation boundaries if subsequently authorized

**ES-1 authorized implementation packet:** `custodian/docs/ai_context/task_packets/PROCGEN_ENVIRONMENTAL_EVIDENCE_V1.md`, with paired independent review `REVIEW_PROCGEN_ENVIRONMENTAL_EVIDENCE_V1.md`. Its claim/ready state remains governed by the dispatcher. Scope: normalize/refactor existing `story_room_sites` projection so each accepted evidence candidate matches an existing `worldgen_reserved_regions[kind=story_room]` by immutable intent-node ID and contains actual validated rect, or is explicitly rejected. Preserve legacy non-intent mode where needed without duplicating active story claims. Add focused pure deterministic geometry/identity/skip tests. Existing story/intent modules should own this; `proc_gen_tilemap.gd` should remain a thin call/delegation and `accepted_world_export.gd` retains detached authoritative output. Do not couple this to D2 authored-claims extraction.

**ES-2 subsequent code packet candidate:** small composition planner (pure RefCounted, e.g. `game/world/procgen/story/story_evidence_composer.gd`) and scene-local presentation adapter (e.g. `game/world/procgen/story/story_evidence_site_2d.gd`), binding two existing WorldReadoutInteractable instances to a selected validated plan. Prefer reuse of existing interactables, keep asset family IDs data-only until Asset V2 approval, and avoid modifying `operator.gd` or `CustodianHUD`. An independent paired post-land review checks the actual rendered/interactive Operator proof. Both packet and review plus all requisite source/fixtures must publish atomically on main when user authorizes.

**ES-1 implementation result:** `story_room_sites` now projects only from reserved F02 story-room nodes, validates exact source node geometry and a STORY_APPROACH graph edge, emits versioned region-local identities and stable skip reasons, and exports both detached site and skip records. The reserved floor stamper asserts exact node/rectangle binding. The non-intent metadata-only compatibility path remains available. No verified F15 parent is passed, and no new Location, persistent state, physical tableau, interaction, art, Operator or HUD authority was introduced. See the task packet and closing summary for exact source and test evidence.

The preceding caution records the packet-authoring posture before ES-1. The implementation now compiles and runs against the current F02 intent/reservation APIs in the focused story-site, intent-graph, world-shape and changed-file validation suites.

## 6. Focused acceptance and failure cases (planned, not executed)

1. Same parent region/intent ID/seed/grammar version and shuffled candidate input = same normalized site fingerprint, story variant, props, readouts; scene reload/reveal rebuilds without duplicate nodes or prompts.
2. Missing/stale B1/B2 parent when such binding is required rejects that binding atomically. In F02-only generation, do **not** fabricate persistent geography; support a clearly transient scoped identity.
3. Missing intent node, mismatched node ID/rect, clipped 16x12, unsupported service road, CHASM, overlap with authored claims, blocked route or unreachable readout → optional site rejected **without rejecting accepted world**.
4. Never conflate `STORY_APPROACH` with a verified road; never merge existing independently scattered story markers with reserved site claims without explicit identity map.
5. Both readouts visible, selectable and usable by the real Operator without blocking gameplay; test 72px/84px range, competing prompt, behind-wall case and open UI suppression. An event/quest state must remain unchanged by mere ambient reading.
6. No newly active legacy polity or Mesh-as-polity; False Seam anomalies require substantive typed canonical evidence. No invented canon answers.
7. No growth of large actor/TileMap/UI coordination files except narrow delegation. Focused tests precede broad Godot sweeps, and visual proof is one small final camera crop after measurable semantics/collision checks.

## 7. ES-1 sign-off questions and next slice

**Recorded human decision (2026-10-28):** Option B was approved for the small ES-1 foundation. An existing verified F15 B1/B2 Location remains optional; no parent was available in current procgen input, so ES-1 records are explicitly F02-region-local. Repeatable native HUD readouts remain part of the future physical pilot, not this foundation.

**Next development slice: ES-2 Refused Passage physical tableau (after ES-1 review PASS).**

Scope a separate implementation/review packet for one optional physical
Refused Passage site inside the joined F02 reservation. Preserve causal
evidence, a real clear through-route, two reachable repeatable
WorldReadoutInteractable points, and safe skip without changing accepted
terrain/routes. This handoff does not authorize an implementation claim or new
Asset V2 intake. ES-3 Borrowed Hearth/False Seam and ES-4 artwork/campaign proof
remain the intended continuation, not abandoned scope.
