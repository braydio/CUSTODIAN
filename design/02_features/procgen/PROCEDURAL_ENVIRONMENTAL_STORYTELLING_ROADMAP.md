# Procedural Environmental Storytelling: Refinement and Integration Roadmap

**Status:** DESIGN REFINEMENT / HUMAN INTEGRATION HOLD. Not a claimable task packet.
**Workstream:** procgen-environmental-evidence-v1
**Recorded:** 2026-10-27
**Source baseline:** main@bb5a1b16
**Authoring chat:** https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain
**Primary design:** [Three Evidence Grammars](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md).

## Preserved design choices

The user endorsed continued development of three procedurally composed styles: **Refused Passage** (evacuation and denied transit), **Borrowed Hearth** (domestic reuse and ordinary life), and **False Seam** (conflicting physical history). The source design specifies narrative layers, causal variants, proposed logical layout coordinates, inspect lines, art state IDs and the semantic constraints.

**Candidate numbers for validation, not final locks:** 16×12 / 12×12 / 12×9 native 32px cells; 0–3 sites per eligible generated local region in lieu of adding another room quota; 24-cell spacing if possible; max one False Seam; three unregistered 192×192-pixel Asset V2 world_prop families containing 27 required static and 3 optional four-frame 8-FPS animated states. All artwork remains unmade. No implementation action, queue claim, asset request or timeline is authorized by this roadmap.

## ES-1 geography and interaction source review (2026-10-27)

**Design-review record:** [ES-1 Existing Interaction and Geography](PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md). Source-audited at main@ce2772f7; **recommended option B pending human decision**, not implementation authorization.

**Preferred physical identity:** treat a tableau as a *region-local child of an existing F02 intent STORY_ROOM reservation*, deriving its stable identity from the actual intent node ID, accepted generation seed, grammar version, and optional verified F15 B1/B2 parent Location. **Do not** register a new F15 Location per tableau. F15-B2 remains data-only; current F02 contract-world generation may have no F15 binding, which must remain honestly transient.

**Important discovered mismatch:** `StoryRoomGeometryStamper` stamps `worldgen_reserved_regions[kind=story_room]`, while `StoryRoomPlacer` independently emits metadata-only markers from unrelated floor cell candidates. These currently have **no canonical join by intent node ID**. Resolve that mismatch before ES-2; do not simply add three templates to the independent marker pass. The queued D2 authored-claim registry excludes intent reservations, so it is not a shortcut or a permitted expansion.

**Preferred interaction:** the existing Operator `interactable` group, max range 84px, and `WorldReadoutInteractable` 72px, repeatable/short HUD readouts (propose two per pilot). Its nearest-only selector lacks LOS/semantic priority; place readouts away from gates and behind-wall ambiguity. Do not adopt authored `WorldEvidenceInteractable2D`'s separate overlay/recovery ledger or hub-specific authored event persistence for ordinary non-collectible evidence.

**Revised ES-1 implementation dependency:** after user approval, first normalize the authoritative F02 story room/reserved rectangle join and deterministic skip/identity contract. Only then create a physical Refused Passage pilot. Existing layout/art/density numbers remain provisional until real camera/route proof.

## Ownership and dependencies

1. **Canon:** Reciprocal Continuity Doctrine and Procedural Lore Generation. Provenance concerns evidence, not physics; anomalous import claims require explicit eligible world metadata.
2. **Persistent geography:** F15-B1 Domain/Location IDs and F15-B2 CampaignGeographySemanticRegistry bind data references only, not physical rooms or scene transfers.
3. **Physical world:** existing F02 accepted candidate, intent/footprint reserver, story placer/geometry stamper, ProcgenRoadAuthority, terrain, ingress, collision, navigation, streaming and visibility owners.
4. **Faction:** FI-001/FI-002 canonical seven-polity migration or explicit adapter first; older iconoclast/cult_mechanist/scavenger runtime IDs are compatibility only. Mesh is separately typed hazard. A first faction-neutral pilot is permitted.
5. **Interactivity/state:** existing inspect/interactable, F14 actor, run/Domain history, WorldEventMemory and REMAP-3 state owners where actually supported, not second controllers.
6. **Assets:** Asset Pipeline V2, requirement registry and verified runtime consumers. Do not invent final filenames or hand-edit generated REQUIRED_ASSETS.md.
7. **Authored events:** Empty Convoy and Abandoned Station already have their own event/placement packets and must keep exclusive authority.

## Conceptual slices, NOT executable packets

| Slice | Purpose | Acceptance / next gate |
| --- | --- | --- |
| **ES-1 · Integration refinement** | Audit F02 accepted-world stage, story placement/intent reservation, F15-B2 semantic sidecar, interactables, camera and real 32px/facing/clearance. Choose one composition/claim owner. | Human approves precise placement interface, identities, layout adjustments, density/frequency and first pilot scope. No code now. |
| **ES-2 · Refused Passage pilot** | One physical four-layer clue tableau with deterministic optional placement, existing interactions and no mandatory new art. | Same seed exact layout, no blocked route/ingress/extraction, reachable evidence, safe skip, reveal/reentry, visual no-text read, focused independent review. |
| **ES-3 · Hearth and Seam extension** | Two additional causal content definitions through the *same* assembler. Hearth actual actors only when present; Seam documented mundane/true-anomaly distinction. | No duplicate generator, false occupancy, misleading access, retconned canon, or uncontrolled rarity/density. |
| **ES-4 · Art and campaign evaluation** | After visual approval, register/ingest three independent Asset V2 families and conduct multi-seed visual/interactive review. | 27 required static states verified; optional 3 animated states tracked; source/inbox hashes, alpha, native pixel scale, family plan/status/doctor, actual consumer binding, no tracker drift. |

**Order is a dependency concept**, not a preauthorized packet chain. An ES-1 source/audit planning pass comes next. Physical pilot ES-2 and any review pair require explicit approval and publication of every indispensable schema/tool/spec in the same main landing as the packet. Do not auto-author ready/auto workstreams merely because this document now exists.

## Questions for the next operational-integration discussion

- Is a tableau a region-local F02 story-site instance, a reusable child of a durable B1/B2 geographic Location, or an authored-site override? Which exact stable identity and seed version govern repeat visits?
- Where can the current accepted-world claim mechanism reserve an optional rectangle *before* terrain and route validation? Can the story stamper support prop-only realization without modifying accepted geometry?
- Which current inspect/machine surface can read a small keyed clue/evidence record? What exactly persists in-run versus across Domain revisits, without new save or history owners?
- Should the pilot be neutral to polity until FI-001/FI-002, and how do old progression/faction IDs migrate safely?
- Are the three proposed footprints, three-cell passage, 192px component canvas, 24-cell separation and real camera/pixel/occlusion layers appropriate for current Operator, vehicles and Alpine visual language?
- How should protected road corridors, mission objectives, existing authored events, terrain/chasm boundaries, and optional site skip be resolved deterministically?
- What rarity/variety thresholds avoid repetition? How is a quiet noncombat site kept meaningful without implying a nonexistent AI population?
- Which clues can imply contested evidence and which require a physical continuity anomaly? What canon assertions must be forbidden by content validation?
- What is the smallest objective visual acceptance capture after machine-checkable collision, visibility and Asset V2 checks?

## Proposed focused validation after authorization

Use pure seed determinism and negative-control fixture first, then accepted-world connectivity, actual Operator reachability, blocker/vehicle clearance, objective/ingress/route exclusions, semantic world/canon guards, idempotent streaming/restore fingerprints, multi-seed density/variety, Asset V2 contract checks if art is approved, and one small final cropped visual proof. Do not treat a passing metadata/story_room_smoke as proof of a complete physical tableau.

## Documentation drift identified

- April 2026 REGION_GENERATION_SYSTEM.md phase claims are **historical**, not current F02 inventory; existing intent/story room claims/road semantics must be reflected without declaring full scenario generation finished.
- WORLD_ASCENT_STYLE_TRANSITION.md identifies a future reservation/carving slice; live StoryRoomGeometryStamper already claims plain story-room floor rectangles, but does not assemble causal props or player evidence.
- Live ascent/story/faction profile still uses older faction identity labels despite seven-polity canon. Do not introduce new production assets under those labels.
- F15-B2's typed semantic site model is data-only, not a physical world streamer. The newly proposed grammars must not silently promote it.

No runtime code has been changed by this design documentation task; only change CURRENT_STATE.md after implementation/asset evidence actually changes current truth. FILE_INDEX should route newcomers to these design and planning entrypoints.

## Next Agent Slice: integration authoring review ONLY

**Goal:** return with 2–3 source-backed integration options, identify an F02 reservation/realization owner and explicit F15-B2 join, and settle first Refused Passage vertical-slice acceptance.
**Likely files:** custodian/game/world/procgen/story/, intent/, roads/, generation/accepted_world_export.gd; geography/campaign_geography_semantic_registry.gd; current interactable/UI and Asset V2 consumers.
**Constraints:** no runtime edits, executable packet, asset commission, active lock mutation or invented geographic authority.
**Acceptance:** a reviewed owner/phase choice, measured geometry/camera/facing requirements, identity/restore policy, negative controls and narrowed authorized Codex contract once the user decides to implement.
