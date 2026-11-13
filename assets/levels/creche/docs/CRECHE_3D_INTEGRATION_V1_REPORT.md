# Creche 3D Integration V1 - Report

Workstream: `creche-3d-integration-v1` · Packet: `custodian/docs/ai_context/task_packets/CRECHE_3D_INTEGRATION_V1.md`
Authoring chat: https://chatgpt.com/c/6af208e2-164c-83ea-9c15-439ee76fa138
Reviewed main: `e2df427c1f80807830a27e3ea230a463787b4691` · Pipeline: Blender 3D → 2D sprites → Godot 2D (option 1)

## Deliverables

| # | Deliverable | Location | Status |
|---|---|---|---|
| 1 | Assembled Blender scene | `assets/levels/creche/build/assembly/creche_assembled.blend` (gitignored, 41 MB) | Built |
| 2 | Top-down comparison | `assets/levels/creche/build/assembly/creche_topdown_render.png` (960×704) | Rendered; **no overlay against the source artwork yet** |
| 3 | Elevated game-camera render | `assets/levels/creche/build/assembly/creche_elevated_render.png` | Rendered |
| 4 | Godot 2D prototype scene | `custodian/content/levels/awakening/01_creche_integration_proto/creche_integration_proto.tscn` | Loads headless and windowed |
| 5 | Godot screenshot | `assets/levels/creche/build/godot/creche_integration_proto_screenshot.png` | Captured, viewed |
| 6 | Placement manifest (30 sockets) | `custodian/content/levels/awakening/01_creche_integration_proto/placement_manifest.json` | Written |
| 7 | Missing / unsuitable pieces | Section below | Listed |
| 8 | This report | `assets/levels/creche/docs/CRECHE_3D_INTEGRATION_V1_REPORT.md` | Written |

## Commands executed (claimed worktree)

```
blender --background --factory-startup --python assets/levels/creche/scripts/build_creche_blockout.py
blender --background assets/levels/creche/build/creche_blockout.blend --python assets/levels/creche/scripts/verify_creche_scene.py
CRECHE_PACKET=<packet> CRECHE_MANIFEST=<build>/creche_manifest.json CRECHE_BLEND=<build>/creche_blockout.blend \
  CRECHE_GLB_DIR=/home/braydenchaffee/Nameless_Creche/GLB CRECHE_OUT=<build>/assembly \
  blender --background --factory-startup --python assets/levels/creche/scripts/assemble_creche.py
CRECHE_OUT=<build>/assembly blender --background --factory-startup --python assets/levels/creche/scripts/render_creche.py
CRECHE_ASSEMBLY=<build>/assembly CRECHE_SPRITE_DIR=custodian/content/levels/awakening/01_creche_integration_proto/sprites \
  blender --background --factory-startup --python assets/levels/creche/scripts/export_sprites.py
python3 assets/levels/creche/scripts/make_godot_scene.py <sprites> <scene.tscn> res://content/levels/awakening/01_creche_integration_proto/sprites/
godot --headless --path custodian --import
CRECHE_SHOT=<build>/godot/creche_integration_proto_screenshot.png godot --path custodian -s res://content/levels/awakening/01_creche_integration_proto/capture_proto.gd
```

## Verification results

- Blockout build: exit 0, no traceback. Verifier: `CRECHE_GEOMETRY_VERIFIED`, 30 art sockets, 9 zones.
- GLB inputs: all 14 hashes checked against the packet's Host-Private GLB list before any import. The script fails closed on a missing or mismatched file.
- Assembly: `ASSEMBLY_OK 30 sockets`. 27 placed, 3 window apertures empty (reserved, not populated). Every placed piece records its source SHA-256.
- Playable Creche: `git diff origin/main -- custodian/content/levels/awakening/01_creche` is empty.
- Godot: the scene loads with no parse or resource errors in the capture run. Screenshot inspected: the walls, floor, window kit, alcoves, south arch, and piers all draw.

## Hashes (first 16 hex chars)

- `creche_blockout.blend` `52d3475bed0e094d`
- `creche_assembled.blend` `c3deaeb85dadfd0a`
- `creche_topdown_render.png` `23794a25e3bce81f`
- `creche_elevated_render.png` `dab6f42b14b21fbf`
- `creche_integration_proto_screenshot.png` `248aeb2bcd793473`
- `placement_manifest.json` `53f3457556753478`
- `sprite_manifest.json` `93052d7ff147f1d0`

## Scaling and placement

- Each GLB is one uniform scale, the largest that keeps it inside its reserved box on every axis. Nothing is stretched.
- Piers (north, south, side) repeat vertically as overlapping segments (4 for the 5.25 m north and south piers, 2 for the side piers). The crown trim repeats 21 times along X.
- Working copies are decimated to at most 60k triangles. Originals are untouched.
- Backing panels are **not** removed yet. The packet requires this in working copies, so it is still open.

## Defects

- **Piers are narrow.** Piece footprints are 0.83 m (north and south) and 1.2 m (side), against socket widths of 1.45, 1.8, and 1.2 m.
- **Crown trim is thin.** A 0.29 m-tall segment fills the 0.42 m-tall socket only partly.
- **Alcove 04 uses the Detailed variant** and is shallow (0.63 m deep in a 1.10 m socket).
- **Rubble pieces are narrow** on X (1.48 m in a 2.15 m socket).
- **Door leaf is narrow** on X and Z (1.28 m and 2.37 m in a 1.75 m and 3.44 m socket).
- **Window kit and door arch are short** on Y and Z (about 0.62 m and 4.13 m tall).

The packet already lists these pieces as undersized in `placement_manifest.json`.

## Missing or unsuitable pieces (another Hunyuan batch)

- **Unused GLBs:** `01_Crated_Thick_Column_01`, `02_Back_Window_Simple`, `02_Low_Wall`, `04_Decorative_Crown_Molding_01`, `07_Leftern_Arch_Leg_01`. The spec reserves `02_Low_Wall` for the library, and the others did not map to a socket.
- **Needed:** a crown-trim piece that is near 25.5 m long or repeats cleanly, a pier at the socket's real proportions (about 1.45 × 0.85 × 5.25 m), and a door leaf that matches the 1.75 m socket width.
- **Empty by design:** the three window apertures, pending a window-glazing asset.

## Remaining gaps

- No top-down overlay against the source artwork (deliverable 2 is a render, not a comparison).
- Backing panels are not removed in the working copies.
- Build artifacts are gitignored, and their remote preservation (approved artifact storage with hashes) is not done yet.
- The packet is `Visual review: required`. The packet is **not** marked complete, because the owner must approve the render and the screenshot first.
