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
- Goal: Complete the 1464×1074 Crèche room cutover with authored walkability and one functional independently rendered console.
- Completion boundary: `Atomic family/inbox/Asset V2 scene cutover for both 1464×1074 Crèche room plates; measured Zone01 collision and 01→02 passage; independently rendered approved 128×128 console with preserved 8-frame 8FPS screen FX and interaction; real Godot validation and in-game capture for direct user/ChatGPT visual review.`
- Current measured state: `Source-only Crèche clean room workstream archived complete at origin/main 0e6b081b18a8b2d9deed0a19157a7a4b376adbb5; approved 1464×1074 RGBA masters exist under Git LFS but both inbox files are absent, family and scene remain 960×704, and Zone01 walkable floor remains 704×512. Existing 128×128 console idle artwork was approved by the user, but its placement in the larger room remains untested.`
- Evidence: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`; `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`; `design/04_architecture/AWAKENING_CRECHE_FLOOR_1464X1074_CANONICAL_V1.md`; `custodian/content/metadata/assets/families/awakening_creche_environment.asset.json`; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png`.
- Task-specific authority: `Asset V2 governs source/inbox/family/ingest, AwakeningLayout governs geometry and collision, AwakeningFirstReturn and existing CrecheConsole govern visual presentation and gameplay. User source-art approvals do not imply final in-game fit. Preserve already accepted original interaction and source identities.`
- Work surface: `custodian/content/metadata/assets/families/awakening_creche_environment.asset.json`; `custodian/asset_drop/inbox/awakening_creche_environment/underlay.png`; `custodian/asset_drop/inbox/awakening_creche_environment/foreground.png`; Asset V2-generated Crèche runtime plates/catalog/receipts; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; existing console scene binding, focused smokes and post-cutover design/current-state docs.
- Change: `1. Verify hydrated source masters and LFS SHA-256 floor 9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a and foreground 515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc with rollback from custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md. 2. Update the existing awakening_creche_environment family canvas and BOTH single-frame states from 960×704 to 1464×1074; do not change family id/kind/domain/owner. 3. Stage exact byte-identical RGBA copies as inbox/underlay.png and inbox/foreground.png, then run asset.py plan with actual nonzero source/output counts, guarded --replace ingest, status/doctor, catalog and Godot import checks. 4. Swap the existing Crèche Underlay and Foreground scene resources together, measuring position from the floor, passage and console, preserving z-order and occlusion; no temporary floor-only deployment. 5. Replace Zone01 floor rect with author-measured walkable geometry and appropriate zone envelope; preserve 32px physics conventions, exclude transparent void and keep CONNECTORS["01_02"] 128px wide and traversable both directions. 6. Render one existing user-approved 128×128 console idle hero 01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb as a Sprite2D at measured pivot; preserve ScreenAnchor and the original eight 128×128 FX frames at eight FPS, plus first-use/repeat/reset; remove stale baked-source metadata only when independent console is visible. 7. Run real Godot geometry, collision mapper, art registration, progression, screen-anchor and full First Return smokes; capture gameplay-scale Operator wake, console and north passage/return. 8. Update current runtime size in design manifest, CURRENT_STATE and scene documentation only after implementation; present capture evidence for direct human visual approval and leave truthful pending review if not yet accepted.`
- Preserve: `Original 960×704 runtime/LFS and current 1464×1074 approved source LFS rollback anchors; existing CrecheConsole gameplay owner and interaction at (112,144); Operator wake (0,160); active alcove (0,208); original screen-local activation logic (8 frames at 8FPS); 128px 01→02 passage; other Awakening zones, global Operator scale, and operator root checkout with local modifications.`
- Non-goals: `No new console art generation or art approval prerequisite, no second gameplay console, no paired Codex reviewer, no Undergate/Port work, no runtime PNG direct overwrite outside Asset V2, no treating full alpha canvas as walkable, no force-push or root checkout reset.`
- Acceptance: `Exact source SHA parity in inbox and Asset V2 receipts, both 1464×1074 states genuinely imported and bound in Godot, traversable Zone01 with protected north/return route and no transparent-void collision, independently rendered unique approved console body and correct screen FX/first/repeat/reset, named Godot tests green, and explicit user/ChatGPT gameplay-scale visual verdict before asserting artistic completion.`
- Validation: `python3 custodian/tools/assets/asset.py plan awakening_creche_environment --json`; guarded `ingest awakening_creche_environment --replace --yes`; `status awakening_creche_environment --json`; `doctor --json`; `custodian/tools/validation/awakening_first_return_geometry_smoke.gd`; `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`; `custodian/tools/validation/awakening_art_registration_smoke.gd`; `custodian/tools/validation/awakening_first_return_progression_smoke.gd`; `custodian/tools/validation/awakening_creche_console_screen_anchor_smoke.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; LFS hydrated hashes/import/rollback, room collision negative tests, `git diff --check`, task packet/index/context and changed-file Asset Pipeline V2 validations.
- Task overrides: `none`
- Deferred: `Other Awakening/Undergate/Port workstreams and any bounded art corrections requested after real game-scale review.`

## Approved source and existing console hero

The predecessor `awakening-interactible-clean-room-plates-v1` is archived **complete** on `origin/main@0e6b081b18a8b2d9deed0a19157a7a4b376adbb5`. The exact approved one-frame 1464×1074 RGBA masters are:

- Floor `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png`: Git LFS `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`.
- Foreground `custodian/asset_drop/source_work/awakening/awakening_creche_environment/foreground_source.png`: Git LFS `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`.
- Source registration, alpha extents and previous-source rollback: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`.

