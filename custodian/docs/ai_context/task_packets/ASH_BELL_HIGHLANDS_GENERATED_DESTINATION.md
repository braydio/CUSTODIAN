# ASH-BELL HIGHLANDS — GENERATED DESTINATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-highlands-generated-destination`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `bridged-falls-generated-region-lifecycle`
- Locks: `ash-bell-highlands, procgen-region-profile`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-ash-bell-highlands-generated-destination`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Goal: Register a distinct generated Ash-Bell Alpine Highlands route destination that can receive the Operator from the Ritualant route and reserve an outward terminal for the later generated Bridged Falls subregion.
- Completion boundary: Using BF1's landed generated-region node contract, add one production-capable `ash_bell_highlands` generated destination with deterministic seed/profile data, named route spawns, explicit region-frame selection, 192–208-cell target scale, Alpine-compatible local biomes, and intent beats from arrival through a Bridged-Falls terminal reservation. Do not generate the bridge network yet.
- Current measured state: The production starting region explicitly selects `alpine_plateau`; local biome and region-frame ownership are already separate. No second registered generated route destination exists, and no Ash-Bell Highlands profile or route spawns exist on current main.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `design/05_levels/ASH_BELL_BRIDGED_FALLS_APPROACH.md`; `procgen_intent_graph_smoke.gd`; `procgen_region_frame_smoke.gd`.
- Task-specific authority: BF1 landed generated-region node contract; procgen Intent Graph owns route-scale generated intent; region-frame profile owns permanent exterior presentation; local biome field remains independent.
- Work surface: generated destination/profile data; procgen world/profile/intent configuration; named generated spawns; registry entry; focused deterministic multi-seed validation.
- Change: Create explicit `ash_bell_highlands` generated destination/profile; target 192–208 cells per side; bias toward rocky_upland + woodland with scrubland connective areas and sparse wetland; expose a stable `Spawn_FromRitualant`; reserve required intent beats `highlands_entry`, `highlands_descent`, `first_basin_reveal`, and `bridged_falls_terminal`; use an explicit Alpine-derived region frame rather than inferring from biome; ensure deterministic same-seed intent and meaningful cross-seed variation.
- Preserve: Generic starting-region behavior and `alpine_plateau`; Archive Resolve; existing biome classification; navigation/collision/streaming; other route destinations.
- Non-goals: No Ritualant route connection yet. No bridge-network generation. No Lower Quarter handoff. No production bridge/waterfall art.
- Acceptance: Registry/route tooling can stage the Highlands destination through BF1; same seed reproduces generation/intent/spawn; multiple fixed seeds vary route/terrain; required entry/descent/reveal/terminal beats remain reachable; region frame is explicit and local biome classification remains generative.
- Validation: Refresh this draft against BF1 first. Then add/run a focused Highlands generated-destination smoke; run `res://tools/validation/procgen_intent_graph_smoke.gd`, `res://tools/validation/procgen_region_frame_smoke.gd`, the generated-region lifecycle proof from BF1, and changed-file validation. Use at most one renderer overview if objective checks cannot establish the macro frame; subjective art approval is not required until BF6.
- Task overrides: `none`
- Deferred: Ritualant north exit, Bridged Falls topology, production environment art and Lower Quarter cutover.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh instruction: After BF1 lands, replace provisional runtime-kind/adapter terminology with the exact landed BF1 contract and remeasure live registry/profile seams before promoting this packet to ready.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill>`
- Completion boundary satisfied: `<fill>`
- Acceptance satisfied: `<fill>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill>`
- Friction severity: `<fill>`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `<fill>`

## Handoff
- Next workstream: `ritualant-north-egress-and-chapel-vista`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: BF3 depends on both generated-region lifecycle and the exact Highlands entry/spawn/presentation contract; re-derive it from live BF1/BF2 evidence plus the locked scene geography.
- Next action: Return BF2 evidence to this chat and refresh BF3 before claim.
- Blockers or open questions: none assumed if predecessors land cleanly.
