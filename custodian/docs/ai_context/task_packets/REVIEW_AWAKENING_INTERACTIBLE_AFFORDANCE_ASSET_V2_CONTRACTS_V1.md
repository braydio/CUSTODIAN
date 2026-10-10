# REVIEW AWAKENING INTERACTIBLE AFFORDANCE ASSET V2 CONTRACTS V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-interactible-affordance-asset-v2-contracts-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `awakening-interactible-affordance-asset-v2-contracts-v1`
- Locks: `awakening-interactible-asset-contracts`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `none`
- Review target workstream: `awakening-interactible-affordance-asset-v2-contracts-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_V2_CONTRACTS_V1.md`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Goal: Independently verify that register the approved live-affordance art contract without falsely treating ungenerated images as supplied..
- Completion boundary: Fresh-context inspection of the real landed production owners, asset gate, focused tests and mutation/evidence as applicable, with independent falsification of claimed acceptance and a user visual verdict when required.
- Current measured state: This packet depends on the implementation and is ready/auto but still implementation-dependent.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; archived `AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_V2_CONTRACTS_V1.md`; implementation summary; current main runtime/scene/Asset V2 receipts.
- Task-specific authority: actual Awakening scene/interaction owners, Layout and Asset V2; review does not create source art or determine human visual acceptance.
- Work surface: `custodian/content/metadata/assets/families/*.asset.json`; `custodian/content/metadata/assets/required_assets.registry.json`; `REQUIRED_ASSETS.md`; `custodian/tools/assets/asset.py`; `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`; `custodian/docs/ai_context/CURRENT_STATE.md`; implemented focus tests and evidence.
- Change:
  1. Rerun the implementation's focused and directly affected regression tests against landed main, not a fixture-only substitute.
  2. Prove no prompt or gameplay collision/nav/progression authority was introduced by a scenic prop, and no canonical art/04→05/05→06 registration was silently replaced.
  3. Verify source-pending and deferred-state classifications remain truthful, with no invented ready art or future gameplay.
  4. Verify the implementation meets each named criterion and author only bounded corrections for actual findings. Do not change reviewed code.
- Preserve: Existing gameplay interaction roles, all canonical route/lighting/art authorities.
- Non-goals: No unrelated redesign, speculative new art, or direct changes to reviewed code.
- Acceptance:
  1. Seven current family contracts parse and accurately show missing state truth.
  2. Required asset registry/generated view agree, with all existing hero art preserved.
  3. Future Hub/Supply/Sepulcher/Gate concepts are not introduced into the game or active required tracker.
  4. No blocking defect/material evidence gap; external human disposition recorded if required.
- Validation: Asset V2 plan/status/doctor for seven families; registry generator --check; awakening_art_registration; --changed; git diff --check
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.
- Deferred: Future art states remain deferred until separate real gameplay posting.

## Review Receipt
- Status: `pending`
- Review target workstream: `awakening-interactible-affordance-asset-v2-contracts-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_V2_CONTRACTS_V1.md`
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
- Detailed review summary: `REVIEW_AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_V2_CONTRACTS_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Next Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `If reviewed and passed, advance to the next eligible Awakening workstream; if missing art, remain parked.`
- Blockers or open questions: `Implementation dependency and human art disposition where required.`
