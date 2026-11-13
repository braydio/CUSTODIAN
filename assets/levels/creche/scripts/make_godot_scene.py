"""Write the Creche integration prototype scene from the sprite manifest.

Each sprite is a full 960x704 frame rendered from the same camera, so every
Sprite2D is centered on the frame and stacked by depth through z_index.
"""
import json
import os
import sys

SPRITE_DIR = sys.argv[1]
SCENE_PATH = sys.argv[2]
RES_PREFIX = sys.argv[3]  # e.g. res://content/levels/awakening/01_creche_integration_proto/sprites/
FRAME_CENTER = (480, 352)

sprites = json.load(open(os.path.join(SPRITE_DIR, "sprite_manifest.json")))
lines = [f"[gd_scene load_steps={len(sprites) + 1} format=3]", ""]
for i, s in enumerate(sprites, start=1):
    lines.append(f'[ext_resource type="Texture2D" path="{RES_PREFIX}{s["sprite"]}" id="{i}_tex"]')
lines.append("")
lines.append('[node name="CrecheIntegrationProto" type="Node2D"]')
lines.append("")
for i, s in enumerate(sprites, start=1):
    name = s["socket"]
    lines.append(f'[node name="{name}" type="Sprite2D" parent="."]')
    lines.append(f'texture = ExtResource("{i}_tex")')
    lines.append(f"position = Vector2({FRAME_CENTER[0]}, {FRAME_CENTER[1]})")
    lines.append(f"z_index = {s['depth_order']}")
    lines.append("")
backdrop = os.path.join(SPRITE_DIR, "room_elevated_backdrop.png")
if os.path.isfile(backdrop):
    # Full-room render (walls, floor and pieces) sits behind every socket sprite.
    lines.insert(1, f'[ext_resource type="Texture2D" path="{RES_PREFIX}room_elevated_backdrop.png" id="backdrop_tex"]')
    lines[0] = f"[gd_scene load_steps={len(sprites) + 2} format=3]"
    lines.append('[node name="RoomBackdrop" type="Sprite2D" parent="."]')
    lines.append('texture = ExtResource("backdrop_tex")')
    lines.append(f"position = Vector2({FRAME_CENTER[0]}, {FRAME_CENTER[1]})")
    lines.append("z_index = -1")
    lines.append("")
open(SCENE_PATH, "w").write("\n".join(lines))
print("SCENE_WRITTEN", len(sprites), SCENE_PATH)
