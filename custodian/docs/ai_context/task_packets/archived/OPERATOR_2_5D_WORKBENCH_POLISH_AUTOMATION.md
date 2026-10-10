# OPERATOR 2.5D WORKBENCH POLISH AUTOMATION

> COMPLETE / IMPLEMENTATION LANDED
> WB25-2 and its final cycle-2 correction/re-review are complete. Consume the accepted Source Session→Workbench handoff, physical saved-document checks, and exact Art Agent seams below; do not recreate a second workspace, registration authority, or mutation path.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-polish-automation
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-ingress-review-corrections-2
- Locks: operator-art-agent, operator-aseprite-tooling, operator-workbench-ui
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow, visual
- Paired review workstream: review-operator-2-5d-workbench-polish-automation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: c447db62d5c6f434394d6c634e1e191952658cc5
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: conditional

## Agent Handoff / Planning Decisions — 2026-10-09

**This is the final pre-claim planning refresh for WB25-3. WB25-2 correction 2 and its fresh cycle-2 review are accepted with zero remaining findings. Do not reopen ingress identity, package recovery, or saved-document contract questions unless current main contradicts the accepted evidence.**

### Accepted predecessor truth

- `Operator2DIngress.target_binding()` owns the exact 2.5D target binding: art generation, semantic identity, direction/layer, accepted profile/reference SHA, frames and 128x128 frame size.
- Accepted authority remains profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761` and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.
- An accepted intake cell terminates at `EDITABLE_WORKBENCH` with durable Source Session, reviewed-candidate SHA, staged handoff and exact direction-level Workbench receipt.
- `Operator2DIngress._validate_workbench()` plus `animation_workbench.inspect_saved_document_contract()` now prove the **physical saved Aseprite document** matches frame count, canvas and uniform timing before READY recovery, completed reuse or package closure. Polish must reuse this read-only inspection contract; it must never silently reconcile a mismatched document.
- Legitimate artist pixel edits inside a valid saved Workbench are preserved byte-for-byte through ingress recovery. WB25-3 must retain that property.
- 2.5D publication remains unconditionally unavailable before WB25-6. Polish operates only on the ignored editable Workbench.

### Art Agent seams to adapt, not replace

- `ArtAgentService.apply_operation()` is the sole bounded mutation transaction. Existing mutation primitives already include `move_region`, `erase_pixels`, `clear_masked_region`, edit scopes, exact before/after workbench hashes, backups/journals and `undo_last()`.
- `ArtAgentService.start_session()` still resolves through the legacy generic Workbench path. **Do not use it to recreate/re-resolve a 2.5D Workbench.** Add one narrow existing-Workbench attach/start seam that accepts the exact landed manifest/document, validates it without repair, and creates the ordinary Art Agent capability/session around those files.
- Art Agent registration helpers currently default to the legacy profile unless a caller supplies a profile id. The existing Workbench manifest already records `creation.art_generation`; derive the default registration profile from that bound manifest. For `operator_2_5d_128`, use the accepted `operator_2_5d_128` profile automatically. Preserve current legacy-96 defaults for ordinary legacy sessions.
- Do not create a second generation/profile field as an independent authority merely for polish. The exact Workbench manifest/target binding remains authority; any cached session projection must be backward-readable and must fail if it disagrees.
- `metrics.py` already owns frame alpha bbox, size, centroid, lowest/highest occupied pixels, width/height, palette size, per-frame pixel SHA, isolated single pixels, landmark trajectories and landmark loop-seam metrics. Extend this owner rather than creating a second metrics schema.
- `qa.py` already owns structural/registration/pixel/animation findings. Add objective polish findings there only where they are generally reusable; keep operation proposals/orchestration in the WB25-3 owner.

### Registration and reference decisions

- There is **no durable repository taxonomy** today saying every semantic action is `planted` versus `root_motion`. WB25-3 must not invent one.
- Planted registration is an **explicit per-operation user choice**, default off. Obvious locomotion-family targets must refuse it. If approved foot/support landmarks or masks are insufficient, return `NO_PROPOSAL`; never fall back to lowest-alpha/root guessing.
- Once explicitly enabled, frame 1 is only the within-animation registration authority for that operation. It is not universal anatomy/pose authority.
- The semantic root remains `[64,106]` with ground/shadow `[64,107]`. Lowest visible alpha and head-top equality are not registration authority.
- “F01/reference diff” means drift against the exact Workbench/session baseline or an explicit approved reference record. **Do not pixel-diff arbitrary attack/crouch poses against the normalized design-lock turnaround and call that correctness.** The normalized reference remains projection/profile identity authority, not a mandatory per-action pose template.
- Timing is whatever the exact saved Workbench contract owns. WB25-3 does not invent or retime FPS.

### Mutation safety

- Every automatic polish proposal must show the exact frames/layer/pixels or source rectangle, predicted dx/dy, and affected bounds before apply.
- Before any apply, set a narrow Art Agent edit scope for the exact target frames/layer and only the operation types needed by that proposal.
- Registration translation uses existing `move_region` semantics on the legal body binding and must fail if the translated occupied rectangle would leave the legal frame.
- Tiny detached-island removal should use existing `erase_pixels` or `clear_masked_region`, never broad palette/repaint cleanup.
- Temporal outline/highlight coherence is **diagnostic only** in WB25-3. It may localize unstable bright/dark/boundary clusters, but it must not auto-recolor, blur or repaint them.
- After each mutation, the saved document must still satisfy the same physical frame/canvas/timing contract; mutation journal + undo remain the recovery authority.

- Goal: Turn the useful one-off Aseprite cleanup/registration tricks proven while authoring idle_relaxed_01 into safe Workbench/Art-Agent operations so a 2.5D strip can be aligned, inspected and polished without hand-running bespoke scripts or destroying intentional motion.
- Completion boundary: Add objective temporal/pixel diagnostics plus bounded preview/apply operations for planted-foot registration, detached islands and outline/highlight coherence, using existing ArtAgent/Aseprite mutation authority. Do not add autonomous anatomy redraw, image generation, publication, review sequencing or runtime cutover.
- Current measured state: WB25-2 guided ingress is complete through correction 2 and a clean final re-review. Exact target-bound Source Sessions now reach direction-level 2.5D Workbenches, and physical saved-document frame/canvas/timing proof is enforced before recovery/completion while preserving legitimate pixel edits. ArtAgentService already supports hashed/journaled bounded Aseprite mutations, edit scopes, masks/drafts, render/contact/onion/diff products and undo, but `start_session()` still resolves through the legacy generic Workbench path and Art Agent registration/QA defaults remain legacy-profile-shaped unless callers explicitly select a profile. `metrics.py` reports bbox/size/centroid/width/height/single isolated pixels and landmark trajectories, but not connected-component bounds/area or the required temporal silhouette/outline/highlight diagnostics.
- Evidence: `OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`; `REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`; `operator_2_5d_ingress.py::target_binding/_validate_workbench/_validate_ready_proof`; `animation_workbench.py::inspect_saved_document_contract`; `art_agent/service.py::start_session/apply_operation/undo_last/registration_profile/registration_report/registration_overlay/run_qa`; `art_agent/models.py::ArtSession`; `art_agent/metrics.py`; `art_agent/qa.py`; `art_agent/registration_profile.py`; `operator_live_bridge/art_agent_ops.lua`; `ui/service.py::workspace/session`; active Art Agent and Workbench design authority.
- Task-specific authority: the accepted WB25-2 target-bound Source Session → exact direction Workbench handoff and physical-document inspection contract; canonical `operator_2_5d_128` profile/reference for registration/projection; `ArtAgentService` + live/headless bridge for bounded mutation/journal/undo; Workbench manifest/document for exact identity/frame/timing; existing metrics/QA modules for reusable objective diagnostics.
- Work surface: new pure analysis/orchestration owner `custodian/tools/operator/operator_2_5d_polish.py`; `art_agent/service.py` for one existing-Workbench session attach seam and generation-derived registration-profile selection; `art_agent/metrics.py` and `qa.py` for reusable objective metrics/findings; `art_agent/models.py` only if a backward-readable session projection is strictly needed; existing Aseprite mutation bridge/ops only if a missing primitive is proven (prefer current `move_region`/`erase_pixels`/`clear_masked_region`); `ui/service.py` plus one bounded POLISH panel/widget; focused Art Agent/2.5D/UI validation. Do not touch runtime selectors/resources/publisher.
- Change:
  1. Add one Workbench POLISH surface for exact `operator_2_5d_128` selections. It accepts the current `AnimationSelection` / exact direction Workbench receipt; it never scans arbitrary PNGs or reconstructs identity from filenames.
  2. Add an Art Agent **attach existing Workbench** entrypoint. It must validate the supplied `workbench.json` + `workbench.aseprite` under the configured Workbench root, preserve the existing file bytes, bind ordinary Art Agent capability/hash/undo state to that exact document, and refuse identity/generation/frame/canvas/timing disagreement. The legacy `start_session()` behavior remains unchanged.
  3. Resolve the Art Agent registration profile from the bound Workbench generation when no explicit profile id is supplied. `operator_2_5d_128` sessions use the accepted 128 profile for registration profile/report/overlay and QA structural context; legacy sessions remain legacy-96 by default. Do not duplicate registration coordinates/hashes in polish code.
  4. Reuse `inspect_saved_document_contract()` before attach/analyze/apply and prove the same frame/canvas/uniform-timing contract after mutation. A mismatch is read-only/fail-closed; do not invoke reconciliation from POLISH.
  5. Extend reusable metrics with deterministic connected opaque components (area + bounds), adjacent-frame alpha/silhouette delta, external-boundary delta, localized luminance/color delta for configurable semantic masks/regions, and explicit last-frame→frame-1 loop seam metrics. Preserve existing metric fields/schema compatibility or version additively.
  6. Add a baseline/reference comparison that can compare frame 1/current frames against the Workbench session baseline or explicit approved reference record. Report exact diff metrics/bounds; never treat the normalized design-lock turnaround as a mandatory pose match for arbitrary actions.
  7. Add planted-registration **proposal only** behind an explicit per-operation `planted/stationary` opt-in. Default is disabled. Refuse at least `group=locomotion` and any target already carrying contrary motion evidence. Require current approved support/foot landmarks or masks; if absent, return `NO_PROPOSAL`. Frame 1 supplies within-animation support authority. Produce integer dx/dy per frame only; never use lowest alpha/head top as root.
  8. Add manual Center X preview. It is never automatic, uses current visual bounds only as an explicit artist aid, warns/refuses obvious locomotion/root-motion usage, and does not redefine semantic root.
  9. Add detached-component proposals. An automatic erase candidate must be tiny (acceptance fixture: 3 pixels; implementation threshold must remain narrowly bounded), fully separated from the main body component, outside protected semantic landmarks/masks, and represented as exact pixels/bounds. Larger/ambiguous components are diagnostic only.
  10. Temporal outline/highlight analysis reports unstable external-boundary or semantic-region bright/dark clusters and their frames/bounds. It does not auto-recolor, blur, smooth, palette-normalize or repaint.
  11. Every apply operation sets a narrow Art Agent edit scope and translates the approved proposal to existing `move_region`, `erase_pixels`, or `clear_masked_region` operations where possible. One apply = one ordinary Art Agent transaction/operation key with before/after hashes, changed bounds, journal receipt and `undo_last()` ownership. Add a new bridge primitive only if current confined primitives cannot safely express the exact proposal.
  12. Add Open/Refresh in Aseprite and canonical registration-guide/ghost actions by reusing existing guide/profile authority. Reserved `__ART_GUIDE_*` / reference layers remain nonpublishing and clean renders exclude them.
  13. Keep WB25-3 publication-free. No POLISH action may invoke 2.5D publish/runtime sync, mutate canonical source, or mark queue/runtime completion. Those remain later slices.
- Preserve: WB25-2 exact target/Source Session/WorkBench receipts and physical saved-document proof; legitimate artist pixel edits; accepted profile/reference/root semantics; existing Art Agent capability confinement, stale/hash checks, live-bridge ownership, edit scopes, journal/undo; legacy-96 session behavior; guide exclusion; Workbench publisher as sole future canonical/runtime mutation authority; intentional animation motion.
- Non-goals: no persistent planted/root-motion taxonomy; no pose synthesis; no anatomy warping; no per-frame scaling; no free rotation; no network/image generation; no automatic palette redesign/recolor/blur; no Source Session normalization redesign; no publication; no canonical source/runtime mutation; no WB25-4 family/sequence acceptance.
- Acceptance: (1) an accepted WB25-2 `EDITABLE_WORKBENCH` can be attached to Art Agent without recreating/reconciling it, and a tampered identity/generation/physical frame/canvas/timing contract refuses without changing document/candidate/handoff bytes; (2) attached 2.5D registration/QA automatically selects the accepted `operator_2_5d_128` profile while a legacy fixture remains legacy-96; (3) a synthetic 15f/128 explicitly-planted idle with approved support evidence and ±2px accidental registration jitter receives deterministic integer proposals while intentional breathing remains; (4) a locomotion/root-motion negative fixture and a planted fixture lacking semantic support evidence receive no registrar proposal; (5) a 3px detached island is localized to exact pixels and can be removed in one scoped, journaled, undoable transaction while a landmark/mask-intersecting or larger component is refused for automatic removal; (6) frame-1 baseline drift, adjacent silhouette jitter, loop-seam drift and shoulder-highlight flicker fixtures produce localized objective metrics/findings without mutating art; (7) a registration apply uses the existing confined mutation path, preserves frame/canvas/timing and can be undone exactly; (8) guide/reference layers remain excluded from clean/publish candidates; (9) no canonical source/runtime/publisher bytes change.
- Validation: add one focused `operator_2_5d_polish` smoke owning existing-Workbench attach/profile selection, physical-contract refusal, planted opt-in/no-evidence/locomotion negatives, connected-component proposal/refusal, temporal metrics, scoped move/erase transactions, undo and no-publication invariants. Re-run `operator_2_5d_ingress`, `operator_art_agent_service`, `operator_art_agent_aseprite`, `operator_art_registration_profile`, `operator_animation_workbench`, and Textual-enabled `operator_workbench_ui` where affected; include a legacy-96 regression. Finish with `run_validation.py --changed --json`, Python compile checks and `git diff --check`. Visual handoff only if objective evidence leaves a material subjective art-direction question.
- Task overrides: none
- Deferred: sequence/family acceptance; Godot sandbox; production queue; runtime promotion.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/tools/operator/operator_2_5d_ingress.py,custodian/tools/operator/animation_workbench.py,custodian/tools/operator/ui/service.py,custodian/tools/operator/art_agent/service.py,custodian/tools/operator/art_agent/models.py,custodian/tools/operator/art_agent/metrics.py,custodian/tools/operator/art_agent/qa.py,custodian/tools/operator/art_agent/registration_profile.py,custodian/tools/operator/art_agent/edit_scope.py,custodian/tools/operator/art_agent/aseprite_bridge.py,custodian/tools/aseprite/operator_live_bridge/art_agent_ops.lua,custodian/tools/aseprite/operator_art_agent.lua,custodian/tools/validation/operator_2_5d_ingress_smoke.py,custodian/tools/validation/operator_art_agent_service_smoke.py,custodian/tools/validation/operator_art_agent_aseprite_smoke.py,custodian/tools/validation/operator_art_registration_profile_smoke.py,custodian/tools/validation/operator_workbench_ui_smoke.py,custodian/content/data/operator/authoring/operator_art_profile.json,design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md,design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md,design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md`
- Purpose: `exact WB25-2 handoff + physical-document authority, Art Agent session/mutation/profile owners, existing bridge primitives, affected validation and active polish/workbench design`

