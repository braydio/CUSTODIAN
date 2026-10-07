# OPERATOR 2.5D RUNTIME PROMOTION

> PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION  
> Refresh only after WB25-5 + paired review land and real verified-family counts exist.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-runtime-promotion
- Status: draft
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-production-queue
- Locks: operator-runtime-animation, operator-art-generation-schema, operator-workbench-publish
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-runtime-promotion
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: conditional
- Goal: Add one fail-closed, rollbackable runtime generation policy so a fully verified 2.5D cohort can atomically replace the same legacy semantic runtime identities without mixing character generations or creating a second runtime animation database.
- Completion boundary: Introduce cohort generation policy, make the existing source→runtime sync choose one authoring generation per promoted cohort, prove complete-family gating/rollback, and update runtime authority/docs. Keep OperatorAnimationSelector and the one generated operator_runtime_frames.tres as execution authority.
- Current measured state: runtime identity is profile/group/action/direction/layer; sync_operator_runtime_assets.py + build_operator_runtime_frames.gd build one runtime manifest/SpriteFrames; OperatorAnimationSelector owns selection and still permits temporary SOUTH fallback. No art-generation policy exists and current canonical source paths are legacy-oriented.
- Evidence: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md; design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md; custodian/tools/pipelines/sync_operator_runtime_assets.py; custodian/tools/pipelines/build_operator_runtime_frames.gd; custodian/game/actors/operator/animations/operator_animation_selector.gd; generated runtime manifest/frames.
- Task-specific authority: reviewed WB25 queue/review receipts for verified canonical 2.5D families; operator_asset_schema.py generation-aware source paths; existing runtime sync/build/selector authority.
- Work surface: new custodian/content/data/operator/authoring/operator_art_generation_policy.json; sync_operator_runtime_assets.py; only the smallest runtime builder/selector changes proven necessary; runtime authority docs; focused runtime/path/spriteframes tests.
- Change:
  1. Add one machine-readable generation policy. It owns which authoring generation feeds runtime per named coherent cohort. Default remains legacy_96.
  2. Policy must never select generation independently per direction/frame. Cohort/family requirements are explicit.
  3. A cohort may promote to operator_2_5d_128 only when every required target family/direction/layer is canonical, current-profile/reference, human-reviewed where required, PUBLISHED and RUNTIME_VERIFIED.
  4. sync_operator_runtime_assets.py reads policy and scans the selected authoring generation for promoted identities, then writes the same existing canonical runtime paths/semantic identities.
  5. Runtime semantic identity remains profile/group/action/direction/layer. Do not add art_generation to gameplay request identity.
  6. Generated operator_runtime_manifest.generated.json and operator_runtime_frames.tres remain the sole runtime database.
  7. OperatorAnimationSelector remains the sole semantic selector. Do not add generation branching inside operator.gd or state controllers.
  8. Promotion is transactional/rollbackable. Before mutation, capture policy + affected generated/runtime hashes. Failure restores prior policy/runtime/generated artifacts exactly.
  9. Refuse partial cohort, stale review receipt, missing exact direction/layer, source collision, profile/reference mismatch, or dirty/pending publication state.
  10. Remove temporary SOUTH fallback only for a scope where the active runtime contract has complete exact directions and the existing authority permits scoped removal; do not globally delete fallback while other legacy cohorts still require it.
  11. Provide dry-run report listing every semantic runtime identity whose source generation would change and every required proof receipt.
  12. Update Workbench queue so promoted families show active runtime generation, without making runtime policy a second workflow database.
- Preserve: gameplay timing/hit windows; OperatorAnimationSelector ownership; one generated runtime SpriteFrames; legacy authoring source; rollback; weapon owner semantics; no runtime direct source PNG loading.
- Non-goals: no deletion of legacy source; no automatic whole-project 2.5D cutover; no gameplay-state redesign; no new animation resolver; no image generation; no silent mixed-generation fallback.
- Acceptance: with a disposable fully verified cohort fixture, dry-run lists exact affected identities; promotion rewrites only generated/runtime outputs to 2.5D source pixels while gameplay identity/API remains unchanged; an incomplete direction blocks before mutation; injected failure restores exact prior hashes; unrelated legacy cohort stays legacy; no second SpriteFrames/runtime DB appears; selector/runtime smokes remain green.
- Validation: focused generation-policy parser, complete/incomplete cohort gates, dry-run identity diff, successful promotion, injected rollback, unrelated-cohort preservation, runtime manifest and SpriteFrames rebuild, operator_runtime_animation_authority_smoke.py, operator_runtime_path_audit.py, operator_runtime_spriteframes_import_smoke.py, body-pair canonical smoke where selected, changed validation + git diff --check.
- Task overrides: none
- Deferred: bulk legacy deletion; global SOUTH-fallback retirement until all required production cohorts satisfy exact-direction authority; later asset cleanup.

## Recommended policy shape

~~~json
{
  "schema": "custodian.operator_art_generation_policy.v1",
  "default_generation": "legacy_96",
  "cohorts": {
    "unarmed_core": {
      "generation": "operator_2_5d_128",
      "required_families": [
        "unarmed/posture/idle_relaxed_01",
        "unarmed/posture/idle_ready_01",
        "unarmed/locomotion/walk_01",
        "unarmed/locomotion/run_01"
      ],
      "review_receipt_set_sha256": "..."
    }
  }
}
~~~

Builder selection should remain outside gameplay:

~~~python
generation = policy.generation_for(profile, group, action)
source_root = schema.authoring_source_root(generation)
# existing scan/sync then writes unchanged runtime identity/path
~~~

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: Bring WB25-5 review + live VERIFIED family/cohort counts to this chat. Decide the first actual promotion cohort, re-check current runtime sync/selector/fallback debt and authoring source layout, then refresh exact policy fields and tests before ready.

## Handoff

- Next workstream: review-operator-2-5d-runtime-promotion
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: first production cohort is intentionally not chosen until real WB25-5 verified coverage exists
