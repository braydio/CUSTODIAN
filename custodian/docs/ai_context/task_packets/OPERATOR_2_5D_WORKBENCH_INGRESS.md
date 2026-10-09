# OPERATOR 2.5D WORKBENCH GUIDED INGRESS

> REFRESHED / READY FOR IMPLEMENTATION  
> WB25-1 and its bounded R0-01 correction are landed and independently re-reviewed. Consume their generation/target/workspace APIs exactly; do not reintroduce family-level workflow projection or parallel identity/path state.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-ingress
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-ingress
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: d6c94d38c99e58c96e5f5c7e46db8d290bfeb10f
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none

## Agent Handoff / Planning Decisions — 2026-10-08

**This is the final pre-claim refresh for WB25-2. WB25-1 and correction R0-01 are accepted. The ingress implementation must adapt the existing reviewed authorities rather than build a second import/creation stack.**

### Landed predecessor API truth

- `AnimationSelection` now owns `art_generation`; `authoring_identity` is `<generation>:<profile>/<group>/<action>/<direction>`.
- `operator_animation_targets.TargetFamily` + `project_targets()` are the single target/coverage/workflow projection authority.
- `WorkbenchService.workspace(selection)` already routes `operator_2_5d_128` to the direction-level workspace `<workspace_root>/operator_2_5d_128/<profile>/<group>/<action>/<direction>`.
- The R0-01 correction is mandatory predecessor behavior: direction workflow reads the exact direction workspace and saved creation readiness comes from `animation_workbench.state()`, not persisted hints.
- `operator_asset_schema.canonical_source_path(key, art_generation="operator_2_5d_128")` owns the generation-separated 128px authoring source path.
- Accepted profile/reference authority remains profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761` and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.

### Gaps WB25-2 is expected to close

1. **Reviewed New Animation is still legacy-generation-shaped.**
   - `animation_workbench_model.build_creation_plan()` calls `canonical_source_path(key)` without an art generation.
   - `animation_workbench.create_animation()` and `WorkbenchService.create_animation()/animation_creation_plan()` do not yet accept generation-aware creation.
   - Extend this path additively with a default `legacy_96` generation. For `operator_2_5d_128`, derive generation-specific source targets and the already-landed generation-specific workspace. Existing legacy callers/paths must remain byte-for-byte compatible.

2. **SourceArtService advertises variable target size but the production proof still hard-codes 96px.**
   - `SourceArtService.start(... target_size=128)` is valid today.
   - `production_command()` currently emits `--size 96`.
   - `verify_production()` currently constructs a `(96,96)` expected target.
   - Parameterize both from the session target size while preserving 96px behavior for all legacy sessions.

3. **Source Session is not yet bound to the selected target authority.**
   - Current `custodian.operator_art_source_session.v1` stores source/geometry/target size but no authoring generation, semantic target, canonical profile/reference SHA, layer, or donor provenance.
   - Introduce one backward-readable session contract extension (prefer v2) that can bind the exact WB25 target. Do not create a second semantic-identity database in the ingress package.

4. **Source handoff collision scope is generation-blind.**
   - `SourceArtService.handoff()` currently resolves canonical collision evidence through the default legacy `canonical_source_path()`.
   - Make the handoff/inspection path generation-aware for Operator 2.5D so a legitimate legacy counterpart does not masquerade as a 2.5D authoring collision. Default legacy behavior must remain unchanged.

5. **Runtime publication remains forbidden in this slice.**
   - Existing runtime semantic paths intentionally remain generation-agnostic.
   - A legacy runtime counterpart is expected and must not prevent creating/importing the 2.5D authoring workspace.
   - WB25-2 may stage reviewed source and open/edit the target Workbench, but it must fail closed on any path that would publish/promote `operator_2_5d_128` into current production runtime. Runtime promotion remains WB25-6 authority.

### Package state rule

The package manifest is orchestration state, not a second Source Session state machine. Store target family/direction mapping, source hashes, Source Session IDs/paths, accepted authority hashes and per-cell terminal/orchestration status. Derive normalization/review truth from the referenced Source Session wherever possible.

For a combined direction sheet/package, explicit human/manifest direction mapping is required. **Never infer N/NE/E/SE/S/SW/W/NW from cell position.**

- Goal: From one missing 2.5D target leaf, let an artist choose NEW or IMPORT and reach an identity-bound editable Workbench without manual filenames, Source Session CLI choreography, or legacy-path risk; support one-direction intake and an eight-direction family package.
- Completion boundary: Add guided intake orchestration over landed WB25-1 target identity. Native creation delegates to reviewed New Animation. External/generated PNGs delegate to SourceArtService and the existing publisher. Add resumable directional package manifests. Do not add network generation, pixel-polish automation, review sequencing, or runtime cutover.
- Current measured state: WB25-1 is landed and its R0-01 direction-workflow correction passed fresh independent re-review with no remaining findings. Generation-aware target projection, authoring identity, 2.5D source paths, direction workspaces and truthful workflow states are live. SourceArtService already owns immutable staging, analysis, profile normalization plans, production verification, review and handoff, but its production proof still hard-codes 96px and its handoff collision lookup defaults to legacy generation. Reviewed New Animation still derives legacy source/workspace contracts unless extended. Source Session v1 lacks exact target/profile/reference provenance. OPUI has no identity-bound import wizard or resumable direction-package orchestration.
- Evidence: `OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION_CLAUDE_SUMMARY.md`; `REVIEW_OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; `operator_animation_targets.py`; `ui/state.py::AnimationSelection`; `ui/service.py::workspace/session/create_animation/animation_creation_plan`; `animation_workbench_model.py::build_creation_plan`; `animation_workbench.py::create_animation/state`; `operator_asset_schema.py::canonical_source_path`; `art_agent/source_models.py::SourceSession`; `art_agent/source_service.py::start/analyze/plan_normalization/production_command/verify_production/review/handoff`; reviewed New Animation authority.
- Task-specific authority: accepted WB25-1 `AnimationSelection`/`TargetFamily`/`project_targets`/direction-workspace model including R0-01; SourceArtService for external/generated source normalization and staging; reviewed New Animation for native creation; `operator_asset_schema.py` for generation-aware canonical authoring destinations; existing Workbench publisher remains the only publication authority but 2.5D production publication is deliberately unavailable in this slice.
- Work surface: recommended new `custodian/tools/operator/operator_2_5d_ingress.py`; `custodian/tools/operator/ui/service.py`; `ui/app.py` and one bounded ingress dialog/screen; `animation_workbench_model.py`; `animation_workbench.py`; `art_agent/source_models.py`; `art_agent/source_service.py`; `operator_asset_schema.py` only through its existing generation API; focused ingress/source/workbench validation. Do not broaden into runtime builder/selector code.
- Change:
  1. Add one ingress orchestrator over the landed target model. It accepts an exact `AnimationSelection` / projected target record and refuses reconstruction from filenames or free-form UI text.
  2. Add backward-compatible `art_generation="legacy_96"` support to the reviewed New Animation planning/creation seam. For `operator_2_5d_128`, use `canonical_source_path(..., art_generation=...)` and the generation-aware direction workspace. Existing legacy creation behavior and paths must remain unchanged.
  3. For 2.5D creation, existing legacy runtime/source counterparts are migration evidence, not authoring collisions. Collision checks must still fail on the same-generation canonical authoring target, same-generation workspace contract, or other true semantic conflicts.
  4. Keep 2.5D publication fail-closed in this slice. NEW/IMPORT may reach a saved editable Workbench; no WB25-2 path may replace production runtime art/resources/selectors or silently invoke the legacy publish transaction for `operator_2_5d_128`.
  5. Parameterize SourceArtService production conversion/verification from `SourceSession.target_width/target_height` instead of hard-coded 96. Preserve legacy 96 tests as regression controls.
  6. Extend Source Session backward-readably with one exact target binding: art generation, profile/group/action/direction/layer, canonical profile SHA, normalized reference SHA, intended frame contract, source/donor provenance. A v1 session with no target binding remains readable and behaves exactly as before.
  7. Make SourceArtService handoff/collision inspection accept the target art generation (default legacy) and resolve same-generation canonical authoring paths. A legacy counterpart must not block a valid `operator_2_5d_128` intake.
  8. IMPORT accepts only SourceArtService-authorized PNG paths. Default unprocessed convention remains `custodian/asset_drop/inbox/operator_2_5d/`; the specialized Operator pipeline remains authority rather than a parallel generic Asset V2 family.
  9. Orchestrate existing stages: start → analyze → optional source landmarks/registration evidence → plan_normalization(mode=operator_profile) → production command execution → verify_production → review → generation-aware handoff/staging → exact target Workbench create/open. Do not bypass any proof gate.
  10. Add Import Direction Set for one target family. Accept eight explicit direction files or a confirmed combined package/grid with an explicit direction map. Never infer direction order from image position.
  11. Persist one ignored package manifest under `.ai/operator_animation_workbench/import_packages/<package-id>/package.json`. It owns package target mapping, source hashes, Source Session references, accepted authority hashes, and per-cell orchestration/terminal state only; Source Session remains normalization/review authority.
  12. Resume is idempotent. Reuse verified Source Sessions and receipts when their source/plan/profile/reference hashes still match; never repeat a destructive conversion/handoff merely because OPUI restarted.
  13. A package is complete only when every required target cell is in an editable target Workbench or explicitly BLOCKED with a durable reason. Wrong generation, stale profile/reference SHA, ambiguous direction map, semantic collision, frame-contract mismatch or changed source/session proof fails before canonical/runtime mutation.
