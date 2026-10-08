# OPERATOR 2.5D WORKBENCH GUIDED INGRESS

> PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION  
> Refresh after WB25-1 + paired review land. Consume their generation/target APIs; do not invent parallel identity/path state.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-ingress
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-operator-2-5d-workbench-cockpit-foundation
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-ingress
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: From one missing 2.5D target leaf, let an artist choose NEW or IMPORT and reach an identity-bound editable Workbench without manual filenames, Source Session CLI choreography, or legacy-path risk; support one-direction intake and an eight-direction family package.
- Completion boundary: Add guided intake orchestration over landed WB25-1 target identity. Native creation delegates to reviewed New Animation. External/generated PNGs delegate to SourceArtService and the existing publisher. Add resumable directional package manifests. Do not add network generation, pixel-polish automation, review sequencing, or runtime cutover.
- Current measured state: SourceArtService already owns immutable staging, analysis, profile normalization plans, production verification, review and handoff; New Animation owns absent canonical CREATE/publication; current OPUI has no identity-bound import wizard and source sessions are driven manually.
- Evidence: custodian/tools/operator/art_agent/source_service.py::start/analyze/plan_normalization/production_command/verify_production/review/handoff; custodian/tools/operator/art_agent/cli.py; custodian/tools/operator/animation_workbench.py; custodian/tools/operator/animation_workbench_model.py; custodian/tools/pipelines/operator_asset_schema.py; OPERATOR_WORKBENCH_ANIMATION_CREATION.md.
- Task-specific authority: landed WB25-1 authoring target/generation identity; SourceArtService for external/generated art; reviewed New Animation for native creation; Workbench publisher for canonical mutation; generation-aware operator_asset_schema.py for destinations.
- Work surface: recommended new custodian/tools/operator/operator_2_5d_ingress.py; custodian/tools/operator/ui/service.py; custodian/tools/operator/ui/app.py; recommended dialog custodian/tools/operator/ui/dialogs/import_2_5d.py; custodian/tools/operator/art_agent/source_service.py only where a narrow API extension is proven necessary; focused source/workbench UI tests.
- Change:
  1. A MISSING operator_2_5d_128 target offers NEW and IMPORT with generation/profile/group/action/direction/layer/frame defaults prefilled from target authority.
  2. NEW calls the landed Animation Creation backend. Do not duplicate creation manifest/publisher logic.
  3. IMPORT accepts only authorized source-work/inbox PNGs. Default unprocessed path convention:
     custodian/asset_drop/inbox/operator_2_5d/.
  4. Imported art creates an identity-bound Source Session recording target authoring identity, canonical profile/reference SHA, source SHA, intended frame/grid contract, and donor/reference provenance.
  5. Orchestrate existing stages: start → analyze → source landmarks/registration evidence → plan_normalization(mode=operator_profile) → production command/verification → review → handoff → Workbench creation/open.
  6. The UI never parses a destination filename to recover identity after the target is already known. Schema generates the filename/path.
  7. Add Import Direction Set for one family. Accept either eight explicit direction files or one confirmed grid/package. Never guess direction order from image position.
  8. Persist one package manifest under .ai/operator_animation_workbench/import_packages/<package-id>/package.json with target family, required directions/layers, source hashes, Source Session IDs, canonical profile/reference SHA, and per-cell stage.
  9. Incremental completion is allowed. Retry resumes verified Source Sessions/receipts and never repeats a destructive transformation simply because OPUI restarted.
  10. A package cannot report complete until every required canonical cell is handed into editable Workbench state or explicitly marked blocked.
  11. Wrong generation, stale profile/reference SHA, ambiguous grid, semantic collision, frame-contract mismatch, or legacy destination fails before canonical mutation.
  12. Imported/generated art cannot publish directly from Source Session. It must hand off to the existing Workbench/creation publication gate.
- Preserve: legacy edit/publish; New Animation; source-plan digest binding; Source Session rollback/staleness rules; dedicated art checkout; Workbench publication transaction; no direct runtime source.
- Non-goals: no network/image-generation call; no autonomous prompt execution; no temporal cleanup/repair; no runtime selector change; no automatic mirror completion; no generic Asset V2 family for Operator animation.
- Acceptance: select a missing 2.5D full_body 15f/128 NE target, import a disposable PNG from asset_drop/inbox/operator_2_5d, resume through SourceArtService without manual CLI/path construction, and open the resulting exact target in Workbench; an eight-direction mixed-state package truthfully reports completed/pending/blocked cells; ambiguous grid/wrong generation/stale profile/collision fail closed; legacy path hashes remain unchanged.
- Validation: focused single import, wrong-generation, ambiguous-grid, collision, resume, stale-profile, mixed-state 8-dir package, and rollback fixtures; reuse custodian/tools/validation/operator_art_source_smoke.py, custodian/tools/validation/operator_art_registration_profile_smoke.py, operator_animation_workbench_smoke.py and operator_workbench_ui_smoke.py where ownership selects them; then run_validation.py --changed and git diff --check.
- Task overrides: none
- Deferred: Workbench-integrated pixel polish; temporal QA; sequence/sandbox review; queue/briefs; runtime promotion.

## Recommended code shape

Use one orchestration record rather than hidden UI state:

~~~python
@dataclass
class ImportCell:
    direction: str
    source_path: str
    source_sha256: str
    source_session: str = ""
    stage: str = "PENDING"
    error: str = ""

@dataclass
class ImportPackage:
    package_id: str
    target_family_id: str
    art_generation: str
    canonical_profile_sha: str
    canonical_reference_sha: str
    cells: list[ImportCell]
~~~

Reuse SourceArtService directly:

~~~python
session = source.start(
    source_path=source_path,
    frames=target.frames,
    target_size=target.frame_size[0],
    columns=confirmed_columns,
    rows=confirmed_rows,
)
source.analyze(session)
source.plan_normalization(session, mode="operator_profile")
# execute source.production_command(session) through existing safe runner
source.verify_production(session)
source.review(session)
source.handoff(session, destination_name=schema_filename, dry_run=False)
~~~

The exact private wrapper may differ after WB25-1 lands; preserve this ownership sequence.

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: Bring WB25-1 implementation/review summaries and live generation-aware target/schema APIs back to this chat. Re-derive exact selection key, creation backend entrypoint, Source Session metadata extension, package fields, locks, and focused tests before ready.

## Handoff

- Next workstream: review-operator-2-5d-workbench-ingress
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: packet must be refreshed before claim
