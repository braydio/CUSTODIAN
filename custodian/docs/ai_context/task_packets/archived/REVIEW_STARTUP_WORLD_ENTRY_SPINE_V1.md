# REVIEW: STARTUP WORLD ENTRY SPINE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-startup-world-entry-spine-v1-r1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `startup-world-entry-spine-v1`
- Locks: `app-boot, world-lifecycle`
- Review: `none`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Review target workstream: `startup-world-entry-spine-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/STARTUP_WORLD_ENTRY_SPINE_V1.md`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `4eec3a3bcb8447dc4d625b4dfdd654c2fde515e8`
- Goal: Independently verify that the App/Boot spine makes Twin Solaria and the Contract sandbox directly bootable without changing production story order or duplicating generation/world-loading authorities.
- Review focus: default Awakening preservation; no default prewarm; one bootstrap generation in Contract mode; existing proxy/loader reuse; Twin direct mode uses the existing production playtest wrapper without world-ingress/persistent-unlock mutation; boot layer remains free of procgen construction/gameplay authority; current boot docs match live behavior.
- Acceptance: findings-first pass or bounded correction packet through the review pipeline. Reviewer does not patch implementation directly.
- Non-goals: Do not add Hub/Forum, production Twin access, procgen optimization, or pause-policy changes during review.

## Required Checks

1. Run default project boot and prove it reaches Awakening.
2. Observe `WorldContractBootstrap.generation_count` and prove default remains zero.
3. Boot Twin mode and prove Crown Causeway arrival through the existing wrapper.
4. Boot Contract mode with a fixed seed and prove bootstrap generation count is exactly one across the scene switch.
5. Confirm `ContractWorldLoader` remains map attach/placement owner.
6. Confirm no `world_ingress` was added to Twin Solaria.
7. Confirm `ARCHITECTURE.md` no longer describes obsolete immediate-`game.tscn` default boot.
8. Exercise invalid mode/seed fail-safe behavior.
9. Confirm no new startup code contains world construction, route adjudication, or persistent unlock mutation.


Queue recovery note: the original remote review branch is fully contained by current main with zero unique commits but still exists. This `-r1` workstream is the executable fresh-context review identity.

## Handoff

- Next action: on pass, proceed to the production Hub continuation/world-transition slice from the roadmap.
- Blockers or open questions: blocked only by `startup-world-entry-spine-v1`.
