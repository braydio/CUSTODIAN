# REVIEW: CONTRACT WORLD PLACEMENT FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-contract-world-placement-foundation`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Review: `none`
- Review target workstream: `contract-world-placement-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CONTRACT_WORLD_PLACEMENT_FOUNDATION.md`
- Reviewed main: `099b42e2588d73c6a2f2ba2500c4c4ab517e77ed`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that P1 created one minimal read-only world-placement context seam, preserved ContractWorldLoader lifecycle/orchestration authority and all placement results, and did not smuggle any P2-P6 domain policy or a second mutable world model into the foundation.
- Reviewed implementation acceptance: Reuse the archived P1 packet's full Acceptance contract. Treat as blocking any mutable shadow copy of accepted map/level-data authority; broad writable map/loader exposure masquerading as a context; duplicated world lifecycle/placement authority; resource/vehicle/relay/encounter/ingress policy moved early; nondeterministic context construction; changed placement/order/startup behavior; undocumented owner/API; or missing focused proof.
- Review evidence: Archived P1 packet and closing summary; landed owner under `custodian/game/world/placement/`; `custodian/game/systems/core/systems/contract_world_loader.gd` adapter/construction seam; placement README/FILE_INDEX; implementation-created context smoke and manifest entry; existing population/resource/ingress/prewarm/startup regressions; S1 quick evidence.
- Correction threshold: Blocking for any API that lets downstream services mutate canonical map/lifecycle state through the context without an explicit existing authority call; context-owned domain scoring/candidate/placement policy; duplicate seed/query implementations; changes to current placement results/order; loader lifecycle logic moved without need; missing deterministic/no-side-effect proof; or docs/test ownership drift that could mislead P2-P6. Minor naming/docs polish may be non-blocking only when ownership and behavior are unambiguous.
- Focused validation: Run the implementation-created placement-context smoke first. Then run `contract_world_population_placement_smoke.gd`, `contract_resource_node_smoke.gd`, `world_ingress_spawner_smoke.gd`, `world_contract_prewarm_smoke.gd`, `startup_world_entry_smoke.gd`, and S1 quick unless implementation evidence is both fresh and unaffected by reviewed changes. Run AI-context/task-packet/review-pairing/manifest checks and `git diff --check` for review artifacts.
- Review focus: Inventory every field/method exposed by the context and identify its source authority; verify values are immutable/copied or access is narrowly read-only; verify no setter/placement/spawn/lifecycle side effect exists; verify seed/scoring primitives are deterministic and truly shared; verify P1 did not begin extracting any resource, vehicle, ARRN relay, encounter/Vaultwing, or authored-ingress policy; verify ContractWorldLoader remains the attach/rebind/activation/order authority; verify downstream P2-P6 packet assumptions still match the landed context or record which packets require refresh before claim.
- Acceptance: Produce a findings-first independent review on live main. Record a pass or stable cycle-scoped findings with class/domain/affected P1 acceptance/evidence/disposition/rationale. Blocking defects or material proof gaps create `contract-world-placement-foundation-review-corrections-1` plus its paired review. A clean/non-blocking-only pass unlocks P2-P6 dependency eligibility, but each remains serialized by the `contract-world-loader` lock and must be refreshed in place first if PR1 finds its assumptions no longer match the landed context.
- Non-goals: Do not implement P2-P6 domain extractions, contract-world loader contraction, ProcGen streaming/cache work, or unrelated agent tooling. Do not edit reviewed implementation code directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Claim after P1 completes and archives. On a clean/non-blocking-only pass, P2-P6 become dependency-eligible subject to the shared loader lock; refresh any packet whose exact API assumptions differ from the reviewed foundation.
- Blockers or open questions: None at authoring time.
