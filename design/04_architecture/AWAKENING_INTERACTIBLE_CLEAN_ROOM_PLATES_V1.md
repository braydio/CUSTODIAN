# Awakening · Interactible Clean Room Plates V1

**Decision:** user approved authored, prop-free architectural room plates rather than mounting standalone interactible artwork over already-baked machines. **Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166.

## Authoritative composition

- Recreate **only the affected Crèche and Undergate background underlays** as architecture/environment. Interactible console and damaged Port terminals become separate Asset V2 `world_prop` sprites under existing zone `SetPieces`.
- Remove both old hero machine bodies, their luminous screens, controls, machine-specific foot/shadow silhouette and prop-specific decals from the environment underlays. Do not leave ghost silhouettes, duplicate terminals or machine-specific markings that remain when the props are hidden. Retain structural walls, permanent architectural sockets/anchors, flooring, grates, distant non-interactive machinery, environmental lighting texture, and route surfaces. A powered machine's emissive effect stays with the prop, not the backdrop.
- Pixel canvases and alignment **must remain exact**: `awakening_creche_environment/underlay` 960×704 at scene position `Vector2(0,-32)`; `awakening_undergate_environment/underlay` 1536×1216 at `Vector2(0,-4320)`. Both are static omni one-frame Asset V2 `backdrop` states. Preserve centered `Sprite2D`, image origin, full-frame crop, orientation, world scale, surrounding scene seams, existing collision/navigation, physics/lighting, and the untouched foreground plates unless measured proof shows the foreground separately contains removable prop pixels. If foreground surgery is necessary, stop and scope exact additional states rather than silently modifying them.
- Crèche reference anchor: `Zone01_Creche/SetPieces/CrecheConsoleBody` currently at `Vector2(105,118)`; Crèche gameplay interaction remains `CrecheConsole` `Vector2(112,144)`. The current `visible_body_source=awakening_creche_underlay_960x704.png` is historical and must be removed or replaced on the real cutover.
- Undergate gameplay interaction stays `PortStatusPlaque` `Vector2(128,-4016)`. It is a visibly **damaged/read-only** status console, not an operative Continuity Port or route.
- Existing Crèche activation effect stays 8 frames of 128×128 at 8 FPS, with screen-local anchor; prop-specific shadow/light/occlusion should be rendered with the prop or its presentation-only child, not baked in the room plate. No new interaction owners.
- Gate, 04→05 registered composition, other Awakening zone plates, camera, world transforms and lighting systems remain outside this slice.

## Asset V2 source contract

| State | Source-work authoring master | Normalized inbox | Canvas | Frames |
|---|---|---|---|---|
| `awakening_creche_environment/underlay` | `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` | `custodian/asset_drop/inbox/awakening_creche_environment/underlay.png` | 960×704 RGBA | 1 |
| `awakening_undergate_environment/underlay` | `custodian/asset_drop/source_work/awakening/awakening_undergate_environment/underlay_source.png` | `custodian/asset_drop/inbox/awakening_undergate_environment/underlay.png` | 1536×1216 RGBA | 1 |

Reuse existing backdrop family schemas:
`custodian/content/metadata/assets/families/awakening_creche_environment.asset.json` and
`custodian/content/metadata/assets/families/awakening_undergate_environment.asset.json`.
No new family, no direct runtime PNG write. Preserve background alpha semantics and no canvas-wide opaque foreground.

## Sequence / atomic cutover

1. `awakening-interactible-clean-room-plates-v1` is **source-only preparation/review**, not a published scene cutover. Use the hydrated LFS originals in the existing isolated inspection worktree as immutable references; stage clean replacement images in the two `source_work` directories. Establish pixel-diff/alpha extent outside identified machine ROIs, geometry anchor parity and registration against unchanged foregrounds. Prepare temporary composited previews with the separate hero props. Human approves exact image SHAs before runtime replacement.
2. `awakening-creche-console-sprite-reauthor-v1` consumes reviewed clean Crèche plate and approved hero, then **atomically** ingests the Crèche underlay+hero and replaces the current baked-body fallback with the actual Sprite2D + FX screen child. Never land a no-console intermediate scene.
3. `awakening-interactible-console-port-presentation-v1` consumes reviewed clean Undergate plate and approved damaged Port body, then **atomically** ingests its underlay+prop and mounts to existing status owner. Never land a damaged Port without its visual owner.
4. Both cutovers run `asset.py plan`, explicit reviewed replacement `--replace`, `status` and `doctor`, SHA-256/provenance checks and Godot imports; preserve previous runtime assets for reversible replacement. Check actual game-scale renders without HUD and native-scale unmodified peripheral regions.
5. Aesthetic approval of source previews is **not** approval of in-game fit. Repeat compact human visual review at runtime before finishing either scene cutover.

## Validation and negative controls

Existing `custodian/scenes/awakening_first_return.tscn` and `custodian/game/world/awakening/awakening_first_return.gd` are real owners. Test existing `awakening_creche_console_screen_anchor_smoke.gd`, `awakening_first_return_progression`, `awakening_art_registration`, `awakening_undergate_lighting`, scene seams, ingress/collision, FX once/repeat/reset, status readout and changed-file coverage. In a no-prop render, no console or Port body may remain baked in the new background; in a normal render, each appears **once**, with prop-specific screen/FX/shadow. Fail on floor-flash, misregistration, art-dependent gameplay nodes, accidental line-of-sight/route change, missing registered underlay, foreground matte or missing V2 receipts.

**Decision status:** layout/ownership design approved; source artwork and gameplay-scale aesthetic approval **still pending**. The previous baked-body fallback is superseded prospectively; it remains a valid historical baseline until both reviewed replacement sources and their atomic cutovers are ready.
