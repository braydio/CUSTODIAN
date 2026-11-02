# Isometric 2.5D Presentation Foundation

Reusable 2D presentation contract from
`design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`. No 3D gameplay path.

- `IsometricPresentationProfile` — `visual_elevation_px`, `depth_band`, `sort_anchor_offset`.
  Band defaults: UNDERLAY -300, VISTA -200, SURFACE -100, GROUND 0, STRUCTURE 40,
  ROOF_OCCLUSION 90, OVERHEAD 100. Defaults only; existing scene z-values are not migrated.
- `IsometricVisualAnchor2D` — root position is the ground contact and sort point.
  Elevation offsets only the `VisualRoot` child. No physics process, collision, or navigation.

## Reuse, not replacement

- Roof/foreground fade: `RoofOccluder2D` (`game/world/common/roof_occluder_2d.gd`) stays the authority.
- Actor contact shadows: `game/actors/effects/blob_shadow.gd` stays the precedent; static
  presentation may use baked/dedicated shadows. Shadows stay at the ground root.
- Sorting: use `y_sort_enabled` on the parent; anchors sort by ground Y, never by the elevated sprite.

Not retrofitted into production scenes. Playable integration is
`isometric-2-5d-forum-vertical-slice`.
