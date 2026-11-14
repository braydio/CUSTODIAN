# CRECHE 3D INTEGRATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `creche-3d-integration-v1`
- Category: `assets-art`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: Visual fidelity of the assembled room is human-owned and gated by `Visual review: required`. Focused checks prove the placement contract (30 sockets, uniform fits, no stretch), the Blender renders, the Godot load, and that the playable Creche is byte-identical.
- Reviewed main: `e2df427c1f80807830a27e3ea230a463787b4691`
- Authoring chat: `https://chatgpt.com/c/6af208e2-164c-83ea-9c15-439ee76fa138`
- Visual review chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34776-7eb0-83ea-b537-f0905b626455`
- Review owner: `user_and_chatgpt`
- Visual review: `required`
- Visual approval: `pending`
- Goal: Place the available Hunyuan architectural GLBs at the verified blockout's named sockets in Blender, render that assembly to 2D sprites, and load the result in a separate 2D Godot prototype level so the recognizable Creche room can be judged in the actual game engine. The playable Creche is not changed.
- Completion boundary: Done when (1) the 14 host GLBs are checksum-verified and placed at the 30 blockout sockets with a placement manifest; (2) Blender renders exist for the 960x704 top-down comparison and the elevated game-camera view; (3) per-socket sprites and a sprite manifest are exported; (4) a new Godot 2D scene at `custodian/content/levels/awakening/01_creche_integration_proto/` loads and a screenshot is captured; (5) `custodian/content/levels/awakening/01_creche/` is unchanged. Blender 3D stays the source; Godot consumes 2D sprites only. Gameplay, collision tuning and deployment are out of scope.
- Current measured state: The blockout kit is on `origin/main` (scripts, spec, README, references). Build outputs (`.blend`, `.glb`, manifest, previews) are gitignored and regenerate through `build_creche_blockout.py`. The playable level `custodian/content/levels/awakening/01_creche/` exists with 2D foreground and underlay PNGs. The 14 host GLBs exist at `/home/braydenchaffee/Nameless_Creche/GLB/` with a checksum manifest; they are host-private, not Git-published. They are normalized to roughly 2 m unit boxes with mismatched aspect ratios, and they carry 139k to 742k triangles. A scratch Blender assembly fit each GLB uniformly into its socket, which left piers at about 1.6 m tall in 5.25 m sockets and the 25.5 m crown trim as one 1.2 m piece.
- Evidence: `assets/levels/creche/docs/CLAUDE_BUILD_SPEC.md` (socket table, scale rules, lines 132 to 174); `assets/levels/creche/scripts/build_creche_blockout.py`; `assets/levels/creche/scripts/verify_creche_scene.py`; `/home/braydenchaffee/Nameless_Creche/GLB/SHA256SUMS.txt` (host-only, source of the checksums below); the existing `custodian/content/levels/awakening/01_creche/` tree.
- Task-specific authority: `assets/levels/creche/docs/CLAUDE_BUILD_SPEC.md` (dimensions, sockets, zones, scale rules); `assets/levels/creche/scripts/build_creche_blockout.py` (socket and manifest source of truth); `assets/levels/creche/scripts/verify_creche_scene.py`; `custodian/content/levels/awakening/01_creche/` (must remain unchanged).
- Work surface: Primary owner `assets/levels/creche/` (assembly and render Blender scripts, placement and sprite manifests, reports). New 2D level `custodian/content/levels/awakening/01_creche_integration_proto/` (scene, sprites, screenshot). Consumers: none. The existing Godot level loader and the playable Creche are not edited.
- Publication inputs: `assets/levels/creche/README.md`; `assets/levels/creche/docs/CLAUDE_BUILD_SPEC.md`; `assets/levels/creche/scripts/build_creche_blockout.py`; `assets/levels/creche/scripts/verify_creche_scene.py`; `assets/levels/creche/scripts/check_reference_dimensions.py`; `assets/levels/creche/references/creche_complete_1464x1074.png`; `assets/levels/creche/references/creche_floor_960x704.png`; `assets/levels/creche/references/creche_walls_960x704.png`; `assets/levels/creche/references/modular_14_contact_sheet.png`; `assets/levels/creche/docs/creche_blockout_plan.png`.
- Change:
  1. Regenerate the blockout from a clean checkout with `build_creche_blockout.py` and verify it with `verify_creche_scene.py`, so the socket manifest is the one this packet cites.
  2. Before any import, check each host GLB against the SHA-256 list below. If a file is missing or its hash differs, stop and report the exact missing or mismatched asset. Do not substitute another file.
  3. Assemble in Blender on working copies only (originals untouched). Map each socket to its GLB by the manifest `asset_hint`. Decimate working copies to at most 60,000 triangles. Fit each piece with one uniform scale so it stays inside its reserved box on every axis. Repeat piers vertically and crown trim along X as overlapping un-stretched segments. Leave the three window apertures empty.
  4. Write `placement_manifest.json` with one entry per socket: socket ID, source GLB filename and hash, translation, rotation, uniform scale, repeat count, fitted size, reserved size, and undersized axes.
  5. Render a 960x704 orthographic top-down view and an elevated game-camera view in Blender.
  6. Export per-socket sprite PNGs with transparent backgrounds and a sprite manifest under `custodian/content/levels/awakening/01_creche_integration_proto/sprites/`.
  7. Create `01_creche_integration_proto` as a 2D Godot scene that places the sprites at their socket positions. Capture a Godot screenshot showing it loaded.
  8. Record the missing or unsuitable pieces that need another Hunyuan batch.
- Preserve: `custodian/content/levels/awakening/01_creche/` byte-identical to `origin/main`; the kit files listed under Publication inputs unchanged; the host GLBs unchanged; the `CRECHE_BLOCKOUT_V1` packet unchanged; no edits to `custodian/project.godot` or any other existing level.
- Non-goals: No Godot 3D scene and no runtime 3D import of the GLBs. No gameplay, collision or camera changes to the playable Creche. No decimation or edits of host originals. No deployment. No merge of implementation work to `main` outside the workstream finish gate. Final visual approval is human-owned.
- Acceptance:
  - `placement_manifest.json` has 30 entries. Each populated socket names an existing source GLB whose checksum matches the list below. The three window apertures are listed as empty.
  - No placed piece exceeds its reserved box on any axis, and no axis is stretched non-uniformly.
  - Piers repeat to cover the 5.25 m height, and the crown trim repeats to cover its 25.5 m length, with recorded counts.
  - The 960x704 top-down render and the elevated render exist and are visually inspected.
  - The Godot 2D scene loads headless with no script or resource errors, and a screenshot is captured and inspected.
  - `git diff origin/main -- custodian/content/levels/awakening/01_creche` is empty.
  - The owner reviews the renders and the Godot screenshot against the source artwork (`Visual review: required`).
- Validation:
  - `python3 assets/levels/creche/scripts/check_reference_dimensions.py`
  - `python3 -m py_compile assets/levels/creche/scripts/build_creche_blockout.py`
  - `blender --background --factory-startup --python assets/levels/creche/scripts/build_creche_blockout.py`
  - `blender --background <generated build>/creche_blockout.blend --python assets/levels/creche/scripts/verify_creche_scene.py`
  - `blender --background --factory-startup --python assets/levels/creche/scripts/assemble_creche.py` (created by this workstream)
  - `blender --background --factory-startup --python assets/levels/creche/scripts/render_creche.py` (created by this workstream)
  - `godot --headless --path custodian --scene res://content/levels/awakening/01_creche_integration_proto/<scene>.tscn --quit-after 2` (exact scene file is named by the workstream when created)
  - `git diff --exit-code origin/main -- custodian/content/levels/awakening/01_creche`
