# REVIEW AWAKENING CRÈCHE CONSOLE SPRITE REAUTHOR V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-creche-console-sprite-reauthor-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `awakening-creche-console-sprite-reauthor-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `review`
- Review: `none`
- Reviewed main: `956cf2114458`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `required`
- Goal: Review the newly authored Crèche terminal source, real V2 replacement provenance and FX screen fit independently.
- Completion boundary: Recorded positive human art verdict, objective source/alpha/hash/scene contract green, reviewer does not edit the hero sprite.
- Current measured state: `AwakeningFirstReturn._build_console_activation_presentation()` adds FX at `_marker_position(&"zone01_creche","creche_console")` without instantiating the existing 128×128 idle hero; FX is 8×128×128 at 8 FPS.
- Evidence: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/metadata/assets/families/awakening_creche_console.asset.json`; `custodian/content/metadata/assets/families/awakening_creche_console_activation_fx.asset.json`; `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_OVERLAY_V1.md`.
- Task-specific authority: `AwakeningFirstReturn` visual presentation, original `CrecheConsole` interaction owner, existing canonical V2 families, Layout marker, current root and custodian AGENTS art/review rules.
- Work surface: source_work/inbox/runtime family, artifact receipt, real scene and focused screen ROI evidence.
- Change: Verify actual old/new image source, approval checksum, `custodian.asset_ingest_job.v2` receipt, no unauthorized direct runtime edit, exact 128×128 one-frame and existing 8×128×128@8 FPS FX; check all frames' alpha ROI inside screen at game scale. Record user's aesthetic verdict; do not self-approve.
- Preserve: Existing `CrecheConsole` gameplay, first-use acknowledgement and repeat readout, HUD prompt, exact Layout marker (112,144), no duplicated body, original FX frames/fps.
- Non-goals: No new interaction owner, no second asset family for the hero, no general editor, no speculative room/route changes, no direct runtime PNG modification.
- Acceptance: No blocking findings/material gaps; human acceptance on real screenshots; no duplicate scene computer or new family.
- Validation: V2 status/doctor, catalog SHA, changed-file smoke; positive/negative screen ROI and first use/repeat/reset.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit and push only durable review receipt, its lifecycle/closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation.
- Deferred: Port and broader affordance art is handled by existing art-gated packets.

## Review Receipt
- Status: `pending`
- Review target workstream: `awakening-creche-console-sprite-reauthor-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_CRECHE_CONSOLE_SPRITE_REAUTHOR_V1.md`
- Reviewed main: `<fill at claim>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `<from authoring chat>`
- Detailed review summary: `REVIEW_AWAKENING_CRÈCHE_CONSOLE_SPRITE_REAUTHOR_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `none`
- What worked: `<fill at closeout>`

## Next Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Explicit human art-source and visual approval required`
- Next action: If passed, permit the dependent successor; otherwise create a bounded correction/re-review.
- Blockers or open questions: No newly approved source/visual verdict yet; do not claim.
