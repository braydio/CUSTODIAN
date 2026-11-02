# Gate of Dust collision QA — 2026-09-20

- [Production capture](gate_production.png)
- [Production capture with pylon collision outlines](gate_collision_overlay.png)

Recreate with `godot --path custodian --rendering-driver opengl3 --script
res://tools/validation/awakening_gate_collision_capture.gd` from the repository
root with an active display. Godot headless uses a dummy renderer and cannot
produce these captures.

The west and east pylon sprite canvases are 256×512. At alpha ≥200, their
nontransparent pixel bounds are respectively `(24, 5, 250, 504)` and
`(17, 15, 239, 495)` within those canvases. The previous 160×320 collision
rectangles covered only the central portions of visibly solid components.

Both live pylon blockers now use 240×496 rectangles at their existing Layout
centers `(−256, −4768)` and `(256, −4768)`. The cyan outlines in the second
capture are drawn from the actual runtime `CollisionShape2D` nodes. The
remaining edge pixels lie in the sprite's irregular silhouette or decorative
fringe; a larger rectangle would occupy transparent space. The central gap
between pylon blockers is 272 world pixels, and the geometry smoke confirms
the authored route remains traversable.

The backdrop and component registration are unchanged. The central sealed Gate
body is visibly opaque across part of the mandatory route while that route is
walkable. Extending collision through it would seal the locked route. Resolve
the visual passage through a future authored Gate composition or state decision;
do not expand collision across the route.
