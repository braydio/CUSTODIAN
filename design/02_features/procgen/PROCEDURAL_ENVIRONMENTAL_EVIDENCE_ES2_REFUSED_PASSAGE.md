# ES-2 · Refused Passage Physical Tableau — Source-Grounded Pilot Contract

**Status:** First physical implementation specification; owner approved proceeding with ES-2 packet authoring on 2026-10-28. Layout is a *provisional technical blockout*, not an approved finished art composition. No Asset V2 source masters are authorized here.
**Parent program:** `procgen-environmental-evidence-v1`; this independently ownable slice is `procgen-environmental-evidence-refused-passage-v1`.
**Source baseline:** `main@eb4de63498ef13eacc86022613bfa35f825d8b7f` (2026-10-28).
**Authoring chat:** https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain
**Parents:** [Three Grammars](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md), [ES-1 Integration/Interaction](PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md), [Roadmap](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md).
**Execution packet:** `custodian/docs/ai_context/task_packets/PROCGEN_ENVIRONMENTAL_EVIDENCE_REFUSED_PASSAGE_V1.md`.

## 1. Desired experience and fixed bounds

The Operator discovers the abandoned trace of an emergency administration checkpoint. A queue was organized, supplies were counted, belongings were deposited, and a physically intact gate was deliberately closed. Evidence supports more than one reason: necessity, cruel rationing, and bureaucratic error remain possible. The scene must communicate **past function → rupture → afterlife → uncertainty** without requiring a text interaction or implying the Ash-Bell West Gate canon event. No NPC, quest, reward, combat encounter, permanent history write or new geographic Location.

Build **one optional physical instance per eligible accepted F02 region**, selected from ES-1's existing joined `story_room_sites` only. A 0-site result is valid when geometry, approach or protection fails. The pilot must actually appear in at least one deterministic positive-control fixture; a consistently empty implementation fails.

Separate *what the ruined gate visually says* from *what it physically does*: the gate is impassable at its own barrier cells; an existing walkable route must remain accessible, using an open bypass in the tableau. Do not cut through the gate to satisfy navigation. Do not paint a new road, change the already-accepted path graph, or place false road-signaling props unless a real playable service/approach surface can support them. An existing `STORY_APPROACH` intent edge proves only a story-site approach, **not** a real road.

## 2. Source-grounded integration

At ES-1, `story/story_room_placer.gd::project_story_rooms` accepts existing `worldgen_reserved_regions[kind=story_room]` only when bound to its exact F02 intent node, source rect, center and `STORY_APPROACH`. Joined records have `site_id` (`es1:` SHA-256), `site_id_version=es1-story-site-v1`, `intent_node_id`, `scope_kind=f02_generated_region`, `scope_id`, `identity_seed`, `cell`, `rect` and `reserved_rect`. No verified F15 parent is supplied. ES-1 deliberately rejects clipped rectangles and exports optional skips.

`story/story_room_geometry_stamper.gd` asserts site-to-reservation identity but independently stamps all story-room reservation floor. It is **not** ES-2's prop author. `proc_gen_tilemap.gd::_place_story_rooms` currently mounts a `StoryRoom_<site_id>` placeholder marker. ES-2 replaces that marker **for the one accepted pilot site**, using one presentation root keyed to the ES-1 `site_id`; other story sites retain their existing behavior. Existing road/floor/terrain/collision/navigation, M5/M6 chunk residency and Archive Resolve are authoritative.

Use two narrowly scoped modules (names may vary if existing code offers a better equivalent):
- `custodian/game/world/procgen/story/refused_passage_plan.gd` (`RefCounted`): deterministic, pure planner consuming a detached ES-1 site, the live accepted floor/road/protection evidence, and a versioned grammar. Returns a detached plan or stable skip reason; **no** scene tree, tile painting, global RNG or independent story-site selection.
- `custodian/game/world/procgen/story/refused_passage_site_2d.gd` (`Node2D`) or paired `.tscn`: consumes the plan, creates visible local props + two `WorldReadoutInteractable` children, and manages idempotent spawn/teardown against real worldgen/chunk lifecycle. It does **not** own accepted world truth, geometry reservation, navigation or save state.

