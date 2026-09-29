# PROCGEN RUNTIME OPTIMIZATION V2 SERIES AUTHORING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-runtime-optimization-v2-series-authoring`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-runtime-optimization-series-v1`
- Locks: `procgen-roadmap`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Convert the completed V1 whole-series review and final soak evidence into the next fully pre-authored procgen optimization/correction packet DAG, preserving the same unattended dependency-driven gauntlet pattern.
- Completion boundary: Done when every blocking V1 review finding and every evidence-backed next optimization selected for V2 has exactly one bounded owner packet, all V2 packets are `Status: ready` / `Dispatch: auto` with explicit dependencies/locks, the next V2 root packet is eligible, a final V2 whole-series review and V3-series-authoring handoff are included, and the detailed/master roadmaps reflect the new series. No runtime implementation occurs in this workstream.
- Current measured state: V1 implementation and final soak are complete and the independent series review has stable finding IDs, residual hotspots, dependency-chain observations, and evidence gaps.
- Evidence: `PROCGEN_RUNTIME_OPTIMIZATION_V1_REVIEW.md`; S1/S11 structured benchmark evidence; V1 archived packets/summaries; live V1 runtime architecture and validation.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; V1 final review; current `AGENT_TASK_PACKET_TEMPLATE.md` and task-packet authoring instructions.
- Work surface: Detailed procgen roadmap, master roadmap, active task-packet directory/index, FILE_INDEX, and only documentation needed to make the new series executable.
- Change: Re-run repository archaeology against the post-V1 live main; cluster findings by coherent subsystem owner; split tasks until each packet has one primary authority and every remaining dependent genuinely requires its prerequisites; preserve safe parallel siblings with shared locks instead of inventing false dependencies; author the entire V2 chain up front, including final independent series review and V3-series-authoring handoff. Use V2 packet schema and focused validation contracts. Carry stable V1 finding IDs into the packet(s) that close them.
- Preserve: V1 historical packets/evidence, reviewed performance baselines, truthful dependency history, current runtime behavior until V2 implementation packets land.
- Non-goals: No runtime code edits; no speculative feature work unrelated to V1 review/evidence; no packet that still requires a human design choice; no continuous worker implementation.
- Acceptance: V2 roadmap graph is acyclic; every active V2 packet parses through task-packet checks; each finding has exactly one owner or an explicit deferred/human-required disposition; dependency edges are justified by real authority prerequisites; final review/next-series handoff closes the loop; no manual packet-authoring step is required between V2 slices.
- Validation: Run task-packet/AI-context validators, dispatcher status/eligibility checks against a temp/read-only interpretation where available, dependency-cycle/duplicate-workstream checks, and `git diff --check`. No Godot runtime sweep is required because this workstream changes only planning/coordination artifacts.
- Task overrides: `none`
- Deferred: V2 runtime implementation is owned by the newly authored packets.

## Handoff

- Next action: Finish/archive this authoring workstream; the new V2 root packet(s) become the next auto-dispatch candidates.
- Best starting files: V1 review report; S1/S11 evidence; PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; AGENT_TASK_PACKET_TEMPLATE.md; active task packet README/index.
- Blockers or open questions: None known at authoring time.
