# REVIEW: ASH BELL LIFT DEV QUICK LAUNCH
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ash-bell-lift-dev-quick-launch`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `ash-bell-lift-dev-quick-launch`
- Locks: `debug-runtime, world-lifecycle, ash-bell-lift-site`
- Review: `none`
- Review target workstream: `ash-bell-lift-dev-quick-launch`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ASH_BELL_LIFT_DEV_QUICK_LAUNCH.md`
- Reviewed main: `b224e51a295e19ef4ae15111c1517dc6a79e70ea`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the new real-world lift quick-launch preset, especially safe spawn, correct real ingress instance, debug/release gating and absence of progression bypass.
- Reviewed implementation acceptance: Read archived `ASH_BELL_LIFT_DEV_QUICK_LAUNCH.md` Acceptance and Completion boundary verbatim; test every assertion, including declared deferrals, against current runtime and receipts.
- Review evidence: Landed preset code and receipt, DevMode shell commands, real generated-world seed/ingress actor spawn smoke, screenshots limited to one exterior entry ROI only if needed, existing loader regression.
- Correction threshold: Failure to instantiate actual procgen placed lift, ability to invoke in release, unsafe/nonwalkable Operator spawn, incorrect camera/controls, bypassed progression or startup regressions are blocking.
- Focused validation: Rerun playable preset smoke for CLI and shell entry (including release-flag rejects) plus ingress/return and spatial/floor acceptance; diagnose against WorldIngressSpawner, not a local mock.
- Review focus: Prove no fixed-coordinate spawn, no fake standalone scene, no unsafe cliff/void cell, no off-mode/release bypass, no duplicate world state, no accidental auto-descent or White Thread unlock.
- Acceptance: Publish a findings-first fresh-context review receipt against landed `main`. Record passed or stable cycle-scoped `R0-01` finding IDs with class/domain/affected acceptance/evidence/disposition/rationale. Confirmed blocking defects or material evidence gaps create bounded `ash-bell-lift-dev-quick-launch-review-corrections-1` and its independent paired review; do not modify implementation in this workstream.
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

