# REVIEW AWAKENING INTERACTIBLE MARKER WAYFINDING V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-interactible-marker-wayfinding-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `awakening-interactible-marker-wayfinding-v1`
- Locks: `awakening-interaction-presentation, awakening-wayfinding`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `required`
- Goal: Independently verify that improve existing register, gate/rest, attestation, lore-plaque and optional chapel wayfinding through noninteractive scenic mounts, with no fake prompt or route ability..
- Completion boundary: Fresh-context inspection of the real landed production owners, asset gate, focused tests and mutation/evidence as applicable, with independent falsification of claimed acceptance and a user visual verdict when required.
- Current measured state: This packet is blocked/manual until the implementation is landed and the exact human-approved Art V2 inputs are verified.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; archived `AWAKENING_INTERACTIBLE_MARKER_WAYFINDING_V1.md`; implementation summary; current main runtime/scene/Asset V2 receipts.
- Task-specific authority: actual Awakening scene/interaction owners, Layout and Asset V2; review does not create source art or determine human visual acceptance.
- Work surface: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/content/metadata/assets/families/awakening_interact_wayfinding.asset.json`; `custodian/content/metadata/assets/families/gate_of_dust.asset.json`; `design/04_architecture/AWAKENING_FIRST_RETURN.md`; implemented focus tests and evidence.
- Change:
  1. Rerun the implementation's focused and directly affected regression tests against landed main, not a fixture-only substitute.
  2. Prove no prompt or gameplay collision/nav/progression authority was introduced by a scenic prop, and no canonical art/04→05/05→06 registration was silently replaced.
  3. Verify exact source/Dropbox checksums and V2 verified state IDs; inspect gameplay-scale mid/near/dim-light renderer evidence, and require explicit human approval in Authoring chat without substituting reviewer aesthetic taste.
  4. Verify the implementation meets each named criterion and author only bounded corrections for actual findings. Do not change reviewed code.
- Preserve: Existing gameplay interaction roles, all canonical route/lighting/art authorities.
- Non-goals: No unrelated redesign, speculative new art, or direct changes to reviewed code.
- Acceptance:
  1. Scenic markers are recognizable but cannot be mistaken for live interactibles in prompts or signal groups.
  2. Gate remains sealed and all authored traversal/camera/collision intact.
  3. Approved selected artwork verified, no duplicated overlay pixels and human approval recorded.
  4. No blocking defect/material evidence gap; external human disposition recorded if required.
- Validation: awakening_first_return_smoke; awakening_first_return_geometry; awakening_first_return_progression; awakening_art_registration; Gate camera review; Asset V2 doctor; screenshots; --changed; git diff --check
- Task overrides: `TASK OVERRIDE: review only; commits limited to review receipt/summary/lifecycle metadata and bounded correction packets. No reviewed-code edits.`
- Deferred: Future art states remain deferred until separate real gameplay posting.

## Review Receipt
- Status: `pending`
- Review target workstream: `awakening-interactible-marker-wayfinding-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTIBLE_MARKER_WAYFINDING_V1.md`
- Reviewed main: `<fill>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `<from authoring chat>`
- Detailed review summary: `REVIEW_AWAKENING_INTERACTIBLE_MARKER_WAYFINDING_V1_CLAUDE_SUMMARY.md`
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
