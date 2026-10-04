
# CUSTODIAN ISOMETRIC 2.5D REALIZATION ROADMAP

**Program ID:** `isometric-2-5d-realization`  
**Status:** active / pivot locked / successor packets authored  
**Priority:** P2  
**Reviewed main:** `09ebb90e78e4568f81f4a7fc270da0a3d158d445`  
**Last Updated:** 2026-10-04  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff  
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
| precursor | `kenney-isometric-blockout-playtest` | finish walkable Kenney/native comparison harness | **ready / unchanged** |
| 2.5D-1 | `isometric-2-5d-presentation-foundation` | converge ground anchors, visual elevation, depth bands and existing occlusion/shadow precedents | **ready / depends on K3D-1P** |
| 2.5D-2 | `isometric-2-5d-forum-vertical-slice` | prove the language in one real playable Forum approach | **ready / depends on 2.5D-1** |

Expected new implementation packets: **2**.

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

Packet: `custodian/docs/ai_context/task_packets/ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md`

Implement the smallest reusable 2D presentation primitive that makes explicit:

- ground/simulation anchor;
- presentation-only visual elevation;
- semantic depth band;
- sort/base anchor;
- Y-sort compatibility;
- reuse of `RoofOccluder2D`;
- reuse of actor contact shadows.

No production-actor/procgen retrofit in this slice.

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

K3D-1P remains the immediate executable precursor. After it lands, 2.5D-1 becomes eligible. 2.5D-2 follows the foundation.

H1 remains separate. At 2.5D-2 claim time, use landed H1 layout constants if available; otherwise use locked Forum coordinates read-only.
