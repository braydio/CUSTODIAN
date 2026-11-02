# PROCGEN STUCK POCKET AUTHORITY

- Status: `complete`
- Authority: `design/02_features/procgen/PROCGEN_CORRECTIONS.md`, `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`, `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`
- Goal: Keep floor/wall TileMaps as base structural authority while making spawned collision participate in runtime walkability, preventing no-exit pockets, and providing loud diagnostics plus a debug-only Operator rescue.
- Files: procgen tilemap, foliage spawner, navigation system, contract loader, Operator, debug console, focused validation, AI context docs.
- Constraints: deterministic generation; canopy remains visual-only; no smaller player collider; no silent teleport; no presentation or debug system may own simulation state.
- Acceptance: runtime blockers affect navigation; protected routes reject blocking props/trunks; pocket validation detects and remediates collision-created traps; stuck report and Observatory events identify ownership; focused and adjacent procgen smokes pass.
- Completed: runtime collision-owner overlay; navigation consumption; tree/ruin wiring; route/structure/combat clearances; forgiving trunk defaults; deterministic two-exit pocket remediation; structured stuck report; debug-only Operator rescue; Developer Observatory telemetry; focused smoke and docs.
- Deferred: visual playtest against the originally observed ruin/canopy seed or save is still recommended when that reproduction input is available. The adjacent `procgen_placeholder_roads_smoke.gd` currently fails its parking-apron assertion for seed `420777` before blocker placement; this unrelated road-generation failure was not changed here.

## Ownership And Timing

- Owner: ProcGenTilemap runtime blocker overlay; NavigationSystem consumes it; Operator only diagnoses/rescues in debug builds.
- Agent/session: Codex `/root`
- Created: 2026-07-14
- Last updated: 2026-07-16

## Work Surface

- Read: active procgen design authority, AI context, validation recipes, foliage/prop spawning, navigation, Operator movement, Developer Observatory.
- Change: blocker registration/unregistration, local escape validation, protected clearances, trunk tuning, diagnostics/rescue, docs and smoke.
- Out of scope: player collider changes, new navigation architecture, canopy collision, manual level redesign.

## Plan

1. Add blocker authority and navigation consumption.
2. Register collision-bearing foliage/props and enforce route/structure clearances.
3. Validate/remediate pockets and expose diagnostics/Observatory data.
4. Add debug-only Operator rescue and console report.
5. Run focused and adjacent validation, then synchronize docs.

## Drift Review

- Primary authority: retain TileMaps as base structural truth; document runtime collision overlay.
- `CURRENT_STATE.md`: update runtime behavior after validation.
- `CONTEXT.md`: no guardrail change expected.
- `FILE_INDEX.md`: index blocker authority and smoke.
- Local routing/readmes: no path migration.

## Handoff

- 2026-07-16 follow-up: ruin props now reject complete inline collision footprints before instantiation, revalidate actual generated footprints after late portal-route reservation but before blocker registration, and keep deterministic candidate ordering. Observatory payloads/gauges distinguish rejection from backup remediation, and focused plus full-seed smokes cover the contract.
- Next action: reproduce the original stuck location in a debug build, run `stuck_report`, and export the F10 Observatory session if any blocker mismatch remains.
- Best starting files: `game/world/procgen/proc_gen_tilemap.gd`, `game/world/procgen/foliage/procgen_foliage_spawner.gd`.
- Validation to run: `procgen_stuck_pocket_smoke.gd` plus existing focused procgen smoke(s) selected by the validation recipe.
- Blockers or open questions: no blocker for this slice; the unrelated parking-apron smoke assertion remains tracked above.
