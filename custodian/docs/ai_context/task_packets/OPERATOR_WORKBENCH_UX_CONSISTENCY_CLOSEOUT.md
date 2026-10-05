# OPERATOR WORKBENCH UX V1 - CONSISTENCY AND UX CLOSEOUT

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> This remains a refresh-gated planning packet originally based on `main@330422023f9a92362915af46b9658585e7c1d450`; the background-sync addendum below was re-reviewed against `main@09706b79318aa627ea5474205884a8d8e53d8292`.
> Do not claim or implement it yet. Request a fresh OPUI repository/interface
> review after UX4 has landed. Remove this banner only after the packet is
> reconciled against current main and explicitly signed off for execution.

- Packet schema: `custodian.task_packet.v2`
- Series: `operator-workbench-ux-hierarchy-v1`
- Workstream: `operator-workbench-ux-consistency-closeout`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `operator-workbench-ux-work-queue`
- Locks: `operator-workbench-ui`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `09706b79318aa627ea5474205884a8d8e53d8292`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Background-sync addendum chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Roadmap: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
- Goal: Close UX Hierarchy V1 by making the five OPUI modes feel like one coherent animation workstation: consistent terminology, focus/navigation, responsive layout, warning hierarchy, progressive diagnostics, help/key hints, accessibility, and final regression coverage.
- Completion boundary: Perform a cross-mode interface/interaction audit after UX1-4 land, fix only inconsistencies and usability defects revealed by that audit, reconcile current docs, and close the roadmap. Do not add a new backend feature family or speculative framework.
- Current measured state:
  - Baseline OPUI has five mode-specific surfaces but many keyboard bindings are globally registered and filtered only by mode/context.
  - `ContextKeyBar` already solves the prior all-bindings Footer problem by showing mode-local hints.
  - Page-specific widgets currently use different density and information styles.
  - Global Activity, status, browser, Publish and preview hierarchy will have been changed by UX1-4 before this packet is eligible.
  - FX adoption may add saved unbound/adoptable layer state that must fit the final inspector language without becoming a separate workflow.
  - Asset Workbench may independently extract generic preview primitives before this closeout; do not move shared code again unless refreshed current main proves duplication remains.
  - The `operator-workbench-background-base-sync` prerequisite is expected to make routine ahead-zero repository lag self-healing while preserving provably Workbench-owned unpublished bytes. Final UX must not regress this into a manual sync chore or expose raw `behind N` commit distance as animation-change count.
- Evidence:
  - `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
  - landed UX1-4 implementation
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/context_key_bar.py`
  - all current Operator UI widgets/dialogs after refresh
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
- Task-specific authority:
  - UX1 owns artist-facing workflow vocabulary.
  - UX2 owns preview-first WORKBENCH.
  - UX3 owns Publish information hierarchy.
  - UX4 owns QUEUE.
  - Existing REVIEW/SEQUENCE/MOTION backend semantics remain authoritative.
  - `operator-workbench-background-base-sync` remains the sole launch-time base-reconciliation authority; UX1/UX3 own its artist-facing vocabulary/projection.
  - This slice owns consistency/polish and final UX validation only.
