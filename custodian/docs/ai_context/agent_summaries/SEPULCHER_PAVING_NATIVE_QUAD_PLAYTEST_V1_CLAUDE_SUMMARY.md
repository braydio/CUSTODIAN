# Sepulcher Paving Native Quad Playtest V1

Workstream: `sepulcher-paving-native-quad-playtest-v1`

## Delivery

- Scene: `custodian/game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn`
- Level: 1024×768 walkable sandbox; original 1024×1024 patch remains 1:1 and extends south beyond the initial view.
- Real `Operator`, gameplay `Camera2D`, `PlayerController`, and `LevelPlaytestBootstrap` are instantiated through the Kenney standalone playtest pattern.
- Modes: 1 neutral blockout; 2 four original adjacent crops; 3 repeated NW crop diagnostic. `Tab` switches 1/2; `1`, `2`, and `3` select each mode directly. Presentation changes leave player, camera, collision and navigation ownership unchanged.
- A scene-lifetime setting disables the otherwise injected VaultManager debug chest and restores its previous value when the test level exits.
- Implementation commit: `1881a21ab1aa193e414d738a68dc37f7fbb0de9e` (`sepulcher paving, native quad playtest [skip render]`).

## Source and crops

- Dropbox ZIP: `/CUSTODIAN/implementation_inputs/custodian_sepulcher_paving_native_quad_preview_v1_20261101.zip`; SHA-256 `1172e3e78741f0f18285dbbb50e40fd9e496470d84b1ec02f075bb7ff1d29344`.
- Master: 1254×1254 RGB; SHA-256 `62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf`.
- Published source-staging tool staged only the unchanged unapproved master in `asset_drop/source_work/.../paving_base_source.png` during execution.
- Published crop tool produced only the four fixed 512×512 crops: NW `(128,128)-(640,640)`, NE `(640,128)-(1152,640)`, SW `(128,640)-(640,1152)`, SE `(640,640)-(1152,1152)`. Their 1024×1024 reassembly matched the source master region pixel-for-pixel.
- Four crop images are Git LFS tracked; `git lfs fsck --objects --pointers HEAD^..HEAD` passed. The original master and QA reconstruction image are not in the implementation commit. No Asset V2 source, family, inbox or approval was created.

## Validation

- `python3 custodian/tools/art/sepulcher_paving_native_quad.py --self-test` — PASS.
- Source staging and crop generation — PASS; exact SHA, RGB mode/dimensions, four native crops, reconstruction equality.
- `godot --headless --path custodian --script res://tools/validation/levels/sepulcher_modular_material_pilot_smoke.gd` — PASS; verifies real Operator movement, three mode visibility, exact crop textures/positions, unchanged camera/collision and mode keys.
- `godot --headless --path custodian --script res://tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd` — PASS.
- Three real Godot viewport captures were rendered under Xvfb/OpenGL from the same fixed Operator position and frozen normal gameplay-camera transform/zoom.
- The normal `NavigationSystem` emits its existing “No floor tilemap found” warning because this movement-focused sandbox has an empty `NavigationRoot`; Operator movement and the scene smoke pass.
- Final changed-file validation and `git diff --check` are recorded in the workstream finish report.

## Visual review evidence

- Manifest: `/CUSTODIAN/visual_review/sepulcher-paving-native-quad-playtest-v1/20261101T111040Z/REVIEW_MANIFEST.json`
- Captures: `sepulcher_mode_1_blockout.png`, `sepulcher_mode_2_native_quad.png`, `sepulcher_mode_3_repeat_nw_diagnostic.png` (all 1280×720).
- Review questions:
  1. Is the original masonry detail legible at real Operator gameplay scale?
  2. Do the 1024×1024 floor patch proportions suit the Operator in the 1024×768 gameplay region?
  3. Does the repeated NW diagnostic reveal unacceptable repetition or outer seam risk for a future tile?
- Dropbox retention is `delete-after-review`. After the user/ChatGPT records a decision, run: `python3 custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest /CUSTODIAN/visual_review/sepulcher-paving-native-quad-playtest-v1/20261101T111040Z/REVIEW_MANIFEST.json --reviewed-by chatgpt-user`.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `The pinned source, exact native crops, pixel reconstruction, scene behaviors, movement, LFS objects and three matched camera captures are verified above. The source remains unapproved; aesthetics and production tileability are not claimed.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The initial full-LFS claim checkout took extra time; retries correctly waited while its dispatcher lock and checkout remained active. The first Godot smoke also ran before the new worktree's global-class cache was populated.`
- Root cause / contributing factors: `The dispatcher provisioned a full LFS checkout, and a new worktree needs one Godot editor scan before script-based validation.`
- Prevention / pipeline improvement: `Allow the original claim process to finish before retrying; perform one editor import/class scan on a fresh checkout before Godot script smoke.`
- Tooling / docs drift discovered: `The validation runner had no owner registration for the new focused smoke; `custodian/tools/validation/validation_manifest.json` now registers the smoke and capture helper.`
- Follow-up: `none`
- What worked: `The SHA-guarded source and fixed crop scripts stayed within the unapproved source_work/dev-preview boundaries.`

## Next Handoff

- Next workstream: `review-sepulcher-paving-native-quad-playtest-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none`
- Next action: `After implementation lands, run the published fresh-context paired review and return the visual-review manifest/questions for the human art decision. Do not advance to pilot asset 2.`
- Blockers or open questions: `Subjective masonry detail, Operator scale, floor proportions, and repeat/seam acceptability remain human-owned visual questions; paired technical review is still required.`

Authoring chat: not-recorded
