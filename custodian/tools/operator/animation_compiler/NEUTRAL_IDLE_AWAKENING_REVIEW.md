# Corrected Neutral Idle in Awakening

Status: `candidate_unapproved`; technical checks passed; animation quality awaits human review.

## Candidate identity

- Version: `neutral_idle_rest_frame_v2_awakening_128_v1`
- Candidate job: `op3d-neutral-idle-v2-f7832b29158a1aa7e78e9c53`
- Receipt SHA-256: `5c237de902397e1bae1f0de6bc3951334369b95db46c9b9e9064ef38b916853b`
- Original Mixamo FBX SHA-256: `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`
- Experimental ITER005 master SHA-256: `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`
- Corrected motion artifact SHA-256: `6915baf7cf56c7606d328d5de497bf8e768f2c48c9b7f8b6d0eff1d39cce0bb5`
- Source action: `Armature|mixamo.com|Layer0`
- Target skeleton signature: `abcadb2f29bb273b25d8db278b5e33af27597a8a68a1c90550a92e2b7da7bbd2`
- Sampling: source frames 1–263, 30 FPS; frame 264 is omitted only as the verified duplicate loop endpoint. Authored source interval remains 1–264 / 8.8 seconds; sampled loop is 8.7667 seconds. Runtime timing authority is absent.

## Awakening preview

- Scene: `res://scenes/debug/operator_3d_animation_preview_awakening.tscn`
- Real environment: `res://scenes/awakening_first_return.tscn`, Attestation Gallery (`zone03_attestation`)
- Spawn: `(0, -1824)`, walkable and outside blocking geometry; initial direction South.
- Camera: existing `game/world/camera.gd`, authored zoom `1.89`.
- Godot preview package: `res://.ai/operator_3d_animation_preview/op3d-neutral-idle-v2-f7832b29158a1aa7e78e9c53-5c237de90239`
- UI labels the exact candidate version, uses one existing Operator body owner, and keeps candidate/approved switching and all eight direction controls. Candidate playback uses authored FPS without runtime timing authority.
- Gameplay, player simulation, collision and Awakening trigger monitoring are disabled in the dev wrapper. Zone lighting, underlay and occlusion are from the real scene.
- The preview wrapper applies a preview-instance-only alpha blend to the existing BlobShadow material so its transparent texels do not appear as a black rectangle over the floor. Its existing texture, transform and placement are retained; no production asset or scene was edited.

## Technical evidence

- Blender render: 8 independent directions × 263 images = 2,104 PNGs; every frame is 128×128 RGBA and hash-bound. Camera elevation 45°, 50 px/m, root `(64,106)`, one fixed master-derived scale `1.2287417600294088`, no mirroring.
- Godot smoke: passed; imported and verified all 2,104 frames, authored 30 FPS, 8 directions, 2,104 checked textures, exact root registration, full-body owner count 1, real Operator scene and Awakening camera, visible shadow, walkable spawn, visible Attestation underlay/foreground, gameplay and progression triggers disabled.
- Retarget validation evidence reports mean normalized ankle spacing `0.496191` target leg lengths and `1.213221` pelvis widths; mean elbow angles L/R `157.217° / 162.146°`; mean knee angles L/R `159.929° / 153.098°`; mean shoulder-to-wrist direction error L/R `7.49° / 17.012°`; zero below-ground mesh frames and minimum mesh height `0.00116504 m`.
- Loop endpoint was verified duplicate: source endpoint maximum joint delta `9.3775e-05 m`, target local-location delta `1.85e-07 m`, target local-rotation delta `1.791e-05°`.
- Fresh Blender repeat test over 24 key samples (frames 1, 132, 263 in all eight directions): 19/24 decoded RGBA images matched exactly; 0/24 PNG file hashes matched. This is a measured renderer nondeterminism limitation.
- Boundary finding: Southwest alpha touches the last image row in 152/263 sampled frames. It is recorded for visual assessment; the technical report does not treat this as approval or conceal it.
- Original FBX and experimental `.blend` still match their pinned hashes. No source, master, runtime art, timing authority, or canonical asset was changed.

## Visual review files

- Full playable loop: `neutral_idle_awakening_full_loop.mp4`, 1280×720, H.264, 30 FPS, 263 frames, 8.7667 seconds. SHA-256: `1b8440a522394a517803f862e599f94566c3e798e13793995e9e84917c41a084`.
- Matched previous-vs-corrected South comparison: `neutral_idle_previous_vs_corrected_awakening.png` (source frames 1, 132 and 263; same environment, camera, scale and registration).
- Full technical QA: `../qa/neutral_idle_technical_qa.v2.json`.
- Repeat comparison: `../qa/render_repeat_comparison.v1.json`.
- Candidate receipt: `../candidates/neutral_idle_candidate_receipt.v2.json`.

## Human questions

1. Do the corrected hands and arm silhouette read as relaxed through the complete loop?
2. Is the stance and weight distribution natural, including the Southwest last-row contact and the prior raised-foot/stagger concern?
3. Does the subtle motion read as alive at the actual in-game scale and Awakening camera framing?

Technical QA does not grant artistic approval or production authority.
