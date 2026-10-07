# BRIDGED FALLS — PROCGEN TOPOLOGY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `bridged-falls-procgen-topology`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-highlands-generated-destination`
- Locks: `bridged-falls-generation, ash-bell-highlands-intent`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-bridged-falls-procgen-topology`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Goal: Make Bridged Falls a true generated subregion whose bridge route is newly composed for each seed while preserving the locked alpine-descent -> first-basin-reveal -> bridge-complex -> Lower Quarter-terminal progression.
- Completion boundary: Extend the Highlands intent/generation pipeline with a required Bridged Falls macro reservation and deterministic bridge-network plan. Materialize playable semantic floor/collision/navigation for the generated network using existing procgen authorities. Use blockout presentation only; production bridge/falls art belongs to BF5/BF6.
- Current measured state: Current Intent Graph supports required spawn/main/ascent/vista/branch/shortcut/exit nodes and route edges; Sundered Keep proves a landmark-specific intent builder can add deterministic required beats and seeded side pockets. No Bridged Falls generator, bridge semantic plan, or Lower Quarter terminal exists.
- Evidence: `design/05_levels/ASH_BELL_BRIDGED_FALLS_APPROACH.md`; `worldgen_intent_{graph,node,edge}.gd`; `sundered_keep_landmark_intent_builder.gd`; `procgen_intent_graph_smoke.gd`; BF2 Highlands profile after refresh.
- Task-specific authority: Highlands generated destination owns the containing region; Intent Graph owns required macro route intent; existing terrain/floor/navigation builders own physical gameplay semantics; Bridged Falls planner may reserve/plan but must not become a second TileMap/navigation authority.
- Work surface: a dedicated Bridged Falls intent/topology planner, generated reservation data, semantic floor materialization hooks, debug summary, deterministic multi-seed validation.
- Change:
  1. Add a dedicated seeded Bridged Falls planner invoked only by the Ash-Bell Highlands profile.
  2. Preserve required beats in order: `first_basin_reveal` -> `bridge_head` -> generated bridge network -> `lower_quarter_terminal`.
  3. Generate a connected critical network targeting 5–9 major spans, 2–4 civic/terrace nodes and 1–3 optional branch/overlook spurs; allow 0–2 shortcuts when they do not bypass reveal/commit beats. Treat these as tuning targets rather than generic procgen quotas.
  4. Vary bridge count, orientation, bend/stagger, branch topology, broken-span rerouting, civic-node placement and overlook location from the region seed.
  5. Keep each span large enough to read as macro infrastructure. Reject noisy micro-maze output.
  6. Convert the accepted plan to ordinary semantic playable floor and existing collision/navigation. Bridge art is not walkability.
  7. Reserve generous CHASM/exterior-negative space around the network for future falls/mist presentation while keeping internal/exterior surface classification truthful.
  8. Export a compact debug snapshot: seed, span count, critical route length, branch count, shortcut count, reveal/terminal cells, topology hash.
  9. Add multi-seed proof: same seed identical; a bounded seed set shows at least several distinct topology hashes while all preserve reachability and required beat order.
- Preserve: Generic Intent Graph behavior and non-Ash-Bell profiles; BF2 entry/spawn/frame contract; existing floor/collision/navigation ownership; Sundered Keep landmark generation.
- Non-goals: No production bridge sprites. No waterfalls/underlays. No Ritualant route edit. No Lower Quarter authored route mutation.
- Acceptance: Every accepted Highlands seed contains one reachable Bridged Falls critical path from reveal to terminal; same seed is deterministic; multiple fixed seeds produce meaningfully different bridge graphs; route never bypasses first reveal/bridge-head commitment; branch/shortcut output cannot strand or disconnect the critical path; generated floor/collision/navigation agree.
- Validation: Refresh against landed BF2/BF3 evidence in the authoring chat before promotion. Add/run focused Bridged Falls deterministic multi-seed topology smoke; run `res://tools/validation/procgen_intent_graph_smoke.gd`, existing playability/navigation checks selected by changed files, and BF2 destination proof. Renderer evidence is limited to a small fixed-seed topology overview only if semantic/debug output cannot prove scale/layout.
- Task overrides: `none`
- Deferred: Production bridge art/grammar, waterfalls, sunset/skyline, Lower Quarter handoff.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh instruction: Re-read landed BF2 Highlands intent/profile and BF3 route geometry, then confirm reservation size, entry/terminal identities and planner hook before setting ready. Preserve the generated-new-route-every-seed design lock.

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
- Next workstream: `bridged-falls-bridge-grammar-asset-v2`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable summary and final Next Handoff.
- Refresh reason: BF5's exact modular asset shapes/counts must follow the real generated topology rather than the draft module list.
- Next action: Return topology evidence and seed captures to this chat, lock final bridge module contract, then promote BF5.
- Blockers or open questions: none assumed if BF4 acceptance is green.
