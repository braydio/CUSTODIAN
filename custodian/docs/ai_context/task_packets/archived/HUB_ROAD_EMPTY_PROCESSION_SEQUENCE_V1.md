# ROAD PROCESSION SPATIAL BEAT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-road-empty-procession-sequence-v1`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `hub-road-procession`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-hub-road-empty-procession-sequence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Stage one playable three-beat empty procession in the POST-AWAKENING Hub North Processional. Existing Road plates are presentation only.
- Completion boundary: In HubRuntimeHost/HubFirstSetMap, a real Operator walks from Spawn_SouthReach through the authored North Processional toward ForumSouth and voluntarily triggers one south→mid→north bell/lamp sequence. No use of the Awakening-only Road prototype as a second route authority.
- Current measured state: Awakening section 10 explicitly defers its north approach. The separate production HubFirstSetLayout defines walkable North Processional Rect2i(72,97,32,36) with Road-local 32px cells, H1 verified Operator-clearance routes and H2 Hub host handoff. Five Road plate pairs are presentation only; not a continuous north-approach art guarantee. HubState has no generic authored-event-record field on inspected base.
- Evidence: custodian/game/world/hub/first_set/{hub_first_set_layout,hub_first_set_map}.gd; design/04_architecture/HUB_SPATIAL_LAYOUT.md
- Task-specific authority: Road module placement ownership, HubState, event spec §3.; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`.
- Work surface: Focused event controller under custodian/game/world/hub/events/road_procession/ with narrow HubFirstSetMap integration; HubState as persistent authority only if a suitable record seam is already live or added minimally with exact safe snapshot/restore. Do not duplicate G1's record authority if concurrently landed.
- Publication inputs: `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`
- Change: Use H1/H2 first-set runtime, not Awakening section 10, for the route. Place three distinct spatial beats in the existing clearance-validated navigable Road/North Processional corridor; candidate anchors are (0,-1152), (0,-1632), (0,-2208), but resolve exact reachable real-Operator trigger bounds from live map before placement. Each beat is activated at most once in logical order; stage visible local lamps/sound using current presentation owners without changing lighting/world state. Existing five plate pairs keep exact registration: do not assume they cover the new North Processional. Persist the event's first-seen/beat completion through the single existing HubState owner (using any G1 record API if already present), deep-copy/backward-compatible snapshot, no second global event manager. No cinematic camera or blocked controls.
- Preserve: Normal player control, Dais route, Road collisions and Crown ingress.
- Non-goals: No testimony station yet, new lighting scheduler, cutscene system, new artwork.
- Acceptance: In a real Hub host a live Operator walks from Spawn_SouthReach through all 3 triggers into ForumSouth, with 3 ordered effects and no teleport; same stage restored from HubState snapshot, no duplicate replay on return; both H1 passage and Forum Dais remain passable/untouched; before/after Road plate positions, textures and collisions unchanged. No north-segment raster art requirement.
- Validation: Add focused Hub-host/real-Operator path+timeline/persistence smoke; reuse existing hub_first_set_blockout_smoke.gd, hub-awakening handoff and HubState snapshot regressions. First assert actual walkability and actor clearance, then event idempotency, then changed-file validation and git diff --check.
- Task overrides: `none`
- Deferred: Production raster Asset V2 art and unlisted expansion mechanics; no mandatory external asset package.

## Playable world boundary
Awakening First Return north processional remains deferred **inside Awakening**. This task uses the separate post-Awakening Hub first-set map and the H1/H2 reviewed handoff. If the live Hub real-Operator traversal is broken, diagnose that bounded H1/H2 regression and do not manufacture a substitute route or relocate the event into Awakening.

## Dependency assumption
Root slice of an independent event chain; implement against live main without waiting for other authored events.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `not-recorded`
- Refresh instruction: Read latest origin/main and predecessor review; reconcile exact runtime owners/paths without expanding user-approved scope or starting new design research.

## Handoff
- Next action: Complete the focused implementation, land, then run `review-hub-road-empty-procession-sequence-v1`.
- Blockers or open questions: No authoring-side design blockers; ordinary dispatcher dependencies and live claim locks apply.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: The post-Awakening Hub Road sequence is playable through three ordered beats. The real Operator traverses the H1/H2 Hub route from Spawn_SouthReach through North Processional toward ForumSouth; Awakening remains untouched. Focused smoke proves traversal, order, local effects, HubState persistence/restore, no replay after completion, unchanged H1/Dais routing, and no Contract prewarm. `run_validation.py --changed --test hub_road_empty_procession --json` passed.
- Evidence: `python3 custodian/tools/validation/run_validation.py --changed --test hub_road_empty_procession --json` passed; `hub_first_set_blockout`, `world_transition_handoff`, `hub_forum_adjudication`, and `campaign_outcome_exactly_once_smoke.gd` also passed.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The fresh worktree lacked Godot's import/class cache on the first direct launch; an initial backward-compatibility fixture omitted the existing campaign_history field. Both were resolved before final validation.
- Root cause / contributing factors: First-run Godot import state was absent; the test fixture did not use the actual legacy HubState snapshot shape.
- Prevention / pipeline improvement: Run import preflight and project import before focused Godot smokes in fresh worktrees; derive legacy fixtures from HubState.snapshot() and remove only newly introduced fields.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Physical Operator traversal and restored event snapshots gave deterministic route, order, and idempotency evidence.
