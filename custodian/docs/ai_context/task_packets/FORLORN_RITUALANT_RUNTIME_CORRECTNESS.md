# Forlorn Ritualant Runtime Correctness

- Status: `complete_with_documented_runtime_limit`
- Authority: `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md` and the active Ritualant underlay/shader specs.
- Goal: make lower-lift interaction/travel truthful, explicitly mask the void presentation, persist encounter state, align authored combat bounds, and close adjacent deterministic runtime gaps without changing dialogue or canon.
- Constraints: authored route remains authority; mask remains presentation-only; collision remains authored; no procgen ownership; no dialogue rewrite; preserve unrelated incoming art.
- Acceptance: focused Ritualant smokes, state reconstruction, transition rollback, explicit mask contract, low-FPS contact validation where current runtime still lacks it, and Moment Forge evidence.

## Live Audit

- Current HEAD already filters interaction candidates through `can_interact()`.
- Current drone FREE_ROAM code already stores its projected destination.
- Current melee code scans crossed presentation frames, but damage still reads the later live frame and therefore needs semantic-frame application.
- Current camp cap prevents overfill but permanently marks partial planned populations complete.
- Unrelated incoming Ritualant PNGs are present and must remain untouched.

## Plan

1. Implement lower-lift rider capture, process suspension, transition-result handling, and rollback.
2. Add explicit event/site/wrapper state capture and repair thread-cut ordering.
3. Replace moving underlay presentation with a fixed masked room quad.
4. Author combat bounds and improve room-boundary validation.
5. Connect committed Operator attacks to room reactions.
6. Finish semantic-frame melee contact processing and planned-camp refill behavior.
7. Extend focused validation, run Moment Forge evidence, repair documentation, and commit only owned files.

## Completion Evidence

- Focused smokes pass: authored Underground, encounter completion/state/lift rollback, semantic low-FPS contact cursor, Vigil dagger, encounter cadence, and allied-drone walkability.
- Repository changed-file selection ran 15 validations and all 15 passed. Its overall coverage exit was `6` only because unrelated untracked incoming Ritualant PNGs are intentionally outside this task's manifest ownership.
- Moment Forge `traversal/forlorn_ritualant_completion` passed every assertion in evidence mode. Review: `reports/moment_forge/traversal/forlorn_ritualant_completion/20260820T233550-0400/index.html`.
- The route pipeline's Ritualant-relevant registry, connectivity, rollback, exfil, cache, state, and exit-binding checks passed. The broader suite still exits nonzero in the unrelated `SunderedKeepWorldVistaSmoke` camera-weight assertions; this pass does not alter Sundered Keep.
- The live `LevelExit2D.request_transition()` Boolean reports local request eligibility; signal listeners do not synchronously return RouteTraversalManager acceptance. The lift now rolls back every observable `false` request. A future route API would be required to acknowledge an asynchronous downstream rejection without changing the signal ownership model in this pass.
- Existing Operator interaction filtering and drone FREE_ROAM projection were verified live and not redundantly rewritten.
- Content-only Ritualant action/death animation gaps and incoming unbound art remain deferred.