Generate once from the claimed worktree with:

```bash
scripts/ai/pack-context.sh task "<Include value above>" "operator-2-5d-workbench-polish-automation"
```

Use the coordination-root CRG only for baseline architecture orientation; the current worktree and exact live files remain implementation truth.

## Recommended code shape

Keep diagnostics pure and mutation delegated:

~~~python
@dataclass(frozen=True)
class PolishFinding:
    code: str
    severity: str
    frame: int | None
    bounds: tuple[int, int, int, int] | None
    metric: float | None
    message: str
    proposed_operation: dict | None = None

@dataclass(frozen=True)
class PolishTarget:
    authoring_identity: str
    manifest_path: Path
    document_path: Path
    art_generation: str
    profile_id: str
    frames: int
    frame_size: tuple[int, int]
~~~

The orchestrator should attach to the exact Workbench, obtain clean frame renders
through Art Agent, produce pure findings/proposals, then require an explicit apply
call. Proposal generation never mutates.

A planted-registration proposal should look like data, for example:

~~~json
{
  "kind": "planted_registration",
  "authority_frame": 1,
  "motion_policy": "explicit_planted",
  "evidence": "semantic_support_mask",
  "anchor": [64, 106],
  "offsets": [{"frame": 2, "dx": 0, "dy": -1}],
  "mutates": false
}
~~~

