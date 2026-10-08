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
- Reviewed main: 90e2ac01e3b91809bd5e1b52fe6ada13e388c808
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: Make OPUI target-driven for the canonical 2.5D migration: legacy and 2.5D art can coexist without path/session collisions, every required 2.5D leaf exists before pixels do, and one structured projection truthfully reports coverage and workflow state.
- Completion boundary: Add art_generation to authoring identity, a collision-free 2.5D source namespace, backward-readable implementation-plan v2, target-first 2.5D projection, separate legacy/2.5D browser roots, and an action×direction matrix from the same projection. Do not add import orchestration, art mutation, QA automation, or production runtime cutover.
- Current measured state: The New Animation backend is reviewed complete. The user has now supplied and locked the actual migration authority pair: design lock `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png` (2048x256, 8x1 256px cells, SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`) and first canonical animation `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png` (1920x1024, 15x8 128px cells, SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, semantic identity `unarmed/posture/idle_relaxed_01/full_body`). Existing pre-migration live art is not the target and may only be legacy/fallback evidence. The viability audit therefore needs deterministic closeout rather than another art-direction decision; the canonical visual-contract packet now owns hardening the two inputs and must land + pass its paired review before this cockpit becomes claimable. WB25-1 remains blocked/manual until those two receipts provide final accepted profile/reference hashes and refreshed target counts.
- Evidence: exact Dropbox implementation inputs/hashes above; user's lock decision in this authoring chat; reviewed New Animation correction/re-review (`a26982b8d` / `0ebea7b6`); active viability and canonical-contract packets; `operator_art_profile.json`; `operator_asset_schema.py`; Workbench service/state/widgets; implementation plan v1; migration roadmap.
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
  6. v2 rows add art_generation, canonical_profile_id, requested directions/layers, migration verdict/source, source/reference hashes, and optional frame contract. Seed `operator_2_5d_128` rows from the completed viability audit rather than every legacy catalog row. The first row is not synthetic: `unarmed/posture/idle_relaxed_01/full_body` already exists as the authored 8-direction x 15-frame family with source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3` and design-reference SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.
  7. Legacy browser remains discovery-first. 2.5D browser is target-first: every required leaf exists even when no file/session exists.
  8. Coverage states minimum: MISSING, PARTIAL, CANONICAL_2_5D, LEGACY_FALLBACK, PROJECTED. Workflow states minimum: NONE, INTAKE, EDITING, REVIEW, READY_TO_PUBLISH, LAND_PENDING, RUNTIME_VERIFIED, STALE_REFERENCE, BLOCKED.
  9. Fallback/projected/legacy never satisfy canonical completion.
  10. Mark a target stale when its recorded canonical profile/reference SHA differs from active authority.
  11. Add explicit LEGACY 96 and 2.5D 128 browser roots or an equally unambiguous generation selector.
  12. Add an action×direction matrix sourced from the same target projection; selecting a matrix cell selects the identical AnimationSelection/authoring target as the tree.
  13. Preserve browser snapshot/race protections. Do not create another cache or progress database.
- Preserve: current legacy source/runtime paths; New Animation backend; Source Session behavior; publish/rollback; preview/timeline/motion; production runtime resources/selectors.
- Non-goals: no guided import; no Source Session orchestration; no Aseprite cleanup automation; no production runtime cutover; no network image generation; no automatic plan rank mutation.
- Acceptance: the real `unarmed/posture/idle_relaxed_01/full_body` `operator_2_5d_128` family appears as the first authored canonical target with eight direction leaves, 15 frames per direction, 128x128 cells, source SHA `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3` and design-reference SHA `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`; missing future 2.5D targets still appear before pixels exist; a legacy asset with the same semantic identity can coexist without source/workspace collision; matrix/tree select identical authoring identity; fallback/projected/legacy never satisfy canonical completion; stale profile/reference SHA is visible; current production runtime resources/selectors remain unchanged.
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
  "state": "authored",
  "migration_verdict": "canonical_2_5d"
}
~~~

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: This refresh records the exact locked design input and first authored canonical family. Keep WB25-1 blocked/manual only until the viability audit closes on the recorded decision and the refreshed canonical visual contract hardens both inputs, lands, and passes its paired review. Then bring the final viability counts plus accepted `operator_2_5d_128` profile/reference hashes back here and flip this packet to ready/auto without changing the already-locked first-family identity.

## Handoff

- Next workstream: operator-2-5d-animation-viability-audit
- Next packet state: ready/auto
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include the exact Authoring chat URL in every durable summary and final Next Handoff
- Refresh reason: The user/ChatGPT planning refresh is already complete. Exact design-lock and first-animation inputs plus the human visual decision are recorded; do not ask the planning chat for them again.
- Next action: Claim `operator-2-5d-animation-viability-audit` now; after it completes, claim `operator-2-5d-canonical-visual-contract`, then its paired review. Return only after those receipts land for WB25-1's final ready/auto flip.
- Blockers or open questions: No remaining art-direction ambiguity. Blocking only if audit closeout or exact-input canonical hardening/review discovers a real byte/provenance/profile conflict. The optional Textual pilot remains irrelevant.
