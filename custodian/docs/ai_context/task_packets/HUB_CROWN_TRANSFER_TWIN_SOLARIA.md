# HUB CROWN TRANSFER ↔ TWIN SOLARIA — H4

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-crown-transfer-twin-solaria`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-hub-awakening-context-handoff`
- Locks: `hub-runtime, route-traversal`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-crown-transfer-twin-solaria`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `348d00eea51e`

- Goal: Make Crown Transfer a real optional Hub branch into the existing registered Twin Solaria authored level and back, without turning Twin into ordinary Contract deployment or losing persistent Hub/Contract state.
- Completion boundary: CrownTransfer starts one same-Hub authored route to `hub_twin_solaria / Spawn_CrownCauseway`; an explicit Twin return restores the reviewed Hub host at `Spawn_TwinReturn`; activation/rollback/camera/navigation/state use the existing authored route/level authorities. No Contract selection or Campaign deployment.
- Current measured state: `custodian/content/levels/hub/twin_solaria_v1.json` registers production `hub_twin_solaria` with world_context `hub`, lifecycle keep_during_route/session, and `Spawn_CrownCauseway`. `LevelLoader` + `RouteTraversalManager` already provide staged authored-level transitions and rollback, but no Hub route connects H1 CrownTransfer to Twin. H2's production Hub host does not yet exist.
- Evidence: `design/05_levels/TWIN_SOLARIA.md`; Twin level JSON/layout/runtime smoke; `AUTHORED_LEVEL_AUTHORING_PIPELINE.md`; `ROUTE_TRAVERSAL_SYSTEM.md`; `level_loader.gd`; `route_traversal_manager.gd`; H1 `CrownTransfer` and `Spawn_TwinReturn`.
- Task-specific authority: reviewed H2 Hub host/lifecycle; live Twin definition; authored route/level registries; H1 marker authority.
- Work surface: Expected Hub route definition under `custodian/content/routes/hub/` plus `content/routes/routes.json`; CrownTransfer interaction/binding; Twin return exit binding; generic RouteTraversalManager/LevelLoader only if current code needs a context-neutral correction; focused Hub↔Twin route smoke.
- Change: Reuse the existing authored route stack for this same-Hub branch instead of the major-context manager. Forward entry targets `hub_twin_solaria / Spawn_CrownCauseway`; exfil/return restores the same Hub runtime/session at `Spawn_TwinReturn`. Preserve H1 host/session state while Twin is active according to the reviewed lifecycle policy. If RouteTraversalManager has a campaign-only assumption, generalize only the proven assumption rather than inventing a Hub-only loader.
- Preserve: Twin internal traversal/canon; detached Crown Annex topology; H1 geometry; any accepted Contract/bootstrap state if H3 has landed; major-context ownership of Hub↔Campaign; current route rollback/camera semantics.
- Non-goals: No Solarium II Passage restoration; no Crown incident/forensics/acquisition implementation; no ordinary Campaign deployment through Twin; no H3 Contract feature; no production Transfer Court art.
- Acceptance: CrownTransfer starts exactly one route; actor enters existing Twin at exact `Spawn_CrownCauseway`; Hub source is inactive while Twin owns authored traversal; return restores the same Hub/session at exact `Spawn_TwinReturn`; camera/navigation bind before input resumes; forced target-stage/activation failure rolls back; repeated entry/return leaks no duplicate Twin instances; accepted/prewarm state survives unchanged when present; Continuity Port remains uninvolved.
- Validation: Add focused Hub↔Twin route smoke covering entry, exact spawn, return, rollback, repeat cycle, cached/session state, and active-world exclusivity. Re-run `twin_solaria_runtime_smoke.gd`, directly affected RouteTraversal/LevelLoader smokes, H2/H1, then changed-file closeout and `git diff --check`.
- Task overrides: `none`
- Deferred: Twin Crown content slices; H5 Port deployment; production Transfer Court art.

## Claim-Time Dependency Refresh

This packet is intentionally `ready/auto` while its declared dependencies may still be incomplete. The dispatcher must keep it non-claimable until every `Depends on` workstream is archived `complete`. Once claimed, the execution agent must reconstruct the landed predecessor seams from current `main`, archived implementation/review summaries, and live public APIs before mutation. Reconcile private helper names and bounded implementation drift while preserving this packet's Goal, Completion boundary, Preserve, Non-goals, and Acceptance. Update directly stale packet/docs facts inside the workstream when needed. Do not stop for a ChatGPT/user refresh unless current evidence exposes a genuine unresolved design choice that existing authority cannot answer.
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

- Next action: After HR2 archives complete, auto-claim in parallel with H3 and self-refresh from the landed Hub host/route contracts.
- Best starting files: reviewed H2 Hub host; Twin level JSON/layout; route registry; RouteTraversalManager/LevelLoader.
- Blockers or open questions: exact Hub-host restoration adapter is an H2 output.