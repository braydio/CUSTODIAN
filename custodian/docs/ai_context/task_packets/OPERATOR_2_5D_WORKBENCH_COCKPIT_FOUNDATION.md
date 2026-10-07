# OPERATOR 2.5D WORKBENCH COCKPIT FOUNDATION

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-cockpit-foundation
- Status: draft
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-animation-viability-audit, review-operator-2-5d-canonical-visual-contract, review-operator-workbench-animation-creation
- Locks: operator-workbench-ui, operator-art-generation-schema, operator-animation-plan
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-cockpit-foundation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Visual review: none
- Goal: Make OPUI target-driven for the canonical 2.5D migration: legacy and 2.5D art can coexist without path/session collisions, every required 2.5D leaf exists before pixels do, and one structured projection truthfully reports coverage and workflow state.
- Completion boundary: Add art_generation to authoring identity, a collision-free 2.5D source namespace, backward-readable implementation-plan v2, target-first 2.5D projection, separate legacy/2.5D browser roots, and an action×direction matrix from the same projection. Do not add import orchestration, art mutation, QA automation, or production runtime cutover.
- Current measured state: AnimationSelection has profile/group/action/direction only; discover_browser_records() starts from source_index() so absent art is invisible; operator_asset_schema.py canonical operator source paths have no generation dimension; OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json is v1 and generation-blind; canonical 2.5D profile/landmarks are still landing through the prerequisite visual-contract workstream.
- Evidence: custodian/tools/operator/ui/state.py; custodian/tools/operator/ui/service.py::discover_browser_records; custodian/tools/operator/ui/widgets/animation_tree.py; custodian/tools/operator/animation_workbench_model.py; custodian/tools/pipelines/operator_asset_schema.py; design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json; design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md.
- Task-specific authority: the reviewed canonical visual contract for generation geometry/reference; completed viability audit for production-reachable target scope; OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json for human rank/priority; operator_asset_schema.py for semantic/path validation; Workbench source/workspace/publication state for workflow truth.
- Work surface: custodian/tools/operator/ui/state.py; custodian/tools/operator/ui/service.py; custodian/tools/operator/ui/widgets/animation_tree.py; custodian/tools/operator/ui/widgets/plan_table.py; recommended new pure owner custodian/tools/operator/operator_animation_targets.py; custodian/tools/pipelines/operator_asset_schema.py; design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json; focused Operator Workbench UI/model validation.
- Change:
  1. Add explicit authoring art_generation values legacy_96 and operator_2_5d_128. Keep art_generation separate from gameplay profile.
  2. Preserve every existing legacy canonical source path byte-for-byte. Extend schema/path APIs with a generation-aware authoring path. Recommended 2.5D root:
     custodian/content/sprites/operator/source/generations/operator_2_5d_128/animations/<profile>/<group>/<action>/<canonical-filename>.
     Do not change current canonical_source_path() output for callers that omit generation.
  3. Include art_generation in Workbench/session/workspace identity. Do not change production runtime semantic identity yet.
  4. Create one pure target/projection owner, recommended custodian/tools/operator/operator_animation_targets.py. UI service consumes it; Textual widgets do not rebuild target logic.
  5. Upgrade OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json to backward-readable schema custodian.operator_animation_implementation_plan.v2. Preserve v1 rank/priority/state values where still semantically valid; reclassify stale generic action groups against current schema instead of propagating invalid group names.
  6. v2 rows add art_generation, canonical_profile_id, requested directions/layers, migration verdict/source, and optional frame contract. Seed operator_2_5d_128 rows from the completed viability audit rather than every legacy catalog row.
  7. Legacy browser remains discovery-first. 2.5D browser is target-first: every required leaf exists even when no file/session exists.
  8. Coverage states minimum: MISSING, PARTIAL, CANONICAL_2_5D, LEGACY_FALLBACK, PROJECTED. Workflow states minimum: NONE, INTAKE, EDITING, REVIEW, READY_TO_PUBLISH, LAND_PENDING, RUNTIME_VERIFIED, STALE_REFERENCE, BLOCKED.
  9. Fallback/projected/legacy never satisfy canonical completion.
  10. Mark a target stale when its recorded canonical profile/reference SHA differs from active authority.
  11. Add explicit LEGACY 96 and 2.5D 128 browser roots or an equally unambiguous generation selector.
  12. Add an action×direction matrix sourced from the same target projection; selecting a matrix cell selects the identical AnimationSelection/authoring target as the tree.
  13. Preserve browser snapshot/race protections. Do not create another cache or progress database.
- Preserve: current legacy source/runtime paths; New Animation backend; Source Session behavior; publish/rollback; preview/timeline/motion; production runtime resources/selectors.
- Non-goals: no guided import; no Source Session orchestration; no Aseprite cleanup automation; no production runtime cutover; no network image generation; no automatic plan rank mutation.
- Acceptance: a synthetic unarmed/posture/idle_relaxed_01 target with art_generation=operator_2_5d_128, eight required directions, full_body, 15 frames and 128x128 can appear with all eight leaves before source files exist; a legacy asset with the same semantic profile/group/action/direction can coexist without source/workspace collision; matrix/tree select identical authoring identity; fallback/projected remain incomplete; stale profile SHA is visible; current production runtime resources/selectors are unchanged.
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
  "rank": 10,
  "priority": "P0",
  "art_generation": "operator_2_5d_128",
  "canonical_profile_id": "operator_2_5d_128",
  "profile": "unarmed",
  "group": "posture",
  "action": "idle_relaxed_01",
  "directions": ["n","ne","e","se","s","sw","w","nw"],
  "required_layers": ["full_body"],
  "frame_contract": {"frames": 15, "frame_size": [128,128]},
  "state": "active",
  "migration_verdict": "reauthor"
}
~~~

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh instruction: After the viability audit is formally completed and the corrected canonical visual contract + paired review land, bring their closing summaries/profile/reference SHAs and live main back to this chat. Re-derive final target counts, accepted 128 registration/profile fields, exact source namespace API, and plan-v2 seed rows before setting this packet ready.

## Handoff

- Next workstream: review-operator-2-5d-workbench-cockpit-foundation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: none after this packet is refreshed and implemented
- Next action: paired fresh-context review
- Blockers or open questions: prerequisite human/profile decisions must land before this packet becomes ready
