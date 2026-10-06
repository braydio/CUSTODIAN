# OPERATOR 2.5D WORKBENCH COCKPIT FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-workbench-cockpit-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-2-5d-animation-viability-audit, review-operator-2-5d-canonical-visual-contract, review-operator-workbench-animation-creation`
- Locks: `operator-workbench-ui, operator-art-generation-schema, operator-animation-plan`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-2-5d-workbench-cockpit-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `f8ef4c84adf8f332713d4284a4c3aaa89ef51fb0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Visual review: `none`
- Goal: Give OPUI a safe migration model with separate legacy-96 and canonical-2.5D authoring generations, a target-driven 2.5D tree that shows missing leaves before files exist, and an honest action×direction matrix without changing production gameplay animation selection.
- Completion boundary: Introduce generation-aware authoring identity/path/workspace metadata; migrate the implementation plan to a target-capable v2 projection; render separate legacy and 2.5D browser roots; join 2.5D targets against real source/workbench/publication state; expose missing/partial/fallback/projected/stale states and a matrix. No guided import yet and no production gameplay cutover.
- Current measured state:
  - `AnimationSelection` currently identifies profile/group/action/direction only.
  - `discover_browser_records()` begins at `source_index()`, so absent art is invisible.
  - `AnimationTree` renders profile→group→action→direction only.
  - plan v1 owns rank/priority/state/reason/directions/layers but is not generation-aware.
  - New Animation creation is separately packeted and must be reviewed first.
  - canonical visual contract owns `legacy_96`/`operator_2_5d_128` geometry/reference.
  - viability audit owns production-reachable backlog/projection truth.
- Evidence: `custodian/tools/operator/ui/state.py`; `ui/service.py`; `ui/widgets/animation_tree.py`; `animation_workbench_model.py`; `operator_asset_schema.py`; `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json`; declared prerequisite workstreams.
- Task-specific authority: Operator asset schema for paths; canonical visual profile for generation geometry/reference; viability audit for backlog truth; implementation plan for authored priority/order; Workbench V2 for workspace/publication state.
- Work surface: generation/path schema and source index where required; UI state/service/tree; PLAN/QUEUE projection; implementation-plan schema/data; focused Workbench model/UI tests.
- Change:
  1. Add explicit `art_generation` with `legacy_96` and `operator_2_5d_128`; keep it separate from gameplay `profile`.
  2. Preserve all current legacy path results. Add a schema-owned collision-free source namespace for 2.5D; never hand-build it in Textual.
  3. Include generation in Workbench/session/workspace identity so the same semantic action can coexist safely.
  4. Upgrade plan authority to backward-readable v2 with generation, canonical profile ID, requested directions/layers, rank/priority/state/reason and migration verdict/source.
  5. Seed production-reachable 2.5D targets from the completed audit; exclude legacy/superseded residue.
  6. Preserve authored rank/priority. Computed status may not rewrite plan order.
  7. Build 2.5D browser target-first; every required direction exists even with no file.
  8. Keep legacy browser discovery-first.
  9. Expose explicit `LEGACY 96` and `2.5D 128` roots or an equally unambiguous generation selector.
  10. Separate coverage from workflow. Coverage minimum: `MISSING, PARTIAL, CANONICAL_2_5D, LEGACY_FALLBACK, PROJECTED`. Workflow minimum: `NONE, INTAKE, EDITING, REVIEW, READY_TO_PUBLISH, LAND_PENDING, RUNTIME_VERIFIED, STALE_REFERENCE, BLOCKED`.
  11. Fallback/projected never satisfy canonical completion.
  12. Mark work stale when recorded canonical profile/reference SHA differs from active authority.
  13. Add action×direction matrix from the same structured projection; selecting a cell selects the same identity as the tree.
  14. Preserve accepted browser snapshot/race protections; do not add another cache.
  15. Do not modify Godot `AnimationTree` or production runtime selectors.
- Preserve: all legacy source/runtime identities/publication; browser refresh hardening; New Animation backend; preview/timeline/motion behavior.
- Non-goals: guided import, package intake, runtime selector change, production 2.5D runtime promotion, general UX shell redesign, automatic art generation.
- Acceptance: legacy path outputs unchanged; same semantic identity safely coexists across two authoring generations; missing required 2.5D leaf appears; fallback/projected remains visibly incomplete; stale SHA visible; tree/matrix state matches; production runtime resources/selectors unchanged.
- Validation: focused generation-schema/path tests, plan v1→v2 compatibility, target projection, duplicate identity across generations, fallback/projection negative controls, stale-reference fixture, browser regression, `git diff --check`; `run_validation.py --changed` only after focused checks.
- Task overrides: `none`
- Deferred: guided ingress, package intake, review automation, generation briefs, production runtime cutover.

## Handoff
- Next workstream: `review-operator-2-5d-workbench-cockpit-foundation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include exact Authoring chat URL
- Refresh reason: `none`
- Next action: `paired fresh-context review`
- Blockers or open questions: `none`