The apply path converts approved offsets/components into the existing confined
Art Agent operations and rechecks the physical Workbench contract afterward.

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh status: **consumed / final pre-claim refresh complete**
- Refresh instruction: WB25-2 correction 2 + final re-review and the live Source Session→Workbench/Art Agent seams have been consumed. WB25-3 is now `ready/auto`. Re-open planning only for a real contradiction in the accepted target/workbench/profile/mutation authorities or a new human-owned art-direction choice.

## Completion Truth

- Completion schema: custodian.task_completion.v1
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: WB25-3 implementation, focused smoke, 29/29 changed validations, compiled Python modules, and clean diff checks are recorded in `OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_CLAUDE_SUMMARY.md`.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The initial integration exposed a legacy test fixture with no session projection and a mode-contract checker that required POLISH to be named in the active-mode map and cheatsheet. A few UI service imports also had a misspelled module path; focused validation caught and corrected it before landing.
- Root cause / contributing factors: New mode wiring and generation-derived defaults crossed existing UI and legacy compatibility contracts that were not visible from the new panel alone.
- Prevention / pipeline improvement: Keep the active mode contract and operator cheatsheet in scope when adding a numbered UI mode; retain the legacy-profile regression fixture and import path in the focused polish smoke.
- Tooling / docs drift discovered: Optional Textual UI interaction pilot is skipped when Textual is not installed; service/UI smoke remains runnable. The paired review runner was previously observed to mishandle an `origin/main:<path>` post-review source path; unrelated to WB25-3 and deferred.
- Follow-up: review-operator-2-5d-workbench-polish-automation
- What worked: Changed-file coverage selected the new focused smoke and all affected unit/integration/moment owners.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-polish-automation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: WB25-3 is fully refreshed; paired review should claim automatically after implementation lands.
- Next action: Claim `review-operator-2-5d-workbench-polish-automation` in a fresh reviewer context and verify the durable metrics, target-bound attach, proposal gates, scoped mutations/undo, and publication boundary.
- Blockers or open questions: none at planning level. Subjective art-direction questions, if any survive objective metrics, use the packet's conditional visual-review handoff rather than autonomous aesthetic approval.