The existing **128×128 one-frame console idle artwork** at `custodian/content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png` has LFS `01716bcdf4a3d7169e52149f495f91830106df93f94736e3c2aee8d910a30acb`; the user explicitly reviewed and approved that artwork in this authoring chat on 2026-11-06. Reuse the existing production texture, with no new console art or separate human source approval gate. **This does not approve the untested in-game scene composition.**

The prior Asset V2 plan `can_apply=true/source_count=0/output_count=0` saw no inbox and was not a 1464×1074 compatibility failure. This workstream owns both inbox files, both family states, the guarded nonempty plan and ingest, the two scene layers, matching world-space navigation and the independent console. The old baked-console underlay must not coexist with a second body. Use existing scene `CrecheConsoleBody/ScreenAnchor` as the anchor authority and preserve first interaction, repeat and reset.

## Direct review and dispatcher authority

The user waived a separate Codex paired reviewer **for this Crèche slice only**. Human/ChatGPT inspected the new gameplay captures and approved gameplay presentation; the newest connector/destination frame was not independently inspected at full resolution. Objective technical tests remain mandatory. This direct review is recorded in `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_RUNTIME_VERIFICATION_20261110.json`. Do not overstate the pixel-inspection limitation or override packet-validation checks.

The existing source-preparation workstream is archived complete; no missing source publication or new hero input is required. This packet is promoted to `ready/auto`; no claim, lock, new worktree, asset ingestion, runtime or Git LFS modification is performed by this packet-authoring change. Use `dispatch.py audit --json` to verify current eligible/unclaimed status and then `dispatch.py claim awakening-creche-console-sprite-reauthor-v1 --agent codex`; do not use `workstream.py start`.

Update `design/04_architecture/AWAKENING_FIRST_RETURN.md`, `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`, `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`, `custodian/docs/ai_context/CURRENT_STATE.md` and generated asset records only after actual Godot runtime production truth changes. Preserve the user's persistent root checkout, which is on a separate branch with local changes.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes; the approved 1464×1074 Crèche cutover, console presentation, trigger fix and truthful Asset V2 runtime verification are implemented on the claimed branch`
- Completion boundary satisfied: `yes; actual scene, import, gameplay/FX capture, live traversal and direct gameplay-scale review evidence are recorded`
- Acceptance satisfied: `yes, with the recorded limitation that the newest connector/destination frame was not independently inspected at full resolution`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `Asset V2 job job_20261110T003455Z_2cfe3ce7; custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_RUNTIME_VERIFICATION_20261110.json; reports/awakening_creche_gameplay_review/live_traversal_result.json; awakening_creche_runtime_asset_contract PASS; asset.py needs --check PASS; ChatGPT/user gameplay approval. Branch publication/landing remains pending normal GitHub CI.`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial; implementation and acceptance evidence are complete, supported checkpoint and main landing remain pending`
- Friction severity: `low`
- What went wrong: `The V2 checkpoint is blocked by 20,064 unresolved ignored paths; Asset V2 doctor also reports four unrelated designation-locker catalog hash mismatches.`
- Root cause / contributing factors: `Dispatcher V2 does not consume the verified external ignored-file archive as a checkpoint preservation receipt; the locker hashes are outside this workstream and were preserved unchanged.`
- Prevention / pipeline improvement: `Keep runtime verification scoped to exact source/runtime/scene/traversal evidence; preserve the Asset V2 doctor exceptions as separately owned baseline data; keep this one-time branch-publication exception scoped to the existing Crèche task.`
- Tooling / docs drift discovered: `After ingest, the read-only Asset V2 plan correctly reports zero inbox sources/outputs; successful import and status are established by the job receipt and status, not by an empty plan.`
- Follow-up: `publish only the curated Crèche task commit to the existing agent branch under the owner’s one-time authorization; retain the checkout; obtain a separate owner decision before any main landing`
- What worked: `Existing approved sources and console art were reused, the live traversal found the early-trigger bug, and direct ChatGPT/user review approved the final gameplay presentation.`

## Next Handoff
- Next workstream: `none`
- Next packet state: `owner-authorized agent-branch publication; main landing remains separately gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none; direct gameplay presentation approval is recorded with its full-resolution limitation`
- Next action: `Curate and publish the task-owned commit to agent/awakening-creche-console-sprite-reauthor-v1 using the owner’s one-time branch-only authorization; verify the exact remote SHA and keep this checkout. Main landing, V2 checkpoint completion, and checkout retirement are not authorized by that decision.`
- Blockers or open questions: `20,064 ignored paths still prevent the canonical V2 checkpoint; the verified host-local preservation manifest does not clear that guard. Asset V2 doctor retains four unrelated awakening_designation_locker hash mismatches.`
