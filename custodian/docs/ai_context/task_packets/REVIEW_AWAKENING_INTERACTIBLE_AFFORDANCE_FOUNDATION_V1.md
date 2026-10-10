# REVIEW AWAKENING INTERACTIBLE AFFORDANCE FOUNDATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-interactible-affordance-foundation-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `awakening-interactible-affordance-foundation-v1`
- Locks: `awakening-interaction-presentation`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review target workstream: `awakening-interactible-affordance-foundation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_AFFORDANCE_FOUNDATION_V1.md`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Goal: Independently verify that a single presenter can mount affordance parts on the four real Awakening interaction owners while preserving Operator/HUD targeting and distinguishing every genuine interactible from inert Layout markers.
- Completion boundary: The reviewer must inspect actual production scene/marker/runtime mapping, prove absent-art no-op and no separate gameplay authority, reproduce the parity smoke and current progression checks, and find no material evidence gap.
- Current measured state: Implementation dependency not yet landed. The pre-fix baseline is the prompt-only Crèche terminal and Layout `lift_mechanism` marker listed as interactible without a standalone runtime control.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; archived foundation packet; implementation summary; live Layout/first-return/P-9/lift/HUD files and focused tests.
- Task-specific authority: Layout marker/spatial authority, each existing interactible node's gameplay contract and Operator/HUD target selection.
- Work surface: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; new presenter script; `custodian/scenes/awakening_first_return.tscn`; new parity smoke; existing progression/lift/locker smokes.
- Change:
  1. Rebuild the real marker/owner inventory on current main, including both lift station anchors, P-9 as a scene instance, the Crèche/Port plaque nodes, and false/out-of-scope markers.
  2. Verify presenters only consume/read gameplay owner state, never register extra gameplay targets or change `get_interaction_prompt()` / `get_interaction_position()` authority.
  3. Prove all new visual mounting nodes are no-collision/no-navigation, additive and idempotent at startup/debug reset, and absence of ungenerated images causes no error spam or hidden fallback lies.
  4. Require a negative regression: no available interaction owner -> no active focus beacon or prompt, even if the marker is visible.
  5. Re-run focused marker/owner and real Awakening progression/lift/locker/geometry tests; distinguish unrelated baseline failures rather than waiving required checks.
- Preserve: Locked 04→05 composition, 05→06 passage, registered P-9 art, Crèche acknowledgement, Port readout, lift controls, Gate sealed state and HUD target priority.
- Non-goals: No artwork generation, subjective judgment, new gameplay or unrelated layout refactoring.
- Acceptance:
  1. Every actually-live owner maps to a unique canonical marker/visual mount (two lift mounts may share one gameplay owner).
  2. No inert marker is promoted to a functioning interaction without a separate owner.
  3. Existing progression and art/geometry tests pass unchanged; no new collision or scene-regression.
  4. New parity smoke detects a deliberately mismatched/phantom owner and no missing images are misclassified as installed.
  5. No blocking defect or material evidence gap.
- Validation: new focused affordance marker/owner parity smoke, awakening_first_return_progression, awakening_designation_locker_presentation, lift, geometry, 04→05 composition/05→06 connector; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.
- Deferred: Art-gated successors remain draft/manual pending exact verified Asset V2 art.

## Review Receipt
- Status: `pending`
- Review target workstream: `awakening-interactible-affordance-foundation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_AFFORDANCE_FOUNDATION_V1.md`
- Reviewed main: `<fill>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_AWAKENING_INTERACTIBLE_AFFORDANCE_FOUNDATION_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Next Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `If passed, art-independent host is available; art-gated visual consumers still require state-by-state source proof and approval.`
- Blockers or open questions: `Implementation dependency only.`
