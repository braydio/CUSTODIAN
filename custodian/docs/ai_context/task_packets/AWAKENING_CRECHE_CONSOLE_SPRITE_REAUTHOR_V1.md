# AWAKENING CRÈCHE CONSOLE SPRITE REAUTHOR V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-creche-console-sprite-reauthor-v1`
- Category: `assets-art`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-awakening-creche-console-idle-fx-binding-v1, awakening-interactible-clean-room-plates-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `User-authorized Crèche-only exception from paired Codex review; objective testing and direct user/ChatGPT runtime visual approval remain required`
- Reviewed main: `0e6b081b18a8b2d9deed0a19157a7a4b376adbb5`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `required`
- Publication inputs: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png`; `custodian/asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png`; `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`; `custodian/content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png`
- Goal: Complete the 960×704 Crèche room reauthor cutover with authored walkability and one functional independently rendered console.
- Completion boundary: `Atomic family/inbox/Asset V2 scene cutover for both 960×704 Crèche room plates; measured Zone01 collision and the south/east 01→02 return passage; independently rendered approved 128×128 console with preserved 8-frame 8FPS screen FX and interaction; real Godot validation and in-game capture for direct user/ChatGPT visual review.`
- Current measured state: `The source-only Crèche clean-room workstream is archived complete; the previous 1464×1074 masters are retained for rollback and the newly supplied 960×704 pair is installed as a candidate. Asset V2 job `job_20261107T092214Z_0e12dbae` completed, focused geometry/registration/console/progression/mapper and real Operator round-trip smokes pass, and the A/B review handoff is published. Direct user/ChatGPT gameplay-scale approval remains pending; keep this workstream open. The existing 128×128 console idle art are published. The original cutover and console presentation are implemented on this active claimed branch. A subsequent visual review approved the room composition and southern exit, then directed a south/east route correction; that correction is now in progress on this branch and requires focused validation plus another direct visual review. origin/main remains the previous landed baseline until this workstream completes its gates.`
- Evidence: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`; `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`; `design/04_architecture/AWAKENING_CRECHE_FLOOR_1464X1074_CANONICAL_V1.md`; `custodian/content/metadata/assets/families/awakening_creche_environment.asset.json`; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png`.
- Task-specific authority: `Asset V2 governs source/inbox/family/ingest, AwakeningLayout governs geometry and collision, AwakeningFirstReturn and existing CrecheConsole govern visual presentation and gameplay. User source-art approvals do not imply final in-game fit. Preserve already accepted original interaction and source identities.`
- Work surface: `custodian/content/metadata/assets/families/awakening_creche_environment.asset.json`; `custodian/asset_drop/inbox/awakening_creche_environment/underlay.png`; `custodian/asset_drop/inbox/awakening_creche_environment/foreground.png`; Asset V2-generated Crèche runtime plates/catalog/receipts; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; existing console scene binding, focused smokes and post-cutover design/current-state docs.
- Change: `1. Verify hydrated source masters and LFS SHA-256 floor 9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a and foreground 515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc with rollback from custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md. Verify the newly supplied source hashes and dimensions against custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_960_CANDIDATE_CUTOVER_20261107.md. 2. Update the existing awakening_creche_environment family canvas and BOTH single-frame states to 960×704; do not change family id/kind/domain/owner. 3. Stage exact byte-identical RGBA copies as inbox/underlay.png and inbox/foreground.png, then run asset.py plan with actual nonzero source/output counts, guarded --replace ingest, status/doctor, catalog and Godot import checks. 4. Swap the existing Crèche Underlay and Foreground scene resources together, measuring position from the floor, passage and console, preserving z-order and occlusion; no temporary floor-only deployment. 5. Replace Zone01 floor rect with author-measured walkable geometry and the updated zone envelope; preserve 32px physics conventions and exclude transparent void. Close the old north route and use these authored rectangles for the south/east 01→02 route: doorway Rect2(-64,288,128,128), south spine Rect2(-64,384,128,192), south court Rect2(-64,480,1024,128), east return Rect2(832,-768,128,1376), east approach Rect2(544,-768,416,128), and connector Rect2(448,-768,128,128). Generate physical boundaries from that union, extend WORLD_BOUNDS to Rect2(-1088,-7328,2176,8000), and walk (0,352)→(0,544)→(896,544)→(896,-704)→(416,-704) and back with the real Operator. 6. Render one existing user-approved 128×128 console idle hero 01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb as a Sprite2D at measured pivot; preserve ScreenAnchor and the original eight 128×128 FX frames at eight FPS, plus first-use/repeat/reset; remove stale baked-source metadata only when independent console is visible. 7. Run real Godot geometry, collision mapper, art registration, progression, screen-anchor and full First Return smokes; capture gameplay-scale Operator wake, console, south doorway, exterior return and eastern Ambulatory arrival. 8. Update current runtime size in design manifest, CURRENT_STATE and scene documentation only after implementation; present capture evidence for direct human visual approval and leave truthful pending review if not yet accepted.`
- Preserve: `Previous 1464×1074 source LFS rollback anchors and new 960×704 canonical source identities; existing CrecheConsole gameplay owner and interaction at (112,144); Operator wake (0,160); active alcove (0,208); original screen-local activation logic (8 frames at 8FPS); 128px 01→02 passage; approved southern doorway and south/east corridor geometry; other Awakening zones, global Operator scale, and operator root checkout with local modifications.`
- Non-goals: `No new console art generation or art approval prerequisite, no second gameplay console, no paired Codex reviewer, no Undergate/Port work, no runtime PNG direct overwrite outside Asset V2, no treating full alpha canvas as walkable, no force-push or root checkout reset.`
- Acceptance: `Exact source SHA parity in inbox and Asset V2 receipts, both 960×704 states genuinely imported and bound in Godot, traversable Zone01 with the old north route blocked, bidirectional south/east connection, physical exterior boundaries and no transparent-void shortcut, independently rendered unique approved console body and correct screen FX/first/repeat/reset, named Godot tests green, and explicit user/ChatGPT gameplay-scale visual verdict before asserting artistic completion.`
- Validation: `python3 custodian/tools/assets/asset.py plan awakening_creche_environment --json`; guarded `ingest awakening_creche_environment --replace --yes`; `status awakening_creche_environment --json`; `doctor --json`; `custodian/tools/validation/awakening_first_return_geometry_smoke.gd`; `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`; `custodian/tools/validation/awakening_art_registration_smoke.gd`; `custodian/tools/validation/awakening_first_return_progression_smoke.gd`; `custodian/tools/validation/awakening_creche_console_screen_anchor_smoke.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; LFS hydrated hashes/import/rollback, room collision negative tests, `git diff --check`, task packet/index/context and changed-file Asset Pipeline V2 validations.
- Task overrides: `none`
- Deferred: `Other Awakening/Undergate/Port workstreams and any bounded art corrections requested after real game-scale review.`

