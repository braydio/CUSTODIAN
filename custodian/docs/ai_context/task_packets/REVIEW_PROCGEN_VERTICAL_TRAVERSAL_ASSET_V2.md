# REVIEW PROCGEN VERTICAL TRAVERSAL ASSET V2
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-vertical-traversal-asset-v2`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-vertical-traversal-asset-v2`
- Locks: `asset-pipeline, procgen-vertical-traversal-assets`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `asset-pipeline, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fresh-context falsification of new traversal-specific Alpine Asset V2 family`
- Review target workstream: `procgen-vertical-traversal-asset-v2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_VERTICAL_TRAVERSAL_ASSET_V2.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Prove A3 published exactly approved multi-cell traversal art at measured A2 geometry without substituting old fallback art or gameplay semantics.
- Completion boundary: Reconstruct the landed implementation from main, inspect actual changed owners rather than trusting its summary, run the focused falsification set, and record findings-first disposition.
- Current measured state: Reconstruct from landed main and the archived implementation packet/closing summary.
- Evidence: A3 source/inbox/runtime hashes, Asset V2 status/doctor, A2 geometry and human review disposition.
- Task-specific authority: Asset Pipeline V2; landed A2 geometry/anchors; current Alpine/AP2 material language; human source/style approval.
- Work surface: landed implementation files, directly affected tests, and only bounded review artifacts authorized below.
- Change:
  1. Verify all 14 identities, exact canvases, alpha, registration and source provenance against A2.
  2. Reject unapproved placeholder/old tiny ramp sources or nonuniform stretching.
  3. Confirm reviewed human hashes equal published runtime hashes.
- Preserve: A2 gameplay geometry/registration, AP2 ordinary cliff families, generic fascia fallback and no gameplay authority from alpha.
- Non-goals: no redesign, unrelated cleanup, preference tuning, or implementation edits inside the review workstream.
- Acceptance:
  1. All 14 states are verified from approved sources with exact geometry and valid human readability disposition.
  2. Negative controls fail for the intended reason; no passing fixture is vacuous or presentation-only where runtime behavior is claimed.
  3. No blocking defect or material evidence gap remains.
- Validation: Asset V2 plan/status/doctor + family/alpha/registration/provenance + changed-file validation + `git diff --check`; recapture only if hashes differ.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: A4 owns runtime composition.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none`
- Next action: `If PASS, return exact runtime identities to this Authoring chat for A4 refresh.`
- Blockers or open questions: `implementation dependency and the implementation packet's refresh gate`
