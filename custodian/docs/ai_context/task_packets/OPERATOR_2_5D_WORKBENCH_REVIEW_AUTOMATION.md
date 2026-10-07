# OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION + RUNTIME SANDBOX

> PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION  
> Refresh after WB25-3 + paired review land.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-review-automation
- Status: draft
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-polish-automation
- Locks: operator-workbench-ui, operator-art-agent, operator-review-automation, operator-runtime-preview
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow, visual, runtime
- Paired review workstream: review-operator-2-5d-workbench-review-automation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: conditional
- Goal: Make canonical anti-drift checks, 8-direction family review, transition/sequence review, and a bounded real-Godot sandbox one guided acceptance path so 2.5D art can become RUNTIME_VERIFIED without touching production generation selection.
- Completion boundary: Project canonical + temporal QA into Workbench, add family/sequence presets, structured review receipts, and a debug sandbox consuming selected 2.5D pixels. No production selector/catalog policy change.
- Current measured state: Preview/Review/Sequence/Motion exist; saved sequences live under .ai/operator_animation_workbench/sequences; canonical QA/metrics exist; Motion request uses .ai/operator_animation_workbench/motion_lab_request.json. Production Operator selection still consumes one generated operator_runtime_frames.tres and must remain unchanged here.
- Evidence: design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md; custodian/tools/operator/animation_preview.py; custodian/tools/operator/animation_motion_preview.py; custodian/tools/operator/ui/service.py; custodian/tools/operator/ui/app.py; custodian/tools/operator/art_agent/qa.py; design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md.
- Task-specific authority: accepted canonical profile/reference; landed WB25-1 target state; WB25-3 diagnostics; existing Sequence/Motion review semantics; gameplay timing/contact metadata for action cadence.
- Work surface: custodian/tools/operator/ui/service.py; ui/app.py; state.py; animation_preview.py; animation_motion_preview.py; recommended focused owner custodian/tools/operator/operator_2_5d_review.py; recommended debug-only custodian/tools/operator/runtime_preview/operator_2_5d_sandbox.gd + .tscn if current Motion owner cannot safely host it; focused UI/preview/runtime tests.
- Change:
  1. Selected 2.5D leaf shows structured canonical QA: registration, body geometry/proportion, alpha/components, palette/brightness, silhouette/outline, F01 fidelity, temporal findings, profile/reference SHA.
  2. Consume existing HARD_FAIL / STRUCTURAL_WARN / ART_DIRECTION_WARN / INFO findings. Do not duplicate metric algorithms in UI.
  3. Stale profile/reference SHA blocks review completion/publication until explicit refresh/re-normalization.
  4. Add FAMILY REVIEW for an action: one 8-direction × frame contact/animation surface sourced from target projection; missing/projected/fallback cells remain visibly incomplete.
  5. Add sequence presets when identities exist:
     idle→walk→idle;
     relaxed→draw→ready;
     fast01→02→03→04→ready;
     block enter→hold→hit→hold;
     dodge→recovery.
  6. Use authored timing/contact/motion data. Never hard-code combat windows simply for review.
  7. Add one structured per-leaf review receipt distinguishing PUBLISHED from RUNTIME_VERIFIED and recording art generation/profile/reference SHA.
  8. Add bounded Godot sandbox/runtime proof. It may instance the real Operator scene and real camera/world context, but selected 2.5D pixels are owned by a debug-only preview presenter. Do not modify OperatorAnimationSelector, generated runtime manifest, production operator_runtime_frames.tres, or gameplay semantics.
  9. Sandbox preserves Operator world position, BlobShadow/fake elevation, camera, and presentation scale. It may temporarily hide normal body presentation through an explicit debug owner, then restore it cleanly.
  10. Sandbox must accept full_body 128 art directly; do not force new 2.5D full-body work into old lower/upper modular layers.
  11. Subjective unresolved art direction produces one compact visual-review handoff only after objective checks.
- Preserve: production Operator selection/resources; gameplay timing; sequence editor; Motion ownership; Workbench publication; legacy preview/comparison.
- Non-goals: no runtime generation cutover; no combat balance/timing changes; no second QA engine; no automatic visual approval; no network generation.
- Acceptance: stale reference blocks; a complete 8-direction family renders a truthful family matrix; missing/fallback cell stays incomplete; sequence presets use authored timing; sandbox shows selected full_body 128 art on the real Operator context while a byte/hash diff proves production runtime resources/catalog unchanged; receipt can distinguish PUBLISHED from RUNTIME_VERIFIED.
- Validation: focused stale-hash, family-state, sequence-order/timing, full-body sandbox, sandbox teardown and production-runtime no-diff fixtures; use existing operator_workbench_ui_smoke.py and Motion/preview smokes; smallest Godot smoke proving sandbox ownership/cleanup; changed validation + git diff --check.
- Task overrides: none
- Deferred: throughput queue, generation briefs, production cutover.

## Recommended sandbox boundary

Prefer a debug-only adapter rather than new operator.gd state:

~~~text
Workbench selection
  → .ai runtime preview request
  → debug-only preview presenter
  → actual Operator scene / camera / shadow
  → selected 2.5D body visible
  → teardown restores normal presenter

Production selector/catalog/resource bytes unchanged.
~~~

A request record should be hash-bound:

~~~json
{
  "schema": "custodian.operator_2_5d_runtime_preview.v1",
  "authoring_identity": "operator_2_5d_128:unarmed/posture/idle_relaxed_01/ne",
  "source_sha256": "...",
  "frames": 15,
  "frame_size": [128,128],
  "fps": 12,
  "loop": true
}
~~~

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: Bring WB25-3 + review evidence and live QA/polish APIs back to this chat. Re-derive receipt shape, family-review projection, sequence integration, sandbox seam, exact Godot files and focused tests before ready.

## Handoff

- Next workstream: review-operator-2-5d-workbench-review-automation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: packet must be refreshed before claim
