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
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Convert the completed V1 whole-series review and final soak evidence into the next evidence-backed procgen optimization/correction DAG, preserving stable workstream identities and unattended dispatch where architecture is actually known while using explicit refresh gates where a later slice's exact contract depends on not-yet-landed predecessor structure.
- Completion boundary: Done when every blocking V1 review finding and selected evidence-backed next optimization has exactly one bounded owner/workstream identity; immediately executable packets are `ready` / `auto`; architecture-dependent downstream packets are deliberately `blocked` / `manual` with an explicit predecessor review/refresh gate; dependencies/locks are acyclic and truthful; a final V2 whole-series review and V3 authoring handoff are included; detailed/master roadmaps and packet index reflect those states. No runtime implementation occurs here.
- Current measured state: V1 implementation and final soak are complete and the independent series review has stable finding IDs, residual hotspots, dependency-chain observations, and evidence gaps.
- Evidence: `PROCGEN_RUNTIME_OPTIMIZATION_V1_REVIEW.md`; S1/S11 structured benchmark evidence; V1 archived packets/summaries; live V1 runtime architecture and validation.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; V1 final review; current `AGENT_TASK_PACKET_TEMPLATE.md` and task-packet authoring instructions.
- Work surface: Detailed procgen roadmap, master roadmap, active task-packet directory/index, FILE_INDEX, and only documentation needed to make the new series executable.
- Change: Re-run repository archaeology against post-V1 `main`; cluster findings by coherent subsystem owner and current file path; author stable packet/workstream identities for the V2 DAG. Only make a packet `ready` / `auto` when its current measured state and implementation surface are real on that main. If exact API/files depend on an earlier architecture slice, publish a blocked/manual refresh packet that names what evidence will unlock re-authoring in place. Preserve parallel siblings through real locks instead of false serial dependencies. Carry V1 finding IDs into their one closing owner.
- Preserve: V1 historical packets/evidence, reviewed performance baselines, truthful dependency history, current runtime behavior until V2 implementation packets land.
- Non-goals: No runtime code edits; no speculative feature work unrelated to V1 evidence; no requirement that every future packet be `ready` at authoring time; no packet that requires an unresolved human design choice; no continuous worker implementation.
- Acceptance: V2 roadmap graph is acyclic; every finding has exactly one owner or explicit deferred/human-required disposition; every `ready` packet is executable from current live evidence; every architecture-dependent future slice is fail-closed behind a named refresh gate instead of asserting future state as current; packet/review pairing and dependencies parse; final review/V3 handoff closes the loop; no duplicate `_v2` packet identities are required merely because a blocked packet later gets refreshed.
- Validation: Run task-packet/AI-context validators, review-pairing checks, dispatcher eligibility/status, dependency-cycle/duplicate-workstream checks, and `git diff --check`. Confirm a sample of `ready` packets resolves all literal validation paths and that blocked refresh packets cannot auto-claim. No Godot runtime sweep is required because this workstream changes planning/coordination artifacts only.
- Task overrides: `none`
- Deferred: V2 runtime implementation is owned by the newly authored packets.

## Handoff

- Next action: Finish/archive this authoring workstream; the new V2 root packet(s) become the next auto-dispatch candidates.
- Best starting files: V1 review report; S1/S11 evidence; PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; AGENT_TASK_PACKET_TEMPLATE.md; active task packet README/index.
- Blockers or open questions: None known at authoring time.
