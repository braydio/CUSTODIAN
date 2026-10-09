# OPERATOR 2.5D WORKBENCH COCKPIT FOUNDATION

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-cockpit-foundation
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-animation-viability-audit, review-operator-2-5d-canonical-visual-contract, review-operator-workbench-animation-creation-review-corrections-1
- Locks: operator-workbench-ui, operator-art-generation-schema, operator-animation-plan
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-cockpit-foundation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: 4aac943751ce1fdefd75d4985b3752474eb23b73
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none

## Agent Handoff / Planning Decisions — 2026-10-08

**This is the final pre-claim planning refresh for WB25-1. All declared prerequisites are complete and reviewed. Do not return to the authoring chat for the already-resolved visual/profile questions below.**

- Viability audit final scope:
  - 69 production-reachable legacy semantic families remain `legacy_96` migration/fallback evidence.
  - 1 authored canonical `operator_2_5d_128` family already exists: `unarmed/posture/idle_relaxed_01/full_body`.
  - 68 baseline semantic families remain without canonical 2.5D counterparts.
  - Baseline planning floor: 68 full-body 8-direction atlases / 544 direction-animation strips before extra modular, weapon, or FX layers.
  - 24 non-live/catalog-only families are excluded from the production migration backlog.
- Accepted canonical authority:
  - profile SHA-256: `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`
  - normalized reference SHA-256: `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`
  - first-family source SHA-256: `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`
  - design-lock SHA-256: `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`
  - center x=64; projected root `[64,106]`; shadow/ground `[64,107]`
  - profile status: accepted
  - universal action-envelope fit: **not asserted**
  - first-family timing/FPS: unknown/null and non-blocking
- The 128px profile is the canonical body/reference registration frame, not a universal maximum action envelope. Do not encode legacy `fast_02` overflow as a reason to expand the global canvas, shift the root, or shrink the Operator.
- The first family is already canonical art, not a synthetic target. Seed it as authored/canonical while preserving legacy art beside it as fallback evidence.
- Runtime production cutover is explicitly out of scope for WB25-1. This slice builds truthful authoring identity, target projection, plan-v2 state, browser roots, and matrix/tree selection only.
- Preserve all existing legacy source/runtime paths and current New Animation behavior exactly unless the packet explicitly requires generation-aware additive behavior.

