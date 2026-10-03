# HUB AWAKENING CONTEXT HANDOFF — H2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-awakening-context-handoff`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-hub-first-set-blockout-v1, review-awakening-handoff-readiness-art-convergence-v1`
- Locks: `hub-runtime, world-lifecycle`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-awakening-context-handoff`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `786f73125094`

- Goal: Consume the reviewed one-shot Awakening completion seam and enter the reviewed persistent Hub first-set runtime at `Spawn_SouthReach` through one major-context lifecycle authority, without starting a Contract or bypassing the Hub.
- Completion boundary: Establish the smallest production major-context handoff needed for Awakening → Hub. Validate the data-only completion once, freeze outgoing authority transactionally, activate a production Hub host around the reviewed H1 map with a real Operator/camera at `Spawn_SouthReach`, bind camera/navigation before control resumes, and fail/rollback safely. No Forum Contract behavior, Twin traversal, or Campaign deployment.
- Current measured state: Production boot enters Awakening. The active Awakening convergence workstream owns replacement of legacy blockout completion naming with a production completion seam. H1 is not yet landed. `WORLD_TRANSITION_SYSTEM.md` still describes the major-context manager as future architecture; live `LevelLoader` and `RouteTraversalManager` own authored traversal inside an active context and must not become the major-context owner.
- Evidence: `design/04_architecture/WORLD_TRANSITION_SYSTEM.md`; `AWAKENING_FIRST_RETURN.md`; `HUB_FIRST_SET_BLOCKOUT.md`; active Awakening handoff-readiness packet/review; H1 packet/review; `game/app/boot/runtime_entrypoint.gd`; live camera/navigation/authored-level contracts.
- Task-specific authority: reviewed Awakening completion contract; reviewed H1 map/spawn API; `WORLD_TRANSITION_SYSTEM.md`; runtime world/camera stabilization authority.
- Work surface: Expected major-context lifecycle owner under `custodian/game/systems/world/` or the cleaner landed equivalent; one production Hub runtime host; completion binding; reviewed H1 map; camera/navigation/world binding; focused handoff smoke. The H1 map itself stays Operator/camera-free.
- Change: Implement one authoritative request/state-machine seam sufficient for Awakening → persistent Hub and reusable by H5/H6. Awakening emits completion but does not call `change_scene_to_file()` into Hub. Resolve persistent-home taxonomy during refresh: if live architecture still says COMPOUND while the authored first-set is the Hub home context, keep one canonical context/alias migration instead of parallel HUB and COMPOUND managers. Place the Operator exactly at `Spawn_SouthReach`; validate target bindings before input unlock; return a deterministic structured failure and restore a safe source on target failure.
- Preserve: default boot into Awakening; reviewed H1 geometry; current startup development modes; generation_count remains zero through H2; RouteTraversalManager/LevelLoader ownership of authored sub-level traversal; deterministic simulation.
- Non-goals: No Dais interaction; no `WorldContractBootstrap.ensure_started()`; no Twin entry; no Port deploy; no Campaign return; no transit polish; no save/resume expansion.
- Acceptance: one reviewed Awakening completion causes at most one successful Hub entry; duplicate/reentrant completion cannot create a second Hub; Awakening contains no direct Hub scene change/bootstrap call; the target is one production Hub host containing the reviewed H1 map with a real Operator exactly at `Spawn_SouthReach`; source and target are never simultaneously authoritative; camera/navigation/world binding completes before input unlock; forced target-stage/validation failure restores a playable source and reports failure; startup modes remain green; bootstrap generation_count remains zero.
- Validation: Add one focused major-context handoff smoke for success, duplicate suppression, binding order, active-world exclusivity, and rollback. Re-run reviewed Awakening completion/progression tests, H1 blockout smoke, startup-world-entry, directly affected camera/navigation binding smoke, then changed-file closeout and `git diff --check`.
- Task overrides: `none`
- Deferred: H3 Contract selection/prewarm; H4 Twin route; H5 deployment; H6 return; save/resume and transit presentation.

## Temporary Refresh Gate — REMOVE WHEN REFRESHED

This packet is intentionally pre-authored before both prerequisite reviews land. After they pass: inspect archived review receipts and exact completion snapshot/H1 API/current world-binding seams; update Reviewed main, measured state, exact Work surface, Acceptance and validation paths; remove this section; set `Status: ready`, `Dispatch: auto`. Refresh this packet in place, not as a v2 duplicate.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh after both prerequisite reviews pass.
- Best starting files: archived Awakening convergence + H1 packets/reviews; `WORLD_TRANSITION_SYSTEM.md`; live startup/camera/navigation binding code.
- Blockers or open questions: exact landed completion schema and Hub-host seam are dependency outputs.