- Task overrides: `none`
- Deferred:
  - 3D Godot integration of the GLBs (out of scope for this packet).
  - Collision proxies and gameplay tuning.
  - Another Hunyuan batch for the missing or unsuitable pieces, which the report will list.
  - Remote storage of the large renders and the `.blend` file. These go to the approved artifact store with hashes and rebuild commands, not into Git.

## Host-Private GLB Inputs

These files live only on the host at `/home/braydenchaffee/Nameless_Creche/GLB/`. They are not Git-published. Claim-time verification compares each file's SHA-256 to this list and fails closed on any missing or mismatched file.

- `f66f80928715541dd2da6d56d582fd9ff71b3fcabe7508defbdc1d9e414a14c5` Nameless_Creche_01_Crated_Thick_Column_01.glb
- `a77d052ec72ad96522333ea4c58e033f85824eada1efb1c7a0165376ac9504f8` Nameless_Creche_01_Thick_Column_01.glb
- `701f61a943cbb9123328d9aa3b67d7801284bdfaf6ceeea41ac3d44b9c64e888` Nameless_Creche_02_Back_Window_Detailed.glb
- `c5c049689661a6ad879eb53103e1678c94c6d43de7dfad047aebc0984cf22fa5` Nameless_Creche_02_Back_Window_Simple.glb
- `eb863819d1eace4dfe7175c78331c5c32e287333e937873286ab815d300264d8` Nameless_Creche_02_Low_Wall.glb
- `fb31eb13b437afd2b2b039845d24cefcf3c4a480da20aa3090222284085c17d5` Nameless_Creche_02_Stone_Rubble_01.glb
- `5ac8eacb74d545178eac84982f3da46cf3df6acf5bbf90bf43f4c7e3f6f59963` Nameless_Creche_03_Column_01.glb
- `771627a491b5c19d07bad5075c4761a744be1251152e7d7f63f590747e02b944` Nameless_Creche_04_Decorative_Crown_Molding_01.glb
- `16a82280956d4bfd329c0e4a8acac67b4f49c2180a0c6d9ce7134416abad400c` Nameless_Creche_05_Door_Archway_01.glb
- `5cfeef5ee7638486d3c7ae9275d4770962687ba74e1f4fe64aeb819d10dcf2c2` Nameless_Creche_06_Door_Body_01.glb
- `e68e5c09b0669b6aa80c48265bc602d252753351cd7b93936e5cccdd33442d11` Nameless_Creche_07_Leftern_Arch_Leg_01.glb
- `a709eeb3491db1e1749f16a00e3b6f8634f933a9c3748de6b106935e9e107cc9` Nameless_Creche_08_Stone_Crown_Moulding.glb
- `f812ed091bd2877d4883a570491c4d8b95ca083c650037040aea47b7415e18f8` Nameless_Creche_09_Wall_Creche_01_Detailed.glb
- `5a631c0f8845ae5ac6e805f488561b84e0e9df36ce3c37fca849bdbd1f37f496` Nameless_Creche_09_Wall_Creche_01_Simple.glb

## Context Pack

- Repomix: `none`
