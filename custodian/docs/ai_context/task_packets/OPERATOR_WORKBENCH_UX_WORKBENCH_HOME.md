# OPERATOR WORKBENCH UX V1 - WORKBENCH HOME AND ALWAYS-ON PREVIEW

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> This is a planning packet based on `main@330422023f9a92362915af46b9658585e7c1d450`.
> Do not claim or implement it yet. Request a fresh OPUI repository/interface
> review after UX1 has landed. Remove this banner only after the packet is
> reconciled against current main and explicitly signed off for execution.

- Packet schema: `custodian.task_packet.v2`
- Series: `operator-workbench-ux-hierarchy-v1`
- Workstream: `operator-workbench-ux-workbench-home`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-ux-state-hierarchy`
- Locks: `operator-workbench-ui`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `330422023f9a92362915af46b9658585e7c1d450`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Roadmap: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
- Goal: Turn Page 2 WORKBENCH into the default visual animation-authoring home: navigation on the left, the selected animation as the dominant center object, and a compact actionable inspector/layer surface on the right.
- Completion boundary: Replace the current metadata-heavy 25/35/40 WORKBENCH layout with a preview-first cockpit, compact inspector/layer presentation, and workflow badges in the animation browser. Reuse existing preview composition/rendering authority. Deep source comparison, diff, transition analysis and examiner controls remain Page 3 REVIEW.
- Current measured state:
  - `ui/screens/main.py` currently allocates WORKBENCH mode as navigation 25%, AnimationDetail 35%, LayerTable 40%.
  - `AnimationDetail.show_session()` displays selected identity, presentation completeness, Workbench state, source/workspace/document frame counts, migration, dependency status, weapon context, workspace path and Aseprite executable.
  - `LayerTable` shows LAYER/LIVE/CONTRACT/CANVAS plus owner/profile/role/publish detail.
  - Page 3 already owns `PreviewCanvas`, `PreviewFilmstrip`, `PreviewControls`, source selection, exact raster rendering and deep review interactions.
  - `WorkbenchService.preview()` and `AnimationPreviewProvider` already provide semantic composed previews for workbench/canonical/runtime sources.
  - Live Bridge can provide matching unsaved Workbench preview and current layer visibility/focus.
  - Browser rows currently expose direction, frame count and composition completeness but not local workflow state such as modified/blocked/landing.
  - The prerequisite browser-snapshot hardening owns accepted browser state and refresh concurrency; row decoration in this slice must extend that accepted projection rather than re-discover source state during rendering/search.
- Evidence:
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/animation_detail.py`
  - `custodian/tools/operator/ui/widgets/layer_table.py`
  - `custodian/tools/operator/ui/widgets/animation_tree.py`
  - `custodian/tools/operator/ui/widgets/preview_canvas.py`
  - `custodian/tools/operator/ui/widgets/preview_controls.py`
  - `custodian/tools/operator/ui/widgets/preview_filmstrip.py`
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/animation_preview.py`
- Task-specific authority:
  - UX1 owns artist-facing workflow-state vocabulary.
  - The browser-hardening accepted snapshot remains browser authority.
  - `AnimationPreviewProvider` remains raster/composition authority.
  - Live Bridge remains unsaved live-document authority.
  - Workbench V2 remains canonical/workspace/publish authority.
- Work surface:
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/widgets/animation_tree.py`
  - `custodian/tools/operator/ui/widgets/animation_detail.py` or a focused replacement
  - `custodian/tools/operator/ui/widgets/layer_table.py` or a focused replacement
  - existing preview widgets/provider
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
- Change:
  1. Redesign WORKBENCH mode around approximately:
     - 24-28% animation navigation;
     - 46-54% preview;
     - 22-28% compact inspector/layers.
     Exact responsive sizing may follow Textual constraints after refresh; preserve the preview as the dominant surface.
  2. Reuse the existing `PreviewCanvas`/preview-provider pipeline for the Page 2 animation image. Do not create a second frame slicer, compositor or renderer.
  3. Page 2 preview source priority should answer "what am I editing now":
     - matching revision-guarded live Workbench preview when a connected matching Aseprite document has unsaved content and live preview is valid;
     - saved Workbench preview when a Workbench exists;
     - runtime preview when no Workbench exists;
     - canonical fallback if runtime is unavailable but canonical review is valid.
     Always label the visible source as LIVE, WORKBENCH, RUNTIME or CANONICAL.
  4. Keep Page 2 controls intentionally small: frame navigation, play/pause and current frame count are enough. Deep source switching, examiner, diff, seam/transition analysis and comparison remain REVIEW.
  5. Replace the large `AnimationDetail` primary panel with a compact inspector containing artist-relevant facts:
     - frames;
     - frame canvas;
     - authored FPS;
     - loop/non-loop;
     - publishing presentation layers;
     - pending frame/canvas contract change when present;
     - weapon context only when non-empty/relevant.
     Workspace paths, Aseprite executable paths, owner/profile metadata and dependency internals move to diagnostics/details.
  6. Replace the 40% LayerTable surface with a compact layer list/card. At minimum show:
     - semantic layer;
     - publishing vs reference;
     - live visibility/focus marker when available;
     - concise frame/canvas mismatch only when it matters.
     Selecting a layer may reveal owner/profile/role/source-workspace-publish detail in a secondary inspector, but those details must not consume the default layout.
  7. Preserve current Live Bridge show/hide and layer focus actions for manifest-authorized layers.
  8. Decorate browser direction rows with workflow state from UX1 and the accepted snapshot/local Workbench projection. Priority labels include:
     - modified;
     - unsaved;
     - blocked;
     - landing pending;
     - partial;
     - reference/legacy;
     - clean/published only when useful.
     Do not require a source-index rescan on each tree paint or search keystroke.
  9. Keep composition completeness, but demote verbose layer-composition strings when a stronger workflow badge exists. Technical composition remains inspectable.
  10. Preserve Page 3 REVIEW as the deep visual forensic surface. Reuse state where sensible so entering REVIEW starts on the same semantic selection/frame instead of feeling like a different tool.
  11. Ensure preview failure affects the preview panel and diagnostic message only. It must not erase the selected browser/session state.
  12. If FX adoption has landed, compact layers may show an unbound saved `vfx/fx` candidate and its existing explicit Adopt as FX action. Do not reimplement adoption.
  13. Update the roadmap immediately if refreshed main already extracted generic preview widgets for Asset Workbench; reuse live generic primitives rather than moving them again.