## Approved source and existing console hero

The predecessor `awakening-interactible-clean-room-plates-v1` is archived **complete** on `origin/main@0e6b081b18a8b2d9deed0a19157a7a4b376adbb5`. The previous one-frame 1464×1074 RGBA masters are retained rollback identities. The current approved source identity is recorded in the 2026-11-07 candidate cutover receipt:

- Floor `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png`: Git LFS `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`.
- Foreground `custodian/asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png`: Git LFS `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`.
- Source registration, alpha extents and previous-source rollback: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`.

The existing **128×128 one-frame console idle artwork** at `custodian/content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png` has LFS `01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb`; the user explicitly reviewed and approved that artwork in this authoring chat on 2026-11-06. Reuse the existing production texture, with no new console art or separate human source approval gate. **This does not approve the untested in-game scene composition.**

The prior empty Asset V2 plan saw no inbox; the current nonempty 960×704 plan and guarded replacement job are recorded in the candidate cutover receipt. This workstream owns both inbox files, both family states, the guarded nonempty plan and ingest, the two scene layers, matching world-space navigation and the independent console. The old baked-console underlay must not coexist with a second body. Use existing scene `CrecheConsoleBody/ScreenAnchor` as the anchor authority and preserve first interaction, repeat and reset.

## Direct review and dispatcher authority

The user waived a separate Codex paired reviewer **for this Crèche slice only**. Human/ChatGPT must still inspect actual new Godot gameplay captures, and objective technical tests remain mandatory. `Visual review: required` is not fulfilled by prior approval of the standalone console sprite. If final in-engine visual review has not been given, record it as pending, not passed. Do not fabricate completion or override packet-validation checks.

The existing source-preparation workstream is archived complete; no missing source publication or new hero input is required. This packet is promoted to `ready/auto`; no claim, lock, new worktree, asset ingestion, runtime or Git LFS modification is performed by this packet-authoring change. Use `dispatch.py audit --json` to verify current eligible/unclaimed status and then `dispatch.py claim awakening-creche-console-sprite-reauthor-v1 --agent codex`; do not use `workstream.py start`.

Update `design/04_architecture/AWAKENING_FIRST_RETURN.md`, `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`, `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`, `custodian/docs/ai_context/CURRENT_STATE.md` and generated asset records only after actual Godot runtime production truth changes. Preserve the user's persistent root checkout, which is on a separate branch with local changes.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `direct-user-chatgpt-game-scale-visual-verdict`
- What worked: `<fill at closeout>`

## Next Handoff
- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Validate and review actual new Crèche gameplay screenshot/FX with the user and ChatGPT, after technical implementation`
- Next action: `Post normal gameplay-scale captures and measured validation to this chat; request explicit final scene visual verdict`
- Blockers or open questions: `No source/hero blocker remains; runtime work and final in-game visual validation are next`
