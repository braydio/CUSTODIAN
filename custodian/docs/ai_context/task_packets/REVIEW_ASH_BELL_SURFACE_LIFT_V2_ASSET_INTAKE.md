# REVIEW: ASH BELL SURFACE LIFT V2 ASSET INTAKE
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ash-bell-surface-lift-v2-asset-intake`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `ash-bell-surface-lift-v2-asset-intake`
- Locks: `asset-pipeline, ash-bell-lift-art, dropbox-handoff`
- Review: `none`
- Review target workstream: `ash-bell-surface-lift-v2-asset-intake`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ASH_BELL_SURFACE_LIFT_V2_ASSET_INTAKE.md`
- Reviewed main: `b224e51a295e19ef4ae15111c1517dc6a79e70ea`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `asset-pipeline, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify source fidelity, family metadata, full-frame registration, approvals, and truthful pending-versus-ingested status of every lift V2 source state.
- Reviewed implementation acceptance: Read archived `ASH_BELL_SURFACE_LIFT_V2_ASSET_INTAKE.md` Acceptance and Completion boundary verbatim; test every assertion, including declared deferrals, against current runtime and receipts.
- Review evidence: Archived implementation packet and approval receipt; exact Dropbox ZIP hash/member manifest; generated V2 contracts/catalog, normalized outputs and source-stage receipt; imported resources and targeted per-frame alpha metrics.
- Correction threshold: Unknown or fabricated review approval, untracked source hash, false 8f activation, alpha/frame bleed, material texture-quality failure, pre-existing runtime overwrite, or family falsely marked fully bound/verified is blocking.
- Focused validation: Rerun independent ZIP+member SHA check, family-plan/status/doctor and target frame geometry/alpha tests; review only a compact cropped keyframe set when objective checks cannot decide presentation quality.
- Review focus: Prove neither accidental 6f→8f pose invention nor silent downgrade; prevent source-work-only PNG and empty receipt from being counted as ingested or visually approved; check full-resolution master files preserved and sprite atlas invariants.
- Acceptance: Publish a findings-first fresh-context review receipt against landed `main`. Record passed or stable cycle-scoped `R0-01` finding IDs with class/domain/affected acceptance/evidence/disposition/rationale. Confirmed blocking defects or material evidence gaps create bounded `ash-bell-surface-lift-v2-asset-intake-review-corrections-1` and its independent paired review; do not modify implementation in this workstream.
- Non-goals: No implementation edits, no new visual art, no new gameplay system or independent intake.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Return reviewer pass or stable findings with exact technical and visual evidence to the authoring chat; do not claim successor implementation until review is archived complete.
- Blockers or open questions: Fresh reviewer is required; unresolved subjective art decisions must be escalated as `human_required`.

