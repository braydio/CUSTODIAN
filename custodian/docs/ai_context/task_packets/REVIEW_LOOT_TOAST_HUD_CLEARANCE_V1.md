# REVIEW LOOT TOAST HUD CLEARANCE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-loot-toast-hud-clearance-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `loot-toast-hud-clearance-v1`
- Locks: `hud-top-left-layout, loot-toast-queue`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `paired fresh-context verification of live HUD geometry, visibility-state transitions and queue semantics; this review packet itself does not spawn another paired review`
- Review target workstream: `loot-toast-hud-clearance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/LOOT_TOAST_HUD_CLEARANCE_V1.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify that the production loot-toast queue clears the actual visible top-left HUD across normal/debug/terminal/viewport states without changing pickup semantics or creating a generic layout engine.
- Completion boundary: Pass only when a fresh reviewer proves the production scene is wired to a live HUD-clearance provider, hidden controls do not reserve space, transitions cannot leave stale geometry, four entries stay on-screen at required desktop sizes, queue semantics remain unchanged, and no per-frame whole-UI scan or pickup-authority coupling was introduced.
- Current measured state: Reconstruct from landed main at claim time. The pre-fix baseline is the human playtest where pickup toasts visually collide with the health/stamina HUD while `LootToastQueue` is fixed at top 126.
- Evidence:
  - archived implementation packet and closing summary for `loot-toast-hud-clearance-v1`;
  - `custodian/game/ui/loot/loot_toast_queue.gd` / `.tscn`;
  - live HUD provider implementation;
  - `custodian/scenes/game.tscn`;
  - extended `loot_toast_queue_smoke.gd`;
  - directly affected HUD visibility regressions;
  - updated `LOOT_PICKUP_FEEDBACK.md`.
- Task-specific authority: `LootToastQueue` owns toast queue state/presentation; the existing main HUD owner owns visible top-left HUD geometry; producers remain geometry-agnostic.
- Work surface: Review only landed implementation/evidence and bounded correction metadata if a finding is confirmed. Do not edit reviewed implementation code.
- Change:
  1. Verify the clearance provider uses actual visible Control geometry, not copied Y constants or a manually duplicated list that will immediately drift.
  2. Verify production `game.tscn` actually binds/uses the provider path; fixture-only behavior is a finding.
  3. Check normal essentials HUD, lower optional/debug row enabled, row hidden again, terminal/HUD suppression, and viewport resize. Require the queue to move both down and back up as visibility changes.
  4. Check four-entry stack bounds at 1280x720 and 1600x900.
  5. Verify queue merge, quantity aggregation, category separation, timings and producer API remain unchanged.
  6. Confirm refresh is transition/event driven or otherwise bounded; a full UI-tree scan every frame is a finding.
  7. If the implementation publishes conditional visual evidence, verify it supports geometry only; do not invent an aesthetic preference finding from an otherwise passing layout.
- Preserve: existing pickup producer contract, queue semantics/timings, terminal/HUD visibility authority, inventory/resource/ammo/consumable ownership.
- Non-goals: No broad HUD redesign, no producer refactor, no new art, no unrelated debug-label cleanup.
- Acceptance:
  - no production overlap with visible top-left HUD controls;
  - hidden controls reserve no clearance;
  - terminal/debug/visibility transitions do not leave stale positioning;
  - four entries remain on-screen at required desktop viewports;
  - no per-frame whole-tree layout search;
  - producer/merge/timing semantics unchanged;
  - updated design doc matches runtime truth;
  - focused and changed-file validation pass with no material evidence gap.
- Validation:
  - `loot_toast_queue_smoke`
  - directly affected HUD visibility/compact/debug owners selected by the manifest
  - `pause_only_minimap_hud_smoke` if applicable
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `git diff --check`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Broader HUD hierarchy/readability work remains separate.

## Review Receipt

- Status: `pending`
- Review target workstream: `loot-toast-hud-clearance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/LOOT_TOAST_HUD_CLEARANCE_V1.md`
- Reviewed main: `<fill at review>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_LOOT_TOAST_HUD_CLEARANCE_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `If passed, close the HUD-clearance defect. If findings exist, author only bounded corrections tied to those findings.`
- Blockers or open questions: `implementation dependency only`
