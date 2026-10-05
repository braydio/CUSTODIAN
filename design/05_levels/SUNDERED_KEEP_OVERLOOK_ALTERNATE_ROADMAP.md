# SUNDERED KEEP OVERLOOK ALTERNATE ROADMAP

**Program ID:** `sundered-keep-overlook-alternate`  
**Status:** active / standalone proof first  
**Priority:** P2  
**Reviewed main:** `223d15ab6695dc79e714398e5645d24b4c89e4c7`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7  
**Presentation authority:** `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`  
**Existing production authority:** `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`

## Intent

Prove a new Sundered Keep approach composition in a standalone playable scene before changing the production route or procgen integration.

The target is a **small playable foreground shelf/perch overlooking a much larger apparent world volume**, with the Sundered Keep occupying the upper/mid distance as a physically distant destination. The presentation should feel fixed-elevated-oblique, volumetric, and close to 3D in depth/readability while remaining ordinary CUSTODIAN 2D gameplay underneath.

The user-provided visual reference and composition discussion live in the recorded authoring chat above. Do not commit or redistribute that third-party screenshot; use it only as a composition reference.

## Locked runtime doctrine

```text
authoritative movement/collision/navigation/combat = 2D XY
gameplay camera = Camera2D
presentation = may fake height, volume, depth, perspective and occlusion
```

This program does **not** reopen the canceled live-3D gameplay path.

No Camera3D, CharacterBody3D, NavigationRegion3D, free camera orbit, or runtime mesh-world conversion is required.

Offline 3D authoring (Blender/Kenney Shape or equivalent) remains an optional future content-production tool only if the 2D layered proof demonstrates a specific asset-authoring limitation. It is not a dependency for the current program.

## Composition lock

The standalone proof should stage:

1. **foreground shelf/perch** — compact walkable space under the Operator;
2. **visible shelf thickness / cliff face** — presentation-only height cue below the ground root;
3. **large nonplayable depth field** — mist, ocean, chasm, lower ruins, or atmospheric negative space;
4. **distant Keep mass** — major architectural silhouette across the depth field;
5. **foreground framing** — vegetation/ruin/cliff framing that sells depth but yields to tactical readability;
6. **fixed elevated-oblique framing** — the world should feel deep because of authored staging, not because the camera can orbit.

Useful review targets rather than hard gameplay constraints:

- Operator primarily occupies the lower third of the establishing frame;
- the Keep owns a substantial upper/mid-frame silhouette;
- a clearly nonwalkable depth interval separates shelf from Keep;
- the playable shelf occupies a minority of the apparent visible world.

## Program slices

| Slice | Workstream | Goal | State |
| --- | --- | --- | --- |
| prerequisite | `isometric-2-5d-presentation-foundation` | reusable ground-root / visual-elevation / depth-band primitives | ready / auto |
| prerequisite review | `review-isometric-2-5d-presentation-foundation` | independently prove the reusable primitive stays 2D-authoritative | ready / auto behind foundation |
| SKO-1 | `sundered-keep-overlook-alternate-vertical-slice` | standalone playable composition proof using existing art donors | ready / auto behind reviewed foundation |
| SKO-1R | `review-sundered-keep-overlook-alternate-vertical-slice` | fresh-context runtime/composition-contract review | ready / auto behind SKO-1 |
| SKO-2 | `sundered-keep-overlook-alternate-art-polish` | optional Asset V2 layered-art pass only if SKO-1 proves composition but donor art limits finish | blocked / manual |
| SKO-2R | `review-sundered-keep-overlook-alternate-art-polish` | paired technical/art-intake review | ready / auto behind SKO-2 |
| SKO-3 | `sundered-keep-overlook-runtime-integration-plan` | re-audit production/procgen seams and author the actual integration series | blocked / manual / planning-refresh required |
| SKO-3R | `review-sundered-keep-overlook-runtime-integration-plan` | fresh-context architecture/workflow review of the selected integration seam and authored packet graph | ready / auto behind SKO-3 |

## SKO-1 exit gate

SKO-1 is a success if the user can walk the real Operator around the compact shelf and answer **yes** to the core direction:

> Does this feel like a small playable place embedded in a vast, physically convincing Sundered Keep world, rather than a flat route with backdrop art?

The proof may be visually rough. It should not create new art merely to avoid exposing whether the composition itself works.

## SKO-2 activation rule

Do **not** activate SKO-2 automatically.

Activate only when the SKO-1 human review says:

- the composition/depth direction is correct; and
- existing donor art is the limiting factor.

If SKO-1 fails spatially, revise the standalone composition first rather than making prettier assets.

## SKO-3 integration gate

After SKO-1 review, and after SKO-2 review if SKO-2 is used, return to:

https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

Re-audit the then-current Sundered production approach, generated frontage/vista, world-ingress route, procgen placement, camera handoff, and spawn/playability state. Only then author production integration packets. Those implementation packets must remain dependency-blocked on `review-sundered-keep-overlook-runtime-integration-plan` (directly or through a reviewed predecessor) so the integration architecture is independently checked before production mutation begins.

No production/procgen implementation packet is pre-authored now because the validated standalone composition may change what the correct insertion seam is.

## Parallel correctness lane

The current-main Operator-spawn-outside-playable-region defect is owned separately by:

- `contract-world-playable-region-spawn-validity-fix`
- `review-contract-world-playable-region-spawn-validity-fix`

That P0 does not block building the standalone authored overlook scene, but it must be resolved before future procgen integration of this program is treated as production-ready.

## Blender / offline 3D decision

Do not require the user to learn Blender for SKO-1 or SKO-2.

Reconsider offline 3D authoring only if, after a successful 2D layered composition proof, one of these remains demonstrably hard:

- consistent oblique fortress perspective across several depth plates;
- believable shelf/cliff volume from multiple nearby camera positions;
- repeated directional architectural variants;
- perspective-consistent lighting/shadow masks.

If that happens, 3D is an **asset-authoring tool** that renders fixed 2D plates/sprites into Asset Pipeline V2, not a gameplay-runtime migration.
