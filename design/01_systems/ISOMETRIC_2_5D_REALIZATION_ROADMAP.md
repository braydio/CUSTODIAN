
# CUSTODIAN ISOMETRIC 2.5D REALIZATION ROADMAP

**Program ID:** `isometric-2-5d-realization`
**Status:** active / foundation implemented / Operator authority accepted / WB25-4 ready before Forum
**Priority:** P2
**Reviewed main:** `119fa1a19427dce838977422d5186e3624e3457e`
**Last Updated:** 2026-10-09
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
**Design authority:** `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`

## Pivot

The Kenney feasibility exploration has served its purpose. CUSTODIAN is **not continuing toward a live orthographic-3D gameplay presentation test**.

K3D-1 remains useful fixed-view/isometric evidence. K3D-1P remains useful as a real-Operator walkable comparison harness.

The previously planned future workstreams `kenney-orthographic-3d-feasibility` and `kenney-3d-to-2d-production-feasibility` are canceled before authoring/implementation.

The active objective is to make the existing fixed-isometric 2.5D doctrine materially true in the current 2D runtime.

## Existing evidence we are reusing

| Evidence | What it proves |
| --- | --- |
| K3D-1 | fixed-view isometric assets can share CUSTODIAN spatial truth and stay presentation-only |
| K3D-1P | real Operator/gameplay Camera2D walkaround over the same sample |
| Lords skeleton | 16-direction Sprite2D actor can read as volumetric in-game |
| Gothic Compound | base-rooted depth sorting already works in production code |
| RoofOccluder2D | tactical foreground/roof fade already exists |
| BlobShadow | actor ground contact already exists |
| Sundered Keep | underlay/playable/occlusion/foreground banding already exists |

## Replacement slices

The two future implementation slots are now:

| Slice | Workstream | Goal | State |
| --- | --- | --- | --- |
| precursor | `kenney-isometric-blockout-playtest` | finish walkable Kenney/native comparison harness | **complete / landed** |
| 2.5D-1 | `isometric-2-5d-presentation-foundation` | converge ground anchors, visual elevation, depth bands and existing occlusion/shadow precedents | **complete / landed** |
| 2.5D-1R | `review-isometric-2-5d-presentation-foundation` | independently verify reusable 2D-authoritative presentation primitive | **ready / auto behind 2.5D-1** |
| OP-2.5D-A | `operator-2-5d-animation-viability-audit` | close the legacy-art audit against the already-recorded locked 2.5D authority and quantify the remaining backlog | **complete / reviewed truth consumed** |
| OP-2.5D-0 | `operator-2-5d-canonical-visual-contract` | harden exact design-lock + first relaxed-idle family; establish accepted canonical 128 profile/reference and anti-drift tooling | **complete / reviewed** |
| OP-2.5D-0R | `review-operator-2-5d-canonical-visual-contract` | verify exact source/profile/first-family/guide integrity | **complete / passed** |
| 2.5D-2 | `isometric-2-5d-forum-vertical-slice` | prove the language in one real playable Forum approach | **draft / behind reviewed foundation + Operator audit human refresh** |
| SKO-1 | `sundered-keep-overlook-alternate-vertical-slice` | prove a tiny playable shelf over a vast Sundered Keep world in a standalone scene | **ready / behind reviewed 2.5D-1** |

The core realization program still has **2** implementation packets. The Sundered Keep overlook is an independent downstream consumer tracked in `design/05_levels/SUNDERED_KEEP_OVERLOOK_ALTERNATE_ROADMAP.md`.

## Not on the active roadmap

- Camera3D gameplay conversion
- 360-degree camera orbit
- CharacterBody3D
- 3D navigation
- mesh/GLB production-runtime schema
- procgen-to-mesh conversion
- vertical combat/trajectory redesign

Offline 3D authoring may be reconsidered later only as a way to generate 2D production assets.

## 2.5D-1: presentation foundation

Packet: `custodian/docs/ai_context/task_packets/archived/ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md`

Implement the smallest reusable 2D presentation primitive that makes explicit:

