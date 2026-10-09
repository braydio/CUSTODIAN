# REVIEW: F14-C1 Real Enemy Physical ↔ Abstract Ownership Handoff

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-living-world-entity-reification-handoff`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `living-world-entity-reification-handoff`
- Locks: `world-simulation-runtime, living-world-abstract-activity, world-actor-lifecycle`
- Review: `none`
- Review target workstream: `living-world-entity-reification-handoff`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md`
- Reviewed main: `810fb93aa20209096e88a6422c832885f220b22c`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify F14-C1 has a real physical Grunt ↔ abstract group handoff with precisely one gameplay authority at a time, stable ActorId/GroupId and state conservation across repeated crossings, without conflating F02 visual chunks or interest dormancy with actors.
- Reviewed implementation acceptance: **All 9 explicit Acceptance items** in the archived `LIVING_WORLD_ENTITY_REIFICATION_HANDOFF.md` including actual `enemy_grunt.tscn`, non-default health/intent, atomic state transfer at fixed-step boundaries, stopped descendants, 60-tick abstract advancement, safe one-time physical reification, repeated crossings, invalid/failure cases, snapshot continuation and legacy v4/v5/event-ID compatibility.
- Review evidence: Archived implementation packet, closing summary and changed files; new authored focused Grunt handoff smoke including negative controls; F14-B independent correction re-review receipt; exact source of current state, adapter and spawn/scene ownership; F15 geographical scope lock, relevant Godot smoke output and registration in validation manifest.
- Correction threshold: A real duplicate actor, simultaneous physical/abstract authority, lost or silently reset condition/intent/identity, repeated or lost causal event, broken legacy snapshot, unmanaged Enemy callback after unload, scene teardown corruption or materially unproved claimed acceptance is blocking. Cosmetic APIs or production geographic integration deferred by the packet are nonblocking.
- Focused validation: After `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian`, reproduce the authored `world_simulation_actor_reification_handoff_smoke.gd`, F14-B abstract activity, kernel, macro-state and snapshot-roundtrip smokes. Exercise the same-seed twice-unload/reentry case and the invalid/duplicate/queued-spawn/attack/death/failing-stage negatives; run narrow Enemy spawn smoke only if the owner was touched. Check changed-file validation and `git diff --check`. Distinguish first-import failure from an actual actor-hand-off defect.
- Review focus: Exclusive mode switching at kernel boundary, stable domain/group/actor ID grammar and collision-free compound IDs, no scene instance pointer as simulation authority, real Enemy health/intent reconstruction, descendant lifecycle, reentry placement validation, event dedupe/snapshot schema compatibility, no spawner/ambient-camp duplication, no new Clock, no gameplay mutations by Archive Resolve, F15 geography integration deferred.
- Acceptance: Fresh-context independent findings-first verdict on landed implementation `main` with linked exact evidence; record pass or stable R0-N findings with class/domain/affected acceptance/evidence/disposition/rationale. No reviewed implementation mutation. If a blocking finding or material evidence gap exists, author one bounded correction pair under existing review-cycle cap, without broadening F14-C1 into F15.
- Non-goals: Do not author/rewrite global geography, auto physical chunk residency, multi-member/offscreen combat, new enemy family, save-to-disk, vehicle/Port travel, or real map world streaming. Do not treat review as implementation work or bypass any human decision.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure and authoring gate

The implementation/review pair remains `draft/manual` until the official targeted local authoring preflight passes. Promote **both** to `ready/auto` together only under the authoring-approved F14-C1 synthetic one-Enemy boundary, rerun preflight, write/check the managed index, and land queue authority on `origin/main` before the implementation can be claimed. Only claim this review in a **fresh different-agent context** after the implementation packet archives complete. Follow `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` and root/local AGENTS.

## Next Handoff

- Next workstream: `none` (F14-C2 and F15 production integration conceptual; author only after reviewed C1 + geographic contract)
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: Review real Enemy handoff evidence, then lock F15 stable production geographic IDs, semantic region ownership, ambient spawn reconciliation and repeated physical site crossing before authorizing automatic production residency.
- Next action: Return reviewed C1 source, tests, receipt and material integration observations to this authoring chat for C2/F15 planning.
- Blockers or open questions: None for the independent C1 review after implementation lands; F14-C2/F15 production binding remains gated.
