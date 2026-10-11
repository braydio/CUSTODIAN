# REVIEW: F14-C2a Exactly-Once Managed Population Slot Reservation and Spawn Queue Guard

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-living-world-population-slot-reservations`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `living-world-population-slot-reservations`
- Locks: `ambient-enemy-spawn-queue, managed-population-reservations`
- Review: `none`
- Review target workstream: `living-world-population-slot-reservations`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/LIVING_WORLD_POPULATION_SLOT_RESERVATIONS.md`
- Reviewed main: `84c7eb1f8a2ee8c2e4936b9df9afa8ea7e1672d1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify managed spawn **at-most-once** reservation, cancellation/replay safety and camp/global quota convergence at the real F04 scheduler queue boundary, with no F14 actor-truth or unmanaged ambient regression.
- Reviewed implementation acceptance: Exact `LIVING_WORLD_POPULATION_SLOT_RESERVATIONS.md` **C2a-01..C2a-08**: same-actor double enqueue blocked; distinct same-name different-Domain actor keys and invalid F14 group rejection; cancellation before/during dequeue and stale token callback non-instantiation; F14 already-physical/in-flight/changed-location guard; null parent/scene/walkability/cap/camp lifecycle quota release; unmanaged family/cap/marker behavior preserved; real queue fixture PASS/negative path and manifest coverage; honest current-state documentation.
- Review evidence: Archived C2a implementation packet, exact landing commit and closing summary, changed `ambient_enemy_camp.gd`, `ambient_enemy_spawner.gd`, transient broker/token implementation (if introduced), focused new queue test, manifest coverage, F14-C1 coordinator and abstract state, existing unmanaged ambient regressions and B1 identity. Treat authored closeout statements as assertions to falsify.
- Correction threshold: Issue review correction only for confirmed C2a-01..08 defects or **material proof gaps**: double physical managed spawn, stale callback resurrection, mishandled cap/token refund, accidental unmanaged spawn rejection, F14 Group/Actor ownership fork, missing actual queue-path test, false PASS receipts. Physical C2b stage/residency and Ritualant underground world ingress are out-of-scope unless a directly changed behavior breaks existing acceptance.
- Focused validation: After Godot editor import in the new reviewer worktree, run the new managed queue smoke with required exit 0 and exact PASS, deliberate negative mode exits nonzero, and run existing `custodian/tools/validation/procgen_enemy_family_spawn_smoke.gd` and `custodian/tools/validation/world_simulation_actor_reification_handoff_smoke.gd` where affected. Independently interleave: reserve→queue→cancel→physics tick; queue duplicate→dequeue; dequeue pending→revoke token→callback; same dotted group names in distinct Domains; F14 physical actor present; parent destroyed and walkability rejection; repeated camp reactivation. Inspect pending queue and per-camp counts **after every terminal outcome**, not only active scene count. Run `custodian/tools/validation/run_validation.py --changed --base <actual-parent> --test <new-owner-id> --json`, ensure manifest maps all changed runtime files, `git diff --check`. Do not substitute a broker-only test for real queue-path evidence.
- Review focus: Managed reservation must be established **before queue enqueue** and rechecked just before `PackedScene.instantiate()`; verify no TOCTOU reification conflict and no second actor authority; token/epoch must guard canceled/stale requests. Confirm un-managed request behavior and existing marker dedupe, cap/leash, family selection remain compatible. A valid B1 Domain+Location key cannot substitute for Domain+Group+Actor identity. Watch for `_queued_or_spawned_count` leakage and callback-failure double-release. Distinguish synthetic test anchor from real world ingress.
- Acceptance: Deliver fresh-context findings-first receipt on actual landed source. Per C2a-01..08 cite observed pass/fail with concrete code/fixtures. For each finding assign `R0-NN`, class, domain, affected acceptance, source evidence and disposition. Blocking/material gap produces **separate delta correction + fresh re-review pair**, capped at two automatic cycles; no implementation edits in reviewer. If clean, `passed` receipt; archive review with exact authoring-chat URL and remain clear that C2b is still gated.
- Non-goals: Do not implement reservation code in review, change `ActorReificationCoordinator` anchor policy, enable physical area unload, author B2/F15-C packets, repair unrelated Ritualant ingress, alter art, world scale, simulation tick or disk persistence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Reviewer independence

1. Claim only after C2a implementation archives `complete` on current main. Start a fresh separate agent context and inspect root/local AGENTS, archived implementation packet and summary, accepted F14-C1/B1 authorities, actual queue/camp logic and direct runtime fixtures.
2. Probe adversarial cancellation/late-callback and quota cases on **actual** queue rather than interpreting test titles or PASS markers as sufficient. Check domain collision and no un-managed branch regressions.
3. Record receipt in archived C2a packet, make only authorized closing-review evidence updates, and surface future C2b coordination only as downstream planning.

## Next Handoff

- Next workstream: `none`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: `F14-C2b real scene residency can only be specified after reviewed C2a slot lifetime and independently reviewed B2/F02 site ingress contracts are known.`
- Next action: Return the reviewed reservation/cancellation receipt to this chat and reconsider C2b safe Domain-qualified physical anchors with fresh F02 ingress evidence; do not start C2b by implication.
- Blockers or open questions: `C2b and F15-C streaming/physical seams, numeric world scale and visual art are intentionally deferred.`