- ground/simulation anchor;
- presentation-only visual elevation;
- semantic depth band;
- sort/base anchor;
- Y-sort compatibility;
- reuse of `RoofOccluder2D`;
- reuse of actor contact shadows.

No production-actor/procgen retrofit in this slice.

**Status:** implemented in `custodian/game/world/presentation/isometric_2_5d/` (`IsometricPresentationProfile`, `IsometricVisualAnchor2D`); focused smoke `isometric_2_5d_presentation_foundation`. Awaiting `review-isometric-2-5d-presentation-foundation`.

## Operator animation viability gate

Before the Forum slice uses the Operator as the visual ruler for 2.5D, run `operator-2-5d-animation-viability-audit`.

The audit is read-only. Its human art-direction decision is already recorded; current Operator runtime/catalog evidence now serves only to classify legacy/fallback coverage and quantify the remaining migration backlog. Historical goalposts remain evidence, not a new approval gate:

- Lords of Pain: 16-angle rotational/viewpoint continuity, especially N → NNE → NE → ENE → E;
- repository Playable Knight: 8-direction grounding, action coherence and combat silhouette.

It must quantify production-reachable keep/cleanup/new-direction/redraw/projection buckets and produce a ranked art-production backlog. The Forum packet remains a draft until the user/ChatGPT reviews those matrices and refreshes it. Foundation review may proceed independently; Sundered's separate showcase does not inherit this Operator-art gate unless its own scope later depends on production Operator art quality.

## Canonical Operator visual lock

The user has approved a new eight-direction Operator body/material/projection reference. Before production animation regeneration or the Forum showcase treats the Operator as visually authoritative, `operator-2-5d-canonical-visual-contract` must preserve the exact source, establish dual legacy-96/canonical-128 authoring profiles, measure/landmark every direction, and wire canonical ghost/QA support into the existing Operator authoring stack. Its paired fresh-context review must pass before mass animation production.

## 2.5D-2: Forum vertical slice

Packet: `custodian/docs/ai_context/task_packets/ISOMETRIC_2_5D_FORUM_VERTICAL_SLICE.md`

Create one standalone real-Operator slice around Forum South → Adjudication Dais with:

- real Operator and PlayerController;
- real production Camera2D;
- ordinary 2D traversal/collision;
- one moving 16-direction Lords skeleton;
- raised architectural mass;
- stairs/ramp visual language;
- sortable structure;
- one overhead/roof/gantry occluder;
- contact grounding;
- flat/reference vs realized-2.5D presentation toggle.

No 3D gameplay node types.

## Human gate after 2.5D-2

Evaluate:

1. Does the world feel materially more volumetric?
2. Does the skeleton retain the dimensional quality the user liked?
3. Do structures communicate height without confusing walkability?
4. Does front/behind sorting feel natural in motion?
5. Do overhead fades preserve readability?
6. Does this feel like the CUSTODIAN direction worth productionizing?

If yes, the next work is production rollout and asset standards, not a return to live 3D by default.

## Current position

K3D-1P is complete and landed as the final Kenney walkaround precursor. The 2.5D-1 presentation foundation is implemented and awaits its fresh-context review. The Operator viability audit is complete: 69 live semantic families are legacy fallback, one authored relaxed-idle family is canonical, and 68 baseline canonical families remain (544 baseline direction-animation strips before extra modular/weapon/FX layers). The canonical visual contract and its paired review are complete/passed with accepted profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761` and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`. WB25-1 is complete/reviewed; WB25-2 guided ingress is complete/reviewed through its cycle-2 saved-document correction; WB25-3 polish automation is complete/reviewed after its proposal-integrity R0-01 correction; WB25-4 review automation has consumed those landed authorities and is now `ready/auto` with its paired review armed behind it. After foundation review passes, the Sundered Keep overlook may proceed independently; the Forum vertical slice still waits for its remaining declared dependencies/refresh. Retain the user's A/B walkaround notes as tuning input for the Forum slice and use the Sundered-specific authoring chat/roadmap for the overlook program.

H1 remains separate. At 2.5D-2 claim time, use landed H1 layout constants if available; otherwise use locked Forum coordinates read-only.