- Preserve: exact legacy creation/edit/publish behavior and paths; WB25-1 target/workflow projection including R0-01; source-plan digest binding; Source Session rollback/staleness rules; dedicated art checkout; existing Workbench publication transaction as sole future mutation authority; current production runtime source/resources/selectors; accepted profile/reference hashes.
- Non-goals: no network/image-generation call; no autonomous prompt execution; no temporal cleanup/repair; no runtime selector change; no automatic mirror completion; no generic Asset V2 family for Operator animation.
- Acceptance: select a missing `operator_2_5d_128` full_body 15f/128 NE target from the landed projection, import a disposable PNG from `asset_drop/inbox/operator_2_5d`, run a 128px SourceArtService production proof without manual CLI/path construction, preserve an exact target-bound Source Session, generation-aware handoff/stage it, and open the same `AnimationSelection.authoring_identity` in the direction-level Workbench; NEW reaches the same generation-aware workspace through the reviewed creation backend; a legacy counterpart does not collide with the 2.5D authoring target; same-generation/stale/wrong-generation/frame-contract conflicts fail closed; an eight-direction mixed-state package truthfully resumes completed/pending/blocked cells with explicit direction mapping; no 2.5D publish/runtime mutation is possible from this slice; legacy path/file hashes remain unchanged.
- Validation: add one focused ingress smoke covering target-binding, NEW generation workspace, 128px conversion/verification, generation-scoped collision, explicit direction mapping, restart/resume, stale profile/reference, same-generation collision, mixed-state 8-dir package, blocked 2.5D publish and rollback/read-only failure paths. Re-run `operator_animation_targets_smoke.py` (including R0-01 direction/readiness cases), `operator_asset_schema_smoke.py`, `operator_art_source_smoke.py`, `operator_art_registration_profile_smoke.py`, `operator_animation_workbench_smoke.py`, and Textual-enabled `operator_workbench_ui_smoke.py` where affected; include explicit legacy-96 regression fixtures; then `run_validation.py --changed --json`, Python compile checks and `git diff --check`.
- Task overrides: none
- Deferred: Workbench-integrated pixel polish; temporal QA; sequence/sandbox review; queue/briefs; runtime promotion.

