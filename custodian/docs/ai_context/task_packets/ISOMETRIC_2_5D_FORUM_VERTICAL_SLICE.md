# ISOMETRIC 2.5D FORUM VERTICAL SLICE

> **REFRESH REQUIRED AFTER OPERATOR 2.5D ANIMATION AUDIT HUMAN DECISION**
>
> The reusable 2.5D foundation may continue through independent review, but this Operator-heavy showcase must not claim until the animation audit is complete, the canonical Operator visual contract is implemented/reviewed, and the user/ChatGPT has refreshed this packet from those results.


- Packet schema: `custodian.task_packet.v2`
- Workstream: `isometric-2-5d-forum-vertical-slice`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-isometric-2-5d-presentation-foundation, operator-2-5d-animation-viability-audit, review-operator-2-5d-canonical-visual-contract`
- Locks: `world-presentation, presentation-experiments, asset-pipeline`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `09ebb90e78e4568f81f4a7fc270da0a3d158d445`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Coordination chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4
- Goal: Prove CUSTODIAN's realized 2.5D language in one normal playable Forum approach with the real Operator/controller/Camera2D, ground-rooted depth, raised/overhead architecture, tactical occlusion fade, contact grounding and the existing 16-direction Lords skeleton.
- Completion boundary: Build one standalone authored/dev scene around Forum South → Adjudication Dais using the landed foundation and existing assets; include a raised mass/stair cue, sortable tall structure, overhead occluder, moving 16-direction skeleton and flat-vs-realized toggle; keep collision/navigation/gameplay completely 2D.
- Current measured state: K3D-1/K3D-1P provide fixed-view/walkaround precursor evidence. The reusable 2.5D foundation has landed and awaits fresh-context review. The current Operator art is not yet approved as the human visual benchmark: `operator-2-5d-animation-viability-audit` now owns that decision using current runtime pixels plus LoP/Playable-Knight goalposts. `dev_lop_skeleton` already has 16 directional 8-frame walk strips. `RoofOccluder2D`, BlobShadow and base-root sorting already exist.
- Evidence: 2.5D presentation contract/foundation; K3D-1P wrapper; Lords skeleton family/manifest; current Hub/Forum authority at execution time.
- Task-specific authority: the 2.5D contract plus live H1 layout constants if H1 has landed. If not, use locked `HUB_FIRST_SET_BLOCKOUT.md` coordinates read-only.
- Work surface: new authored/dev vertical-slice scene/wrapper/local helper; Lords skeleton consumer metadata; focused validation and roadmap/index docs.
- Change: integrate the reusable foundation into one human-reviewable gameplay composition.
- Preserve: real Operator/controller/camera; ordinary 2D collision/navigation; production Hub; campaign/transitions; existing actor pixels/states; K3D-1 evidence.
- Non-goals: no production Hub art replacement; no new mesh/GLB assets; no live 3D; no 360 camera; no free-Z; no 16-direction Operator conversion; no AI/combat conversion; no broad procgen retrofit.
- Acceptance: normal movement/camera work; skeleton presents all 16 walk directions; ground-root sorting works against Operator/structures; elevated visuals keep ground XY; overhead occluder fades/restores via `RoofOccluder2D`; shadows remain grounded; flat/realized toggle is presentation-only; focused smoke and manual walkaround are green.
- Validation: focused vertical-slice smoke + foundation smoke + one short manual walkaround + `git diff --check`. No broad sweep unless needed.
- Task overrides: `none`
- Deferred: production rollout and offline 3D-to-sprite tooling only after human approval.

## Identity

```text
workstream: isometric-2-5d-forum-vertical-slice
branch: agent/isometric-2-5d-forum-vertical-slice
closing summary: ISOMETRIC_2_5D_FORUM_VERTICAL_SLICE_CLAUDE_SUMMARY.md
```

## Preferred exact files

| Action | Path |
| --- | --- |
| create | `custodian/game/world/levels/authored/dev/isometric_2_5d_forum_vertical_slice/isometric_2_5d_forum_vertical_slice.gd` |
| create | `custodian/game/world/levels/authored/dev/isometric_2_5d_forum_vertical_slice/isometric_2_5d_forum_vertical_slice.tscn` |
| create | `custodian/game/world/levels/authored/dev/isometric_2_5d_forum_vertical_slice/isometric_2_5d_forum_vertical_slice_playtest.tscn` |
| create | `custodian/game/world/levels/authored/dev/isometric_2_5d_forum_vertical_slice/directional_skeleton_demo.gd` |
| create | `custodian/game/world/levels/authored/dev/isometric_2_5d_forum_vertical_slice/README.md` |
| create | `custodian/tools/validation/levels/isometric_2_5d_forum_vertical_slice_smoke.gd` |
| modify | `custodian/tools/validation/validation_manifest.json` |
| modify | `custodian/content/metadata/assets/families/dev_lop_skeleton.asset.json` |
| modify | `design/01_systems/ISOMETRIC_2_5D_REALIZATION_ROADMAP.md` |
| modify | `custodian/docs/ai_context/task_packets/README.md` |

## Spatial/playtest contract

Core route:

```text
ForumSouth        (0,-2464)
AdjudicationDais  (0,-3136)
```

Standalone wrapper follows the existing real-Operator dev-playtest structure with `GameRoot/World/Operator`, `PlayerController`, `Camera2D` and `LevelPlaytestBootstrap`.

Spawn near Forum South.

Raised/overhead art does not get a second collision model. The level keeps ordinary 2D authored traversal.

## Human A/B control

```text
1   flat/reference presentation
2   realized 2.5D presentation
Tab toggle
```

The toggle may change elevation offsets, foreground/roof participation, contact-shadow presentation and 2.5D structure layers.

It must not change Operator position/velocity, collision, navigation, camera ownership, spawn or gameplay state.

## Required realized composition

### Raised mass
One Dais/platform/machinery mass with stable ground footprint and obvious vertical face/top.

### Stair/ramp cue
One visual connection that communicates rise without creating free-Z simulation.

### Sortable structure
One tall structure the Operator can pass behind and in front of. Sorting follows its base/ground line.

### Overhead element
One gantry/roof/arch that can pass visually over the Operator. Use `RoofOccluder2D` when it obscures required gameplay readability.

### Grounding
Keep Operator shadow behavior. Give the moving skeleton a stable contact shadow/equivalent tied to its ground root.

## 16-direction Lords skeleton demo

Reuse existing Asset V2 family `dev_lop_skeleton`. Do not re-ingest or alter source pixels.

Create a deterministic noncombat patrol/demo actor that:

- moves along a small loop;
- quantizes velocity angle to the existing 16-direction order;
- plays `default_walk_<dir>`;
- keeps the family's existing 8 fps / 8-frame strips;
- sorts by ground root.

Direction order:

```text
n, nne, ne, nee, e, see, se, sse,
s, ssw, sw, sww, w, nww, nw, nnw
```

Add the vertical slice as a consumer in `dev_lop_skeleton.asset.json` only. Do not change family state definitions.

## Prohibited live-3D path

The new slice must not use:

```text
Node3D
Vector3
Camera3D
CharacterBody3D
CollisionShape3D
NavigationRegion3D
MeshInstance3D
```

## Focused smoke

Manifest ID: `isometric_2_5d_forum_vertical_slice`.

Assert:

1. real Operator/PlayerController/Camera2D wrapper;
2. valid Forum spawn;
3. flat/realized toggle preserves Operator global position;
4. elevated nodes preserve ground-root position;
5. skeleton exposes/maps all 16 directional walk states;
6. sortable structure uses base-anchor semantics;
7. `RoofOccluder2D` controls the overhead target;
8. presentation owns no extra gameplay collision/navigation;
9. no prohibited 3D type appears in the new slice;
10. production main scene is unchanged.

## Human review

Walk Forum South → Dais → back in both modes and answer:

- materially more volumetric?
- skeleton still has the appealing dimensionality?
- front/behind ordering natural?
- overhead fades readable?
- raised/stair cues useful?
- feels like the CUSTODIAN direction worth productionizing?

## Closeout

```bash
python custodian/tools/validation/run_validation.py --test isometric_2_5d_forum_vertical_slice
python custodian/tools/validation/run_validation.py --test isometric_2_5d_presentation_foundation
git diff --check
```

Then manually run the playtest for 2–3 minutes. Return the result to the authoring chat for the production rollout decision.
