# Sepulcher Paving Native Quad Playtest V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `sepulcher-paving-native-quad-playtest-v1`
- Category: `assets-art`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `sepulcher-native-paving-playtest`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-sepulcher-paving-native-quad-playtest-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `A new playable Godot scene must preserve Operator and camera identities while keeping unapproved external source art isolated from gameplay authority and Asset V2.`
- Reviewed main: `8beb9d9da9a0be46f470f959d111241d19169f88`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: `Provide a runnable, real-Operator game-camera comparison of a 1024px contiguous source-detail paving composition against neutral baseline and deliberately repeated single-crop material, without changing production Hub or granting artwork approval.`
- Completion boundary: `One new standalone playable 1024x768 Godot test scene with three presentation modes and exactly four independently placed native 512x512 source crops from the immutable master, deterministic one-time tool, focused technical smoke, and three same-player/camera visual proofs. Implementation lands for independent review and stops before human art approval or new material generation.`
- Current measured state: `At main 8beb9d9da9a0be46f470f959d111241d19169f88, design brief and four-asset planning manifest exist, with four exact source rectangles. Codex's November 1 host investigation confirmed no named active packet/claim and successfully downloaded SHA-verified Dropbox ZIP to /tmp, but performed no source staging, cropping, game-scene edits or Godot validation. Unapproved 1254x1254 source is only in pinned Dropbox ZIP/raw candidate; no approved tile or runnable Sepulcher modular preview exists.`
- Evidence: `design/04_architecture/SEPULCHER_PAVING_NATIVE_QUAD_CODEX_BRIEF_V1.md; design/04_architecture/SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json; pinned Dropbox source package and Codex failure report (2026-11-01); existing Kenney standalone playtest scene and smoke.`
- Task-specific authority: `design/04_architecture/SEPULCHER_PAVING_NATIVE_QUAD_CODEX_BRIEF_V1.md; design/04_architecture/SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.md; custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md; custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md; custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md.`
- Work surface: `custodian/tools/art/sepulcher_paving_native_quad.py; custodian/tools/art/sepulcher_paving_source_stage.py; custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn; adjacent scene-local script/neutral presentation and focused new smoke; four dev-only LFS-tracked cropped preview textures. No production Hub or Asset V2 family changes.`
- Publication inputs: `design/04_architecture/SEPULCHER_PAVING_NATIVE_QUAD_CODEX_BRIEF_V1.md, design/04_architecture/SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.json, design/04_architecture/SEPULCHER_MODULAR_PLAYTEST_ASSET_PILOT_V1.md, custodian/tools/art/sepulcher_paving_native_quad.py, custodian/tools/art/sepulcher_paving_source_stage.py, custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md, custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn, custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.tscn, custodian/tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd, custodian/tools/iteration/publish_review_artifacts.py`
- Change: `Claim the existing named packet through dispatch, verify and stage immutable source only into source_work using the already published staging tool; run the fixed four-crop tool; construct the independent Godot test scene from real Operator, game Camera2D, and LevelPlaytestBootstrap; offer modes 1 neutral, 2 native adjacent quad, 3 NW-repeat diagnostic, Tab 1/2 toggle, and matched-camera three-view evidence; validate then land for independent review. Do not replace art by a giant downscaled map.`
- Preserve: `Root/Hub collision, navigation, grave-event coordinates/persistence, production main scene and camera settings, Asset V2 source approval/inbox and independent-review workflow; original RGB master unchanged and SHA-pinned.`
- Non-goals: `No new generated art, alternate crops, artificial seam repair, asset family registration, Dropbox reupload, production room cutover, grave controller, other three pilot assets or global camera refactor.`
- Acceptance: `A1: 1254x1254 RGB source matches pinned SHA 62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf; four exact 512x512 source boxes and full 1024x1024 assembled original-region pixel equality. A2: playable scene at declared path instantiates real Operator and normal gameplay Camera2D/bootstrap and retains responsive movement. A3: keys 1/2/3/Tab swap ONLY floor presentation, with identical player transform, camera transform/zoom, collision and navigation; the 1024x1024 original-detail patch is not resized to the 1024x768 gameplay view. A4: precisely three same-camera/same-player captured modes, with actual game scale and no synthetic Operator pasted in. A5: no source-work master or unapproved art promoted to Asset V2; only clearly labeled dev test sources (Git LFS for PNG), no production Hub edits. A6: focused Godot smoke and changed-file validation prove technical contract; independent review receives concrete evidence. Human quality judgment remains pending.`
- Validation: `python3 custodian/tools/art/sepulcher_paving_native_quad.py --self-test; sha256sum of staged pinned original; new focused Godot smoke (author in this workstream) against custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn; godot --headless --path custodian --script res://tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. Stage/hash/crop equality must pass before launching Godot; no broad CI sweep or unbounded screenshot capture.`
- Task overrides: `none`
- Deferred: `Human choice of acceptable material scale/repetition, actual seamless production tile, other three four-asset pilot sources, reviewed Asset V2 family, district-scale Sepulcher or Dust Lung asset-program revision.`

