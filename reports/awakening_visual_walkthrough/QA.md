# Awakening visual reconciliation QA — 2026-09-20

The `awakening_visual_diagnosis_capture.gd` isolation pass captured eight zones
with underlay, foreground, set pieces, and traversal layers separated. The
production walkthrough uses the real Operator and a 1920×1080 SubViewport;
`awakening_visual_walkthrough_capture.gd` reproduces its 15 checkpoints.

## Rectangle ownership

- Crèche, Ambulatory, Attestation, Reliquary, and Approach rectangular room
  fragments came from complete adjacent-zone plates remaining visible across
  the shared world. Zone art now fades by distance from the Operator to each
  Layout zone envelope, with a 128px transition.
- The hard dark connector bars were `Traversal/BlockoutPresentation`; production
  visibility is false while Layout traversal and collision remain active.
- The left-of-center Undergate dark rectangle was traversal/adjacent plate
  composition, not a defect in the canonical foreground. No environment
  foreground was replaced, and no Asset V2 job was run for this pass.
- The neutral gray around room plates was the viewport clear color. The
  collision-free `AwakeningVoidBackdrop` now covers WORLD_BOUNDS plus 1024px.

## Art and collision

- The Ambulatory shaft and Dust Lung cistern void footprints were tightened to
  the visible inner rims. Geometry smoke checks walkable rings and blocked
  interior samples.
- The P-9 visual offset is `(88,-24)` from its unchanged interaction anchor
  `(832,-1952)`; its shallow `112×32` base now centers at `(920,-1888)`.
- Undergate ambient profiles changed only for its core and two threshold zones.
  Ordinary gameplay captures show floor motif and machinery detail without an
  exposure boost; the Operator flashlight behavior is unchanged.
- [Gate pylon collision overlay](../awakening_gate_collision/gate_collision_overlay.png)
  remains valid: the 240×496 blockers align to west/east component opacity and
  leave a 272px central route. The sealed center body still hides a player
  standing behind it. Extending collision through it would close the required
  route; its authored open-state/passage composition is deferred.

## Known art gaps

The 04→05 route has uncovered rectangles after subtracting the adjacent plate
bounds from Layout connectors:

| Connector | Uncovered world rect | Size |
| --- | --- | --- |
| 04_05_A | `Rect2(640,-2432,128,96)` | 128×96 |
| 04_05_B | `Rect2(0,-2560,704,128)` | 704×128 |
| 04_05_C | `Rect2(-64,-2592,128,32)` | 128×32 |

The five Road modular underlay/foreground families remain `REGEN_REQUIRED` at
their existing native runtime canvases. No Road sprite or geometry was edited.
The Gate skull/banner direction remains `STYLE_REVIEW`.
