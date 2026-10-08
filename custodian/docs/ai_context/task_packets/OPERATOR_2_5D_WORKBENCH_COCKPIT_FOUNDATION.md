# OPERATOR 2.5D WORKBENCH COCKPIT FOUNDATION

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-cockpit-foundation
- Status: blocked
- Dispatch: manual
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
- Reviewed main: b0bc0956c4ce0510199b098d74691a39672df69a
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: Make OPUI target-driven for the canonical 2.5D migration: legacy and 2.5D art can coexist without path/session collisions, every required 2.5D leaf exists before pixels do, and one structured projection truthfully reports coverage and workflow state.
- Completion boundary: Add art_generation to authoring identity, a collision-free 2.5D source namespace, backward-readable implementation-plan v2, target-first 2.5D projection, separate legacy/2.5D browser roots, and an action×direction matrix from the same projection. Do not add import orchestration, art mutation, QA automation, or production runtime cutover.
- Current measured state: The New Animation backend prerequisite is now complete after bounded correction `operator-workbench-animation-creation-review-corrections-1` landed at `a26982b8d` and its cycle-1 paired re-review artifacts landed at `0ebea7b6` with 0 blockers, 0 material evidence gaps, and no new findings. Full-body and modular creation now publish through the shared `WorkbenchService`, preserve authored pixels, normalize to source-backed sessions, reject invalid contracts/post-preview target races, and surface unwired published identities as DORMANT. Two Operator-2.5D prerequisites remain unresolved on production main: (1) the viability-audit donor `8d66c42e4` is archived unique history, 409 commits behind current main, and its own durable summary says the workstream paused at the human visual-review boundary rather than completed; (2) the canonical visual-contract donor `1624fe638d` is archived unique history, 333 commits behind current main, while the active implementation packet is still ready/manual and its paired review has not completed. WB25-1 therefore cannot truthfully seed final target counts/profile/reference SHAs or become claimable yet.
- Evidence: archived `REVIEW_OPERATOR_WORKBENCH_ANIMATION_CREATION_REVIEW_CORRECTIONS_1.md` + its durable summary; `operator-workbench-animation-creation-review-corrections-1` landed at `a26982b8d`, review artifacts at `0ebea7b6`; archived viability donor `8d66c42e41296396747fbdeb0fcfbc57f289dad1` with `OPERATOR_2_5D_ANIMATION_VIABILITY_AUDIT_CLAUDE_SUMMARY.md` and report artifacts; archived canonical-contract donor `1624fe638db78bf1c30eec66541b739c280d8cac`; live `OPERATOR_2_5D_ANIMATION_VIABILITY_AUDIT.md`, `OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md`, paired canonical review packet, `operator_art_profile.json`, `operator_asset_schema.py`, Workbench service/state/widgets, implementation plan v1, and this roadmap.
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
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: This refresh consumed the completed New Animation correction/re-review and remeasured both remaining prerequisites. Keep WB25-1 blocked/manual until the viability audit is actually completed/landed from current-main evidence and the canonical visual contract is recovered, corrected for current main, landed, and independently reviewed. At that point bring the final viability counts/verdicts plus accepted `operator_2_5d_128` profile/reference hashes back to the planning chat; then rewrite this packet in place to ready/auto with exact target counts and plan-v2 seed rows.

## Handoff

- Next workstream: operator-2-5d-animation-viability-audit
- Next packet state: recovery/closeout-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: New Animation is reviewed complete, but the viability audit and canonical visual contract are not completed dependencies on current main; both existing implementations survive only as archived donor evidence.
- Next action: Recover/close the viability audit first, then recover/land/review the canonical visual contract; return their final counts/profile/reference SHAs here before promoting WB25-1.
- Blockers or open questions: The viability audit donor was paused at human visual review and lacks current-main closeout; the canonical visual-contract donor is hundreds of commits behind current main and must be reconciled before landing/review. The optional Textual pilot remains irrelevant to this gate.