## Source handoff: exact external binary, preclaim provenance gate

The verified raw art is an **unapproved preview source**, not a production Asset V2 source. A Dropbox file exists and the Codex transcript confirms real host retrieval without local repository writes. As a legacy preview-only source, it was published at a **flat** Dropbox `implementation_inputs` path rather than the canonical nested manifest-last format. Do not misrepresent this as a canonical `custodian.implementation_handoff.v1` batch or a dispatcher-registered artifact.

- ZIP: `/CUSTODIAN/implementation_inputs/custodian_sepulcher_paving_native_quad_preview_v1_20261101.zip`
- Dropbox file ID: `id:8NXqdXuW6GUAAAAAAAAGLw`; revision `65f33a03ca3ce915cdd61`; bytes `3672520`.
- ZIP SHA-256: `1172e3e78741f0f18285dbbb50e40fd9e496470d84b1ec02f075bb7ff1d29344`
- Raw PNG: `/CUSTODIAN/implementation_inputs/custodian_sepulcher_paving_base_source_candidate_v1_20261101.png`; Dropbox ID `id:8NXqdXuW6GUAAAAAAAAGMA`; revision `65f33a0c84155915cdd61`.
- Raw PNG bytes `3783377`, SHA-256 `62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf`, RGB 1254x1254.
- Stage source at `custodian/asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/paving_base_source.png` only after successful dispatcher claim; verify checksum after staging. The existing Dropbox tool/temporary ZIP are transport, **never a repository asset**. If SHA, immutable retrieval, expected source bytes, or Git LFS for test-piece publication fail, stop on that specific blocker; do not invent a replacement.
- Download the pinned ZIP by the user's configured Dropbox connector/host transport, verify ZIP SHA before extraction, and run `python3 custodian/tools/art/sepulcher_paving_source_stage.py --source <extracted>/source/paving_base_source.png --custodian custodian --install`; the program checks source bytes and refuses conflicting contents. Then `python3 custodian/tools/art/sepulcher_paving_native_quad.py --custodian custodian`. Do not run either before claim. Tool code is **tracked on main** with this packet, not exclusively in the ZIP.

## Exact source geometry and in-game composition

Four crop boxes, Pillow half-open coordinates; each is 512x512 RGB, **no resampling**:

| Piece | Source pixels | Sprite2D center in local level |
|---|---|---|
| NW | `(128,128,640,640)` | `(256,256)` |
| NE | `(640,128,1152,640)` | `(768,256)` |
| SW | `(128,640,640,1152)` | `(256,768)` |
| SE | `(640,640,1152,1152)` | `(768,768)` |

The patch covers a contiguous 1024x1024 source region and may extend south beyond the initial 1024x768 view. Every piece is a separate Sprite2D with `centered=true`, native scale `(1,1)`, rotation `0`, a shared origin, below Operator in Z. Keep the repeat-NW mode visibly **diagnostic and non-seamless**. Game geometry is owned by the independent sandbox, never inferred from pixels.

The four crop PNGs are **dev-only sources**. The implementation should commit the exact four derived PNGs under `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/preview/generated/` with repository-required Git LFS tracking, so the landed review can actually load the test scene. Never commit the full unapproved original master to Git or register its derivatives as production assets. Verify LFS object availability and exact downstream scene imports. The 1024px reconstructed reference can remain ignored/QA evidence rather than a runtime dependency.

## Review evidence budget and ownership

First use source SHA, pixels, Godot scene/node assertions, camera equality, and input/geometry checks. Capture only three matching Operator/camera ROI frames (modes 1, 2, 3). If a reviewer must compare subjective scale, density, repetition or character readability, publish **one** small review bundle via `custodian/tools/iteration/publish_review_artifacts.py --important --reason "Sepulcher native quad playable scene"` as governed by `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`, root `/CUSTODIAN/visual_review/sepulcher-paving-native-quad-playtest-v1/`. Ask: (1) Is original stone detail legible at real Operator scale? (2) Does the contiguous mosaic feel suitably sized? (3) Is the NW-only repeated pattern too obvious for a future tile? Publish manifest and stop for user visual decision, **not** automatic image approval.

## Execution feedback and truthful closeout

At workstream finish, populate `custodian.task_completion.v1` and `custodian.task_feedback.v1` in the implementation packet/summary. Technical completion of a playable preview does not mean the original source becomes a seamless tile or approved art. Keep the unapproved preview provenance visible.

## Next Handoff

- Next workstream: `review-sepulcher-paving-native-quad-playtest-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; the paired reviewer independently verifies the landed playable test and its objective proofs`
- Next action: `After technical implementation lands, claim the separate paired review with fresh context. Return the three real-game-camera screenshots to the user for subjective judgment. Do not advance to pilot asset 2.`
- Blockers or open questions: `No remaining art-direction decision is required to build the preview. Immutable Dropbox ZIP retrieval, host source staging, Git LFS and Godot execution are fail-closed checks inside the claimed workstream; user art approval is a later visual decision.`