- Preserve:
  - Exact preview pixel fidelity and renderer policy.
  - Existing Page 3 REVIEW feature depth.
  - Browser accepted-snapshot/race guarantees.
  - Existing Live Bridge layer-control restrictions.
  - Existing Workbench edit/frame/canvas/publish/validate actions.
  - UX1 status vocabulary and compact Activity behavior.
- Non-goals:
  - No deep REVIEW feature redesign.
  - No motion/timeline behavior change.
  - No work queue redesign.
  - No Publish modal redesign.
  - No new source/runtime composition rules.
  - No arbitrary layer adoption.
  - No art/runtime changes.
- Acceptance:
  - WORKBENCH opens with the selected animation visually dominant, not with metadata occupying 75% of the content width.
  - A modified saved Workbench displays its saved pixels in the Page 2 preview by default.
  - A matching unsaved live Aseprite document, when live preview is valid, visibly labels and displays LIVE content without making unsaved pixels publication authority.
  - No-Workbench selections fall back to runtime/canonical review without crash.
  - The compact inspector displays frames, canvas, FPS, loop and publishing layers while raw paths/debug internals are hidden by default.
  - Layer visibility/focus controls remain functional from the compact presentation.
  - Browser rows visibly distinguish at least modified, blocked/landing, partial and ordinary clean states without color-only meaning.
  - Search continues to filter accepted in-memory browser projections and does not rescan the repository.
  - Page 3 REVIEW continues to provide existing examiner/diff/transition behavior with the same selected identity.
  - Preview failure does not clear navigation/session state.
- Validation:
  - Extend `operator_workbench_ui_smoke.py` for dominant Page 2 preview, source priority, compact inspector/layers, workflow badges, preview failure preservation and shared selection/frame handoff to REVIEW.
  - Run focused preview/Live Bridge smokes selected by validation ownership.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Task overrides: `none`
- Deferred:
  - UX3 Publish decision modal.
  - UX4 work queue.
  - UX5 final cross-mode closeout.

## Execution Feedback

Complete only after the refresh banner has been removed and implementation is actually executed.

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: Bring the landed predecessor/review evidence and any material live-main drift back to this conversation. Re-derive the packet here with the user before promoting it to implementation-ready; do not let the execution agent silently reinterpret architecture, scope, sequencing, or acceptance.

## Handoff

- Next action: after UX1 lands, request the mandated refresh and reconcile the actual shell/state projection before making this packet ready.
- Best starting files: `ui/screens/main.py`, `ui/widgets/animation_detail.py`, `ui/widgets/layer_table.py`, `ui/widgets/animation_tree.py`, `ui/app.py`, and the existing preview widgets/provider.
- Blockers or open questions: implementation is intentionally blocked until refresh/sign-off.