- Work surface:
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/**`
  - `custodian/tools/operator/ui/dialogs/**`
  - `custodian/tools/operator/ui/state.py` only for final projection consistency if needed
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `custodian/tools/validation/validation_manifest.json` if focused ownership changed
  - active Workbench design/current-state/file-index docs
- Change:
  1. Audit all five user-facing modes using the locked vocabulary:
     - QUEUE;
     - WORKBENCH;
     - REVIEW;
     - SEQUENCE;
     - MOTION.
     Remove stale PLAN/PREVIEW/TIMELINE labels from primary UI/help while preserving internal keys if useful.
  2. Audit focus behavior and shortcut routing:
     - mode switches retain meaningful semantic selection;
     - text-entry widgets retain native editing shortcuts;
     - mode-specific shortcuts do not fire from inappropriate modes;
     - modal close returns focus to the useful originating control;
     - existing contextual Ctrl+R behavior remains correct.
  3. Audit shared selection/frame continuity:
     - QUEUE -> WORKBENCH opens intended semantic direction;
     - WORKBENCH -> REVIEW preserves selection and sensible frame;
     - REVIEW -> SEQUENCE add/open actions preserve intended identity;
     - MOTION follows selection without silently rewriting review state.
  4. Audit layout at at least three terminal sizes representing compact, normal and wide use. Establish minimum pane widths and graceful collapse/stack behavior so the preview and primary workflow state remain usable without horizontal information soup.
  5. Audit information-tier discipline:
     - Tier 1 artist-critical state is never hidden behind diagnostics;
     - Tier 3 paths/hashes/checkout internals do not leak back into normal surfaces;
     - raw `ahead N / behind N` remains repository-history diagnostics and is never framed as animation-change count, artist workload, or a routine manual-sync task after safe reconciliation succeeds;
     - blockers automatically promote exact useful reasons;
     - successful debug checks remain quiet.
  6. Audit error/empty/loading states for every mode. No mode should present stale prior content as current after a failed load. Preserve accepted browser/session state where the existing hardened contract requires it.
  7. Audit Activity behavior:
     - INFO stays compact;
     - WARN/ERROR is visible;
     - full history remains available;
     - dialogs do not swallow underlying activity updates.
  8. Audit accessibility/readability:
     - no critical state is communicated by color alone;
     - status symbols have text labels;
     - selected/focused state remains distinguishable;
     - dim/debug content remains readable enough when explicitly opened;
     - button labels use user intent rather than backend jargon.
  9. Audit contextual key-bar density. Keep only actions relevant to the active mode and avoid horizontally overflowing with low-frequency debug actions. Rare commands belong in Help/Details when needed.
  10. Reconcile FX-adoption UI if that prerequisite landed:
      - unbound/adoptable `vfx/fx` state should fit the compact layer/inspector hierarchy;
      - unsaved unbound layers must remain clearly non-publishable until Save;
      - do not invent general new-layer adoption.
  11. Reconcile any shared preview widget extraction landed by Asset Workbench. Use the live authority; do not perform speculative framework work solely for symmetry.
  12. Add/update headless Textual Pilot coverage for the full cross-mode happy path and the highest-risk focus/status transitions.
  13. Update `OPERATOR_ANIMATION_WORKBENCH.md` to describe the final user-facing cockpit truth, not the implementation history.
  14. Update `CURRENT_STATE.md` and `FILE_INDEX.md` only with concise current truth.
  15. Mark all five roadmap slices complete only after focused validation plus explicit human visual sign-off on the refreshed terminal UI. Record the final main SHA and any intentionally deferred UX debt.
- Preserve:
  - All backend runtime/publication semantics.
  - Existing hardened browser/readiness/recovery behavior.
  - Exact preview fidelity.
  - Existing timeline/motion semantics.
  - UX1-4 information hierarchy.
  - Asset Workbench ownership boundaries.
- Non-goals:
  - No new animation/runtime/art behavior.
  - No new Git/worktree architecture.
  - No new Asset Workbench feature.
  - No generic design-system/framework rewrite.
  - No speculative animation-plan editor.
  - No autonomous art generation.
- Acceptance:
  - The five modes use consistent user-facing terminology everywhere visible.
  - Mode/focus shortcuts behave correctly with text-entry, modal and non-applicable contexts.
  - Selection/frame continuity works across the documented cross-mode transitions.
  - Compact, normal and wide terminal fixtures remain usable without hiding primary state or producing unreadable overlapping panes.
  - All critical statuses have text meaning independent of color.
  - Debug paths/hashes/checkout internals remain available but are not primary visual noise; raw ahead/behind commit counts stay in that diagnostic tier.
  - Routine safe repository lag resolves behind the scenes and leaves the cockpit at `MAIN READY`; only genuinely unsafe reconciliation presents `MAIN BLOCKED` with a concise reason.
  - WARN/ERROR activity surfaces promptly while INFO remains compact.
  - Empty/loading/error states do not masquerade as valid stale content.
  - FX-adoption state, if present, is integrated without introducing new adoption semantics.
  - Existing REVIEW/SEQUENCE/MOTION behavior remains regression-green.
  - Human visual sign-off confirms the cockpit is materially easier to parse than the pre-UX1 baseline before the roadmap is marked complete.
- Validation:
  - Expand `operator_workbench_ui_smoke.py` with a bounded full-flow Textual Pilot scenario across QUEUE -> WORKBENCH -> REVIEW -> SEQUENCE -> MOTION and back.
  - Re-run focused background-base-sync, readiness, browser snapshot, FX-adoption, preview, Live Bridge and publish UI regressions selected by changed-file ownership.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
  - Perform explicit human visual review at compact/normal/wide terminal sizes before closeout.
- Task overrides: `none`
- Deferred:
  - Any UX idea requiring new backend authority becomes a separately reviewed post-V1 workstream.
  - Generic Asset Workbench convergence remains owned by the Asset Workbench roadmap.

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

- Next action: after UX4 lands, request the mandated final refresh, audit the actual five-mode interface, then narrow this packet before making it ready.
- Best starting files: the landed UX1-4 UI files, `ui/app.py`, `ui/widgets/context_key_bar.py`, and `operator_workbench_ui_smoke.py`.
- Blockers or open questions: implementation is intentionally blocked until refresh/sign-off and requires final human visual review.