- Goal: Make OPUI target-driven for the canonical 2.5D migration: legacy and 2.5D art can coexist without path/session collisions, every required 2.5D leaf exists before pixels do, and one structured projection truthfully reports coverage and workflow state.
- Completion boundary: Add art_generation to authoring identity, a collision-free 2.5D source namespace, backward-readable implementation-plan v2, target-first 2.5D projection, separate legacy/2.5D browser roots, and an action×direction matrix from the same projection. Do not add import orchestration, art mutation, QA automation, or production runtime cutover.
- Current measured state: All WB25-1 prerequisites are complete on current main. The viability audit closed with 69 production-reachable legacy semantic families, one authored canonical `operator_2_5d_128` family, 68 remaining baseline semantic families and 544 baseline direction-animation strips. The canonical visual contract implementation landed and its fresh paired review passed with 0 blocking defects, 0 material evidence gaps and 0 non-blocking findings. Accepted authority is profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`, normalized reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`, first-family source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, and design-lock SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`. Registration is center x=64/root [64,106]/shadow+ground [64,107]. New Animation is already reviewed through its correction/re-review path. WB25-1 is therefore claimable as the first implementation slice of the 2.5D Workbench migration.
- Evidence: `OPERATOR_2_5D_ANIMATION_VIABILITY_AUDIT_CLAUDE_SUMMARY.md`; `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_CLAUDE_SUMMARY.md`; canonical implementation `8574dfff5d6153e9638886729e1d34be5cc3bca1`; paired review landed at `4aac943751ce1fdefd75d4985b3752474eb23b73`; reviewed New Animation correction/re-review (`a26982b8d` / `0ebea7b6`); accepted hashes above; `operator_art_profile.json`; `operator_asset_schema.py`; Workbench service/state/widgets; implementation plan v1; migration roadmap.
- Task-specific authority: the **reviewed/landed** canonical visual contract for generation geometry/reference; the **completed** viability audit for production-reachable target scope; `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` for human rank/priority; `operator_asset_schema.py` for semantic/path validation; the corrected New Animation `WorkbenchService` path for absent-target creation/publication truth; Workbench source/workspace/publication state for workflow truth.
- Work surface: custodian/tools/operator/ui/state.py; custodian/tools/operator/ui/service.py; custodian/tools/operator/ui/widgets/animation_tree.py; custodian/tools/operator/ui/widgets/plan_table.py; recommended new pure owner custodian/tools/operator/operator_animation_targets.py; custodian/tools/pipelines/operator_asset_schema.py; design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json; focused Operator Workbench UI/model validation.
- Change:
  1. Add explicit authoring art_generation values legacy_96 and operator_2_5d_128. Keep art_generation separate from gameplay profile.
  2. Preserve every existing legacy canonical source path byte-for-byte. Extend schema/path APIs with a generation-aware authoring path. Recommended 2.5D root:
     custodian/content/sprites/operator/source/generations/operator_2_5d_128/animations/<profile>/<group>/<action>/<canonical-filename>.
     Do not change current canonical_source_path() output for callers that omit generation.
  3. Include art_generation in Workbench/session/workspace identity. Do not change production runtime semantic identity yet.
  4. Create one pure target/projection owner, recommended custodian/tools/operator/operator_animation_targets.py. UI service consumes it; Textual widgets do not rebuild target logic.
  5. Upgrade OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json to backward-readable schema custodian.operator_animation_implementation_plan.v2. Preserve v1 rank/priority/state values where still semantically valid; reclassify stale generic action groups against current schema instead of propagating invalid group names.
  6. v2 rows add art_generation, canonical_profile_id, requested directions/layers, migration verdict/source, canonical profile/reference/source/design hashes, and optional frame contract. Seed the 2.5D target plan from the completed audit: 69 production-reachable semantic families total, one already-authored canonical family, 68 baseline families still missing canonical counterparts, and 544 baseline direction-animation strips before extra modular/weapon/FX layers. The first row is not synthetic: `unarmed/posture/idle_relaxed_01/full_body` already exists as the authored 8-direction x 15-frame family with source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, design-reference SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`, accepted profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`, and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.
  7. Legacy browser remains discovery-first. 2.5D browser is target-first: every required leaf exists even when no file/session exists.
  8. Coverage states minimum: MISSING, PARTIAL, CANONICAL_2_5D, LEGACY_FALLBACK, PROJECTED. Workflow states minimum: NONE, INTAKE, EDITING, REVIEW, READY_TO_PUBLISH, LAND_PENDING, RUNTIME_VERIFIED, STALE_REFERENCE, BLOCKED.
  9. Fallback/projected/legacy never satisfy canonical completion.
  10. Mark a target stale when its recorded canonical profile/reference SHA differs from active authority.
  11. Add explicit LEGACY 96 and 2.5D 128 browser roots or an equally unambiguous generation selector.
  12. Add an action×direction matrix sourced from the same target projection; selecting a matrix cell selects the identical AnimationSelection/authoring target as the tree.
  13. Preserve browser snapshot/race protections. Do not create another cache or progress database.
- Preserve: current legacy source/runtime paths; New Animation backend; Source Session behavior; publish/rollback; preview/timeline/motion; production runtime resources/selectors.
- Non-goals: no guided import; no Source Session orchestration; no Aseprite cleanup automation; no production runtime cutover; no network image generation; no automatic plan rank mutation.
- Acceptance: the real `unarmed/posture/idle_relaxed_01/full_body` `operator_2_5d_128` family appears as the first authored canonical target with eight direction leaves, 15 frames per direction, 128x128 cells, source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, design-reference SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`, accepted profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`, and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`; the projection represents the audit truth of 69 live semantic families, exactly one already-authored canonical family and 68 baseline families still needing canonical 2.5D counterparts; missing future 2.5D targets appear before pixels exist; a legacy asset with the same semantic identity can coexist without source/workspace collision; matrix/tree select identical authoring identity; fallback/projected/legacy never satisfy canonical completion; stale profile/reference SHA is visible; current production runtime resources/selectors remain unchanged.
- Validation: focused generation/path compatibility, plan v1→v2 parsing, target projection, duplicate semantic identity across generations, stale SHA, fallback/projected negative controls, browser snapshot regression, then custodian/tools/validation/operator_workbench_ui_smoke.py and run_validation.py --changed only after focused checks; git diff --check.
- Task overrides: none
- Deferred: guided ingress; Aseprite polish automation; canonical QA/family review; runtime sandbox; production queue; runtime promotion.