## Recommended code shape

Prefer one orchestration owner around existing services:

~~~python
@dataclass(frozen=True)
class TargetBinding:
    art_generation: str
    profile: str
    group: str
    action: str
    direction: str
    layer: str
    canonical_profile_sha256: str
    normalized_reference_sha256: str
    frames: int
    frame_size: tuple[int, int]

@dataclass
class ImportCell:
    direction: str
    source_path: str
    source_sha256: str
    source_session: str = ""
    terminal_state: str = "PENDING"
    error: str = ""
~~~

The exact schema spelling may differ, but **target binding must live with Source Session evidence**, not only in UI/package state.

The 2.5D normalization call remains the existing service:

~~~python
session = source.start(
    source_path=source_path,
    frames=target.frames,
    target_size=target.frame_size[0],
    columns=confirmed_columns,
    rows=confirmed_rows,
)
# bind exact target/profile/reference authority
source.analyze(session)
source.plan_normalization(session, mode="operator_profile")
# execute the existing production command safely
source.verify_production(session)
source.review(session)
source.handoff(
    session,
    destination_name=schema_filename,
    art_generation=selection.art_generation,
    dry_run=False,
)
~~~

Do not copy this pseudocode literally if live signatures change during implementation. Preserve the authority sequence and fail-closed invariants.

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh status: **consumed / final pre-claim refresh complete**
- Refresh instruction: WB25-1, its R0-01 correction and fresh re-review have been consumed. WB25-2 is now `ready/auto`. Re-open planning only for a real contradiction in the landed generation/workspace/source-session authorities, not for implementation detail discovery.

## Handoff

- Next workstream: review-operator-2-5d-workbench-ingress
- Next packet state: ready/auto behind WB25-2
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: WB25-2 is fully refreshed; paired review should claim automatically after the implementation lands.
- Next action: claim and implement `operator-2-5d-workbench-ingress`; after landing, dispatch its paired fresh-context review.
- Blockers or open questions: none at planning level. If the live specialized Operator pipeline cannot support generation-aware staging without runtime mutation, fail closed and report that concrete architectural conflict rather than inventing a second pipeline.
