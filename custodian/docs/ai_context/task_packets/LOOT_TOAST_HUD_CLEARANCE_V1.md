# LOOT TOAST HUD CLEARANCE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `loot-toast-hud-clearance-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `hud-top-left-layout, loot-toast-queue`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-loot-toast-hud-clearance-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `the bug is visually simple but the fix changes live HUD layout ownership and should be independently checked across visibility states and viewport sizes`
- Reviewed main: `cf03b238416fb06c71a4af946242eb9ccf58228a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `conditional`
- Goal: Keep loot/pickup toasts readable and non-overlapping with the live top-left gameplay HUD by replacing the queue's stale fixed Y assumption with one narrow runtime clearance contract derived from the currently visible HUD footprint.
- Completion boundary: Done when `LootToastQueue` still owns toast queueing/merge/animation, the main HUD exposes or supplies one read-only top-left clearance boundary, the toast queue positions itself below that boundary with a small gap and viewport clamp, hidden HUD controls stop reserving space, terminal/HUD suppression does not strand the queue at a stale position, the four-entry stack remains on-screen at supported desktop sizes, existing pickup producers require no changes, and focused layout/queue validation passes.
- Current measured state:
  - Human gameplay on 2026-10-09 reported pickup toasts being visually blocked by/overlapping the health/stamina HUD.
  - `loot_toast_queue.tscn` hard-codes the queue rectangle to `left=18, top=126, right=338, bottom=390`.
  - `game.tscn` mounts `LootToastQueue` directly beneath the `UI` CanvasLayer as a sibling of the legacy gameplay HUD controls.
  - The same `UI` CanvasLayer contains top-left HUD controls whose authored bottoms range well past that fixed toast anchor: `StaminaLabel/Bar`, `LivesLabel`, `ContractPhaseLabel`/Ammo/FieldPatch, camera/zoom/time/aim/loadout rows, the primary-weapon button, cooldown row and optional Director/Supply rows. Runtime `ui.gd` already owns which of these are visible in normal/debug/terminal states.
  - Existing `loot_toast_queue_smoke.gd` proves registration, merge and producer behavior but does not assert screen geometry or HUD clearance.
  - `design/02_features/ui/LOOT_PICKUP_FEEDBACK.md` still declares a fixed `(18,126)` runtime contract, which is now stale against the live HUD.
- Evidence:
  - human playtest screenshots/report in the Authoring chat;
  - `custodian/game/ui/loot/loot_toast_queue.gd`;
  - `custodian/game/ui/loot/loot_toast_queue.tscn`;
  - `custodian/scenes/game.tscn`;
  - `custodian/game/ui/hud/ui.gd`;
  - `custodian/tools/validation/loot_toast_queue_smoke.gd`;
  - `design/02_features/ui/LOOT_PICKUP_FEEDBACK.md`;
  - `custodian/docs/ai_context/CURRENT_STATE.md`.
- Task-specific authority:
  - `LootToastQueue` remains the single toast queue/merge/animation owner.
  - `ui.gd` / the live HUD owns normal gameplay-control visibility and is the correct source for the currently occupied top-left HUD footprint.
  - Pickup producers continue to communicate only through the `loot_toast_queue` group and `push_pickup(...)`; they do not learn HUD geometry.
- Work surface:
  - Expected edits:
    - `custodian/game/ui/loot/loot_toast_queue.gd`
    - `custodian/game/ui/loot/loot_toast_queue.tscn`
    - `custodian/game/ui/hud/ui.gd`
    - `custodian/scenes/game.tscn` only if an explicit NodePath/provider binding is cleaner than sibling discovery
    - `custodian/tools/validation/loot_toast_queue_smoke.gd`
    - `custodian/tools/validation/validation_manifest.json` only if ownership needs to include `ui.gd`/`game.tscn`
    - `design/02_features/ui/LOOT_PICKUP_FEEDBACK.md`
    - concise directly stale `CURRENT_STATE.md` / `FILE_INDEX.md` entries if their fixed-placement wording changes.
  - Do not touch pickup producer scripts unless live inspection proves one bypasses the queue contract.
- Change:
  1. Keep the queue's horizontal placement and 320 px presentation width unless live viewport constraints require the existing component to shrink at very small supported widths. This packet is primarily a vertical-clearance correction.
  2. Add one narrow read-only top-left HUD-clearance contract. Preferred shape: `ui.gd` computes the maximum bottom edge of currently visible, ordinary top-left gameplay controls and exposes that value/rect to the toast queue. The computation must use the actual visible `Control` rectangles rather than duplicating authored Y constants in a second list of magic numbers.
  3. The provider must ignore hidden controls. Normal essentials-only HUD should reserve only what is actually visible; enabling optional/debug rows may push the toast stack down; opening the terminal or suppressing the gameplay HUD must not leave an old large clearance cached after those controls disappear.
  4. Let `LootToastQueue` consume that boundary and place its own top at `max(fallback_top, hud_bottom + gap)`. Initial gap target: 10-12 px. Keep the component presentation-only and do not make inventory/pickup authorities depend on HUD state.
  5. Refresh clearance at deterministic UI transition points and before presenting a newly pushed toast. Also respond to viewport-size changes. Do not poll the entire UI tree every frame.
  6. Clamp the toast stack to the viewport. With the current 4-entry maximum and 52 px entries / 6 px separation, all visible entries must remain on-screen at least at 1280x720 and 1600x900. If available vertical room is temporarily insufficient, prefer placing the stack in the nearest non-overlapping top-left region and preserving all four entries; do not silently drop pickups or change queue semantics.
  7. Avoid generic recursive collision solving across every HUD control. This is a top-left HUD contract, not a new layout engine. Use the existing live HUD owner/provider seam.
  8. Extend `loot_toast_queue_smoke.gd` with geometry fixtures:
     - essentials-only visible HUD -> first toast begins below the occupied HUD + gap;
     - one lower optional/debug top-left control visible -> toast moves down;
     - that control hidden -> toast moves back up without stale clearance;
     - viewport resize preserves horizontal inset and keeps four entries on-screen;
     - queue merge/quantity/category behavior remains unchanged.
  9. Add one integration assertion against `game.tscn` or a minimal UI fixture proving the production `LootToastQueue` is bound to the live HUD-clearance provider, rather than a smoke-only mock.
  10. Update `LOOT_PICKUP_FEEDBACK.md` from the obsolete fixed `(18,126)` claim to the dynamic top-left-clearance contract, retaining the current queue size, merge window and animation timing unless implementation evidence requires a directly related correction.
- Preserve:
  - `push_pickup(item_id, display_name, quantity, accent, icon, detail)` public contract;
  - max four visible entries;
  - same-item 0.75 s merge behavior;
  - 0.12 s enter / 1.80 s hold / 0.25 s exit timing;
  - existing world-space floating pickup feedback;
  - terminal/gameplay HUD visibility authority;
  - inventory/resource/ammo/Field Patch/vault ownership.
- Non-goals:
  - no full HUD redesign;
  - no Black Reliquary style pass;
  - no relocation to another screen corner unless the supported viewport makes top-left clearance impossible;
  - no pickup producer refactor;
  - no inventory semantics change;
  - no new art.
- Acceptance:
  1. In the production `game.tscn` HUD, the toast queue never intersects the currently visible top-left gameplay HUD rectangle.
  2. Hidden top-left controls do not reserve toast space.
  3. Toggling HUD/debug/terminal visibility cannot strand the queue at stale clearance.
  4. Four entries fit on-screen at 1280x720 and 1600x900 with the current 320x52 presentation contract.
  5. Horizontal inset remains visually consistent with the current 18 px left target unless viewport clamping requires a documented adjustment.
  6. No per-frame whole-UI scan is introduced.
  7. Existing merge/quantity/category/producer behavior passes unchanged.
  8. The production scene is actually wired to the provider contract; the fix is not fixture-only.
  9. The design doc no longer claims fixed `(18,126)` positioning.
- Validation:
  - Run `loot_toast_queue_smoke` first with the new layout cases.
  - Run any existing HUD visibility/compact/debug smoke selected by `ui.gd` / `game.tscn` ownership.
  - Run `pause_only_minimap_hud_smoke` if changed-file ownership selects or the provider touches shared HUD visibility behavior.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
  - Visual evidence is optional if geometry assertions prove non-overlap. If objective checks cannot establish production placement, publish at most one compact screenshot/contact-sheet handoff to `/CUSTODIAN/visual_review/loot-toast-hud-clearance-v1/` with the exact Authoring chat and ask only whether the toast stack is visually clear of the top-left HUD.
- Task overrides: `none`
- Deferred:
  - broader normal-HUD hierarchy/mental-load redesign;
  - any separate cleanup of legacy debug labels in `game.tscn`;
  - Archive Resolve presentation findings are owned by `procgen-archive-resolve-playtest-polish-v1`.

## Context Pack

- Repomix: `none`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `the fixed toast top=126 placement contract is superseded by live HUD-derived clearance; toast queue semantics remain unchanged`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `the toast scene hard-coded a Y anchor that no longer matches the live HUD footprint`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `layout smoke owns real HUD clearance instead of only queue semantics`
- Tooling / docs drift discovered: `LOOT_PICKUP_FEEDBACK.md still claims fixed (18,126) placement`
- Follow-up: `paired fresh-context review`
- What worked: `the centralized queue/group contract means the repair can stay inside UI presentation without touching pickup producers`

## Handoff

- Next workstream: `review-loot-toast-hud-clearance-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `After implementation lands, claim the fresh-context paired review.`
- Blockers or open questions: `none`