Keep the `proc_gen_tilemap.gd` adapter bounded to preparation/selection, authoritative tile/world conversion, existing blocker registration and ownership-safe presentation lifecycle. Do not add a second story-site collection, duplicate ES-1 IDs, or move generated floor/wall/road dictionaries to a story module. If a small blocker adapter must be exposed, delegate existing `_register_runtime_prop_blocker_cells` / unregister behavior with provenance and generation-scoped IDs. Do not use transient instance IDs as durable blocker identity.

## 3. Exact native blockout and orientation

Native procgen cell = **32×32 px**; prototype logical canvas = **16×12 cells = 512×384 px** (all coordinates below are local tile indices `x=0..15, y=0..11`, not Godot world pixels). A nominal unclipped F02 story reservation at radius 8 is **17×17 tiles**. Fit only inside the **actual** validated reservation rectangle; choose a deterministic integer-tile origin and ensure every rotated footprint and approach lies on the accepted playable floor. No scaling existing assets to fill this envelope.

```text
                x0                                x15
 y0   . . . . . . . . . . . . . . . .
 y1   . P . Q Q . . . . . . S S S . .
 y2   . . . Q Q . . C C . . S S S . .
 y3   . . . Q Q . . C C . . . . . . .
 y4   . . . Q Q . . G G . . . . . . .
 y5   . . A Q Q . . G G . . . . . . .
 y6   . . A . . . . G G . . . . . . .
 y7   . . . I . . . . . . . D . . . .
 y8   . . . . . . . . . . . . . . . .
 y9   = = = = = = = = = = = = = = = =
y10   = = = = = = = = = = = = = = = =   3-cell clear lane
y11   = = = = = = = = = = = = = = = =
```

Legend: `P` authority post/sign, `Q` old queue rails/markings, `A` two abandonment traces, `C` checkpoint frame/spine, `G` visibly closed gate, `S` orderly stores, `I` identity-tray evidence point, `D` duty-ledger evidence point, `=` **zero blockers or decorative placement**. The depicted marks are semantic footprints, *not* mandatory one-object-per-cell placement. Preserve evidence objects as individual distinguishable silhouettes.

Anchor the canonical unrotated layout within the ES-1 rectangle. Orient toward the actual approach using a deterministic cardinal transform only when material legibility and all geometric assertions pass. For a 90° transform the logical footprint is 12×16; rotate **coordinates/placement**, not arbitrary text or unsuitable preexisting sprites. For no proven orientation, skip rather than invent a passable road or render reversed labels. Use the same transformed plan for props, clear lane, interaction anchors and collision cells. Record `orientation_id` in the versioned plan.

**Gate blocker and bypass:** The 2×3 `G` region (x7–8/y4–6) is blocked only if the actual CollisionShape2D, runtime blocker registry and navigation all agree; other solids are optional and cannot invade the 3-cell clear lane. `C` is visual architecture, not automatically physical collision. Connect the bypass to *existing* accepted playable component(s); connectivity checks must include approach and both inspect positions, not merely check that the local 3×16 stripe is floor. A former through-route implied by markings may be historical; present-day traversal must remain valid. Respect vehicle-route clearance separately whenever an existing required vehicle path is nearby.

**Readouts:** `identity_tray` at (3,7), `duty_ledger` at (12,7), each visually attached to its corresponding clue prop; interaction anchors may be shifted by <=1 tile if measurable LOS/approach proof demands it and the plan records the adjustment. Their 9-cell separation avoids the nearest-only Selector's overlapping 72px radius. From the 3-cell bypass, y9 is 2 tiles (64px) from each anchor, but real collision and view tests still decide. The Operator maximum interaction range is 84px; the shared `WorldReadoutInteractable` defaults to 72px and `single_use=false`. No independent prompt priority or new HUD.

**No prop inside the clear stripe.** External road/mission/ingress/vehicle-protected cells also remain clear; if a variant collides with them, try bounded alternate eligible ES-1 site or orientation, otherwise log deterministic skip and leave the accepted world untouched.

## 4. Causal variants (one coherent roll)

Use exactly one `variant_id` per site, from a stable hash of ES-1 `site_id`, `refused_passage` and `grammar_version=1`. Sort candidates by stable site ID before choosing at most one eligible; do not advance the global RNG. Variant selection changes the evidence composition and text, **not** gate collision or safe lane.

