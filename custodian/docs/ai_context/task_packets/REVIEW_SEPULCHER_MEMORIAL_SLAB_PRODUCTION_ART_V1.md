# REVIEW: SEPULCHER MEMORIAL SLAB PRODUCTION ART V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-sepulcher-memorial-slab-production-art-v1`
- Category: `assets-art`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `sepulcher-memorial-slab-production-art-v1`
- Locks: `asset-pipeline, hub-sepulcher`
- Review: `none`
- Review target workstream: `sepulcher-memorial-slab-production-art-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/SEPULCHER_MEMORIAL_SLAB_PRODUCTION_ART_V1.md`
- Reviewed main: `761ea68008e32305691d15ffd5de546289c6a6b0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently establish that the exact approved Memorial Slab source has been normalized, ingested, bound and displayed in production Hub gameplay without altering any authored Sepulcher grave behavior.
- Reviewed implementation acceptance: Verify every acceptance clause in the immutable archived `SEPULCHER_MEMORIAL_SLAB_PRODUCTION_ART_V1.md` packet, including original-art provenance, V2 registered state, live scene visibility, absence of duplicate procedural slab, unchanged interaction/persistence and full production-runtime proof.
- Review evidence: Read exact user approval at https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac, source hash/revision receipt, runtime texture resource path, V2 family/catalog/status, grave controller diff, Hub smoke results, minimal production grave ROI and closing summary. Reconstruct from durable repo evidence rather than relying on the implementation conversation.
- Publication inputs: `design/04_architecture/HUB_SEPULCHER_AWAKENING_ART_V1_MANIFEST.md`, `design/04_architecture/ASSET_PIPELINE_V2.md`, `custodian/game/world/hub/events/sepulcher_grave/sepulcher_grave_evidence.gd`, `custodian/tools/validation/hub_sepulcher_grave_evidence_smoke.gd`, `custodian/tools/validation/hub_sepulcher_grave_resolution_smoke.gd`, `custodian/tools/validation/hub_first_set_blockout_smoke.gd`
- Correction threshold: Wrong or unverifiable source, invented approval hash/receipt, failed alpha/registration, image not shown by production scene, duplicate stone, changed gameplay/collision/routes, untested state restore, and a material runtime proof gap are blocking. Optional polish does not trigger corrections absent an acceptance failure.
- Focused validation: Independently rerun focused Hub grave, resolution and blockout smokes; asset.py status/doctor/needs as relevant; audit imported texture pixel geometry, alpha, source digest, consumer path and node visibility; reuse narrow renderer evidence, recapture only if stale/incomplete.
- Review focus: Ensure world anchor (-1984,-3200), 160x96 one-frame RGBA texture, grave event semantics, growth gate, read positions and z-order; confirm original accepted art and source receipt are not misrepresented; distinguish imported from runtime-verified.
- Acceptance: Publish findings-first independent review on landed `main`, with either accepted `passed` receipt or concrete cycle-scoped finding IDs and dispositions. Produce a bounded correction/re-review packet only for blocking defects/evidence gaps; keep subjective composition human-owned and mark `human_required` if material approval remains unresolved. Do not self-modify reviewed implementation.
- Non-goals: No replacement artwork, no new CAL-01/blackwater intake, no new gameplay or architecture redesign, no implementation edits inside review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9a2f9-cf10-83e8-bffe-5f16e079abac
- Next action: Return the independent PASS or precisely scoped findings to the authoring chat; preserve one-at-a-time art queue and do not release the next asset before closure.
- Blockers or open questions: Fresh reviewer context is required; unresolved material subjective placement is escalated to human review with the exact compact Dropbox evidence path.