## Recommended code shape

Keep semantic identity distinct from authoring identity:

~~~python
@dataclass(frozen=True)
class AnimationSelection:
    profile: str
    group: str
    action: str
    direction: str
    weapon_id: str = ""
    linked_profile: str = ""
    art_generation: str = "legacy_96"

    @property
    def semantic_identity(self) -> str:
        return f"{self.profile}/{self.group}/{self.action}/{self.direction}"

    @property
    def authoring_identity(self) -> str:
        return f"{self.art_generation}:{self.semantic_identity}"
~~~

Prefer one target record rather than UI-specific flags:

~~~python
@dataclass(frozen=True)
class AnimationTarget:
    selection: AnimationSelection
    required_layers: tuple[str, ...]
    coverage: str
    workflow: str
    canonical_profile_sha: str
    reason: str
~~~

Recommended v2 plan row:

~~~json
{
  "id": "unarmed_idle_relaxed_2_5d",
  "rank": 1,
  "priority": "P0",
  "art_generation": "operator_2_5d_128",
  "canonical_profile_id": "operator_2_5d_128",
  "profile": "unarmed",
  "group": "posture",
  "action": "idle_relaxed_01",
  "directions": ["n","ne","e","se","s","sw","w","nw"],
  "required_layers": ["full_body"],
  "frame_contract": {"frames": 15, "frame_size": [128,128], "loop": true},
  "source_sha256": "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3",
  "design_reference_sha256": "41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b",
  "canonical_profile_sha256": "05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761",
  "normalized_reference_sha256": "e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9",
  "state": "authored",
  "migration_verdict": "canonical_2_5d"
}
~~~

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh status: **consumed / final pre-claim refresh complete**
- Refresh instruction: The completed viability audit and passed canonical visual-contract review have been consumed. WB25-1 is now `ready/auto`. Do not reopen those prerequisites unless live main contradicts one of the accepted hashes or the dependency ledger no longer shows them complete.

## Handoff

- Next workstream: review-operator-2-5d-workbench-cockpit-foundation
- Next packet state: ready/auto behind WB25-1
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: WB25-1 is fully refreshed and claimable; its paired review should auto-claim after the implementation lands.
- Next action: claim and implement `operator-2-5d-workbench-cockpit-foundation`; after landing, dispatch its paired review automatically.
- Blockers or open questions: none. Universal action-envelope fit and animation timing remain intentionally outside this slice.

## Completion Truth
- Outcome: complete
- Implemented: generation-aware authoring identity and source/workspace namespace; plan schema v2 with preserved legacy ordering and corrected action groups; target-first projection for 69 families and 552 direction leaves; truthful canonical/fallback/projected/missing/stale workflow; separate browser roots and shared matrix/tree selection.
- Preserved: legacy canonical source paths and semantic runtime identity; existing runtime selectors/resources and New Animation backend remain unchanged.
- Evidence: `operator_animation_targets_smoke.py`, `operator_animation_plan_smoke.py`, `operator_asset_schema_smoke.py`, Textual-enabled `operator_workbench_ui_smoke.py`, `run_validation.py --changed --json` (19/19 selected passed, complete coverage), Python compile checks, and `git diff --check`.
- Deferred as specified: import orchestration, art mutation/QA automation, and production runtime cutover.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first changed-files validation run found missing validation-manifest ownership for the new projector and generation path checks; the gate was correctly closed.
- Root cause / contributing factors: New source and smoke files were added without registering their test ownership in `validation_manifest.json`.
- Prevention / pipeline improvement: Added focused target and asset-schema test entries/owners; rerun passed with full changed-file coverage.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Focused negative controls and the real Textual matrix cell handler verified generation identity without touching runtime authority.

## Next Handoff
- Next workstream: review-operator-2-5d-workbench-cockpit-foundation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: after implementation lands, claim the paired review in a fresh reviewer context and verify the archived packet contract.
- Blockers or open questions: none