| `variant_id` | Original function + rupture | Afterlife + contradiction | Repeatable evidence readouts |
| --- | --- | --- | --- |
| `emergency_quarantine` | Evacuation triage, containment order, gate actuator left functional | Stacked uncontaminated supplies; extra identity slot worn after apparent closure | Duty ledger: `TRANSFER HOLD. SOURCE UNVERIFIED. Actuator: nominal.` / Tray: `Nineteen stamped tags. Twenty grooves worn into the tray.` |
| `controlled_drawdown` | Organized withdrawal, closure after a counted inventory | Sealed stores remain although the register says consumed | Ledger: `All stores issued before shutter lock.` / Tray: `Departure tags sorted. The last two have no departure mark.` |
| `disputed_diversion` | Route redirection, overwritten public order | Queue lines point toward the sealed gate; alternate notice lacks a signing authority | Ledger: `Route B authorized. Closure command unchanged.` / Tray: `Escort tags marked RETURN. No return was logged.` |

Each variant must still have the four causal layers: 1 authority object, >=2 visually distinct human absence traces, orderly stores, 1 contradictory record. Text remains a clue, not a definitive canonical explanation. Do not use modern company logos or polities from the retired prototype `iconoclast/cult_mechanist/scavenger` IDs. The Interdiction Mesh is not a polity. No F15 source, historical actor, quarantine pathogen or WorldEventMemory fact is asserted.

## 5. Deterministic plan contract

New plan descriptor (proposal; private helper names are not authority):

```text
custodian.environment_evidence.refused_passage.v1 {
  schema_version: 1,
  grammar_id: "refused_passage", grammar_version: 1,
  parent_site_id, intent_node_id, exact_reserved_rect,
  generation_scope, effective_seed, orientation_id,
  footprint_rect, variant_id, plan_fingerprint,
  required_clear_lane: [Vector2i], approach_cells: [Vector2i],
  props: [{slot_id, semantic_role, local_cell, world_cell,
            visual_kind, blocking_cells, facing}],
  readouts: [{clue_id, world_cell, title, readout, single_use:false}],
  blocked_cells: [Vector2i], skip_reason?
}
```

Never serialize a Godot NodePath, instance ID or raw `Node` into the accepted-world record. Use SHA-256 over a canonical ordered, typed/length-prefixed payload for `plan_fingerprint`. Store the plan as detached data on the existing site/accepted-world export seam only where it is a supported consumer; avoid a new mutation owner or duplicate array. If no suitable generation/export lifecycle exists, produce a deterministic read-only derivation from the accepted ES-1 records and pin the full rebuild inputs in validation. The optional site must not be materialized before authoritative floor/route/protected-cell conditions are final, and must not be counted as committed if later placement protections fail.

**Idempotence:** repeated generation/scene attach/detach/chunk reveal must show one site root per `site_id` and exactly two live interactable descendants, not multiples. Teardown releases any dedicated runtime blocker IDs and collision bodies. A rejected optional site creates no props, blockers or interactions and does not mutate a generated region's accepted topology or seed. `WorldReadoutInteractable.is_acknowledged` remains per-node ephemeral: reentry may reset its first-read text; don't fabricate cross-visit persistence.

## 6. Runtime presentation, evidence and art gate

ES-2 must produce distinguishable visible physical cues in the real Godot game, not just a metadata-only marker and two floating interactions. Reuse approved **already ingested** in-game props where roles actually match their semantics. A focused greybox/primitive silhouette fallback is permitted for the ES-2 technical pilot only, with visibly distinct post/rail/gate/stores/pack/tray/ledger roles and no misleading production art approval. If no proper asset/primitive can represent a mandatory causal layer, report the appearance as **blockout**, not production-ready. Do not use an unrelated Gothic spiked barricade as a settled Alpine civil-control design by default.

