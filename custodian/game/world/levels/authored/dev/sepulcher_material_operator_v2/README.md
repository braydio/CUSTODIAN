# Sepulcher Canonical Operator + Material V2 Preview

This standalone development scene is an unapproved gameplay and presentation
preview. It instantiates the real Operator, controller, collision, HUD and
Camera2D. The approved 128px source is shown as an idle-only visual on that same
moving actor. Eight-direction idle frames are illustrative at 8 FPS; 128px
movement and combat artwork has not been authored or approved.

## Controls

- `1`: neutral blockout
- `2`: original four-piece courtyard floor
- `3`: repeated northwest crop diagnostic (nonproduction)
- `4`: quiet modular floor (default)
- `Tab`: toggle courtyard and quiet modular floors
- `B`: toggle both unique bronze inlay routes
- `V`: toggle canonical 128px idle and live legacy Operator visuals
- Standard gameplay movement controls move the actual Operator.

All floor modes use the same world coordinates, player, collision, navigation,
and scoped gameplay camera. The quiet floor uses 48 native 128px atlas cells
from the existing V1 preview crops. No source artwork is modified, regenerated,
or submitted to Asset Pipeline V2 by this preview.

Launch `sepulcher_material_operator_v2.tscn` directly in Godot to play.