ES-2 does **not** ingest new PNGs or register new Asset V2 families. When ES-4 starts, planned `world_prop` family `campaign_story_refused_passage` has nine provisional states: `cordon_post`, `closure_barrier`, `queue_rail`, `passage_sign`, `supply_stack`, `abandoned_pack`, `identity_tray`, `duty_ledger`, `ground_scuff`, all 1 frame at **192×192 RGBA**, and optional `signal_beacon` at **4 frames × 192×192 = 768×192**, 8 FPS looping. Layout/orientation are not asset-facing locks. Planned source and normalized inbox paths for each state:
- `custodian/asset_drop/source_work/campaign/campaign_story_refused_passage/<state_id>_source.png`
- `custodian/asset_drop/inbox/campaign_story_refused_passage/<state_id>.png`
- `custodian/content/metadata/assets/families/campaign_story_refused_passage.asset.json`

No source artwork exists or is authorized for ingestion by this packet; final schema/registration must be checked at ES-4 intake. Project's Asset V2 approval process governs source review, dimensions, alpha, alignment, collision/occlusion ownership and production consumer bindings.

## 7. Acceptance and falsification

1. **Positive and negative fixture:** fixed ES-1 accepted region with a real suitable candidate creates exactly one Refused Passage site; invalid/clipped/protected/unwalkable/unknown approach regions create zero and a stable reason, not a failed world.
2. **Causal visual structure:** visible authority post/gate, queue, >=2 distinct human abandonment clues, stores and contradictory document; the real gate is impassable, bypass is traversable, and none of the two inspect points are hidden behind a blocker. Check explicit semantic-role inventory as well as tight cropped visual proof.
3. **Geometry:** 16×12 logical/512×384 pixel unscaled blockout (or cardinal-transformed 12×16), wholly within exact ES-1 reserved rectangle; at least three **actual** walkable cells of transverse safe passage along the transformed lane, with real connectivity from existing playable approach and without reducing any required road/ingress/mission/extraction/vehicle route.
4. **Determinism and no rebloat:** same seed/site/grammar and reordered input yield identical site choice, layout, variant, transform, readout identities and plan fingerprint; different supported seeds can vary variants while preserving safety. No competing metadata anchor, new F15 topology, fake durable save, new global RNG dependency or substantial `proc_gen_tilemap.gd` growth.
5. **Real interaction:** two and only two visible, distinct, approachable `WorldReadoutInteractable` nodes; 72px effective readout range, correct 84px Operator bound, repeatable reads without quest/event/write side effects; no gate prompt precedence conflict or behind-wall interaction.
6. **Lifecycle:** after regenerate/scene reload/stream unload/reload/Archive Resolve, identical accepted site has no duplicate props, prompts or blockers and no permanently orphaned collision; rejected site never leaves residue.
7. **Regressions:** ES-1 story/intent/world-shape/accepted-export, road semantics/terrain requirements, candidate parity, runtime blockers/route, chunk residency, readout/Operator/HUD integration, changed-file manifest, pairing/AI-context and diff checks pass. Falsify one deliberate blocked-lane, replaced-rect, missing-intent, duplicate-spawn, unreachable-readout and conflicting gate-prompt case.
8. **Visual review:** technical blockout is mechanically machine-verified first. If final subjective composition/legibility matters, deliver one small ROI contact sheet and a single exact Dropbox review manifest at `/CUSTODIAN/visual_review/procgen-environmental-evidence-refused-passage-v1/<run-id>/REVIEW_MANIFEST.json`; request human answer to `Can the player infer deliberately denied passage and conflicting evidence without reading the HUD?` The absence of polished Asset V2 art is a named ES-4 future limitation, not a reason to fake ES-2 completion.

## 8. Continuation and truth

ES-1 implementation is landed and mechanically validated; its earlier paired independent review was stopped before reviewer launch on a five-document archive scope mismatch. This is **not** an ES-1 runtime failure, and is not a passing independent review either. Do not overwrite or close the preserved claim through the ES-2 workstream. The live dispatcher and repository rules decide whether ES-2 is claimable; merely publishing this specification cannot waive the review/claim gate.

After ES-2 independent technical acceptance, extend the **same planner/presenter contract** to Borrowed Hearth and False Seam (ES-3), not two new assemblers. ES-4 commissions and ingests the three Asset V2 families and performs multi-seed campaign visual acceptance. No external prerequisites, art masters, schemas, scripts or fixtures are delivered only as chat files.
