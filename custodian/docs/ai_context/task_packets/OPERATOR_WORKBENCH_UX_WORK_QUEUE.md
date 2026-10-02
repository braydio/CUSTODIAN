# OPERATOR WORKBENCH UX V1 - WORK QUEUE / PLANNING REVAMP

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> This is a planning packet based on `main@330422023f9a92362915af46b9658585e7c1d450`.
> Do not claim or implement it yet. Request a fresh OPUI repository/interface
> review after UX3 has landed. Remove this banner only after the packet is
> reconciled against current main and explicitly signed off for execution.

- Packet schema: `custodian.task_packet.v2`
- Series: `operator-workbench-ux-hierarchy-v1`
- Workstream: `operator-workbench-ux-work-queue`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `operator-workbench-ux-publish-decision`
- Locks: `operator-workbench-ui`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `330422023f9a92362915af46b9658585e7c1d450`
- Roadmap: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
- Goal: Replace Page 1's low-value spreadsheet-style PLAN view with an actionable QUEUE that preserves authored implementation rank/priority/state while making missing direction/layer coverage, partial presentation, and local unpublished work obvious.
- Completion boundary: Rework Page 1 data projection and presentation only. The human-authored `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` remains the only implementation-order authority. The UI may compute coverage and explain an actionable next direction, but it may not silently reorder or mutate authored rank/priority/state.
- Current measured state:
  - `ui/widgets/plan_table.py` renders only `# / PRI / STATE / COVERAGE / PROFILE / ANIMATION`.
  - `WorkbenchService.animation_plan()` loads `design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` and current generated catalog, then delegates to `animation_preview.validate_plan()`.
  - The plan JSON is `custodian.operator_animation_implementation_plan.v1` and explicitly stores id, rank, priority, profile, group, action, directions, required_layers, state and reason.
  - Current authored examples include 8-direction `melee_1h/walk_01`, 2-direction `run_01`, and many planned 8-direction action sets.
  - The active design says authored rank/priority/plan state are human-owned while coverage and health are computed annotations.
  - UX1/UX2 are planned to make local workflow state and browser direction state clearer. This slice should reuse those projections rather than independently walking Workbench folders.
- Evidence:
  - `design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - `custodian/tools/operator/ui/widgets/plan_table.py`
  - `custodian/tools/operator/ui/service.py::animation_plan`
  - `custodian/tools/operator/animation_preview.py::validate_plan`
  - landed UX1/UX2 workflow/browser projections after refresh
- Task-specific authority:
  - The plan JSON owns authored order, priority, state, requested directions, required layers and reason.
  - Accepted browser/runtime/catalog state owns computed coverage.
  - UX1/UX2 own artist-facing local workflow status.
  - This slice owns the QUEUE projection and presentation only.
- Work surface:
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/screens/main.py`
  - `custodian/tools/operator/ui/widgets/plan_table.py` or a focused queue replacement
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/animation_preview.py` only if plan validation needs a narrow projection extension
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
- Change:
  1. Rename the user-facing Page 1 concept from PLAN to QUEUE while preserving the plan JSON's authored authority.
  2. Replace the flat coverage-only table with an actionable item projection. Each queue item should expose:
     - authored rank;
     - priority;
     - plan state;
     - profile/group/action;
     - authored reason;
     - required directions;
     - required layers;
     - per-direction coverage state;
     - total complete/required count;
     - local unpublished/blocked state when present.
  3. Add compact direction coverage using the real plan direction order. For 8-way sets, render all requested directions with a text+symbol state. Suggested vocabulary:
     - `● authored/complete`;
     - `◐ partial`;
     - `◇ mirrored/fallback` only when the runtime/catalog authority actually classifies it that way;
     - `○ missing`.
     Do not infer mirrored/fallback solely from visual similarity or absent canonical art.
  4. Distinguish missing required layer vs missing entire direction. Example:
     `S ◐ missing upper_body` is more useful than only `6 / 8`.
  5. Add queue filters:
     - NEXT;
     - MODIFIED;
     - INCOMPLETE;
     - PARTIAL;
     - ALL.
     Filter changes must not mutate authored order.
  6. NEXT remains rank-respecting. It may select the first currently actionable non-complete item according to authored rank/priority/state and explain why it needs work. Do not invent a hidden AI score or reorder plan items.
  7. MODIFIED surfaces plan items that contain any direction with saved local changes waiting to publish, contract changes, landing pending or publication blockers from UX1/UX2.
  8. INCOMPLETE surfaces missing required directions/layers.
  9. PARTIAL surfaces semantic directions present but composition-incomplete/reference-only according to existing completeness authority.
  10. Show authored `reason` prominently enough to explain why the animation exists in the plan.
  11. Enter/open behavior:
      - selecting a queue item keeps the authored item selected;
      - opening it should navigate to WORKBENCH on a direction that currently needs attention;
      - choose the first attention-needed direction in the item's authored `directions` order, not by an invented ranking;
      - if all requested directions are complete but one is locally modified/unpublished, prefer the first modified direction in authored order;
      - if fully complete/clean, use the first authored direction.
      Record this deterministic rule in tests.
  12. Preserve search/filter semantics as view operations over accepted projections. Do not rescan source on every filter change.
  13. Do not make Page 1 editable plan-authoring UI in this slice. Rank, priority, plan state, directions, layers and reason remain file-authored.
  14. Keep raw catalog/source path detail out of the queue default surface.
- Preserve:
  - `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` schema and authored values.
  - Human rank/priority/state order.
  - Existing coverage/catalog authority.
  - UX1/UX2 browser/workflow status.
  - WORKBENCH/REVIEW/SEQUENCE/MOTION behavior.
- Non-goals:
  - No plan JSON editing.
  - No automatic priority changes.
  - No AI ranking/recommendation scoring.
  - No new runtime fallback semantics.
  - No publication behavior changes.
  - No animation art/runtime changes.
- Acceptance:
  - Page 1 immediately shows why the next authored item needs work, not merely a coverage fraction.
  - 8-direction plan items show all authored directions and distinguish complete/partial/missing using non-color-only text/symbols.
  - Missing required layers are called out by layer.
  - MODIFIED filter surfaces an otherwise complete plan item with unpublished local work.
  - NEXT preserves authored plan order and never invents a ranking.
  - Enter from a queue item deterministically opens WORKBENCH at the first attention-needed authored direction under the documented rule.
  - Authored `reason` is visible.
  - Filters/search do not mutate the plan JSON or rescan source on each keystroke.
  - Existing plan JSON remains byte-identical after all queue interactions.
- Validation:
  - Extend `operator_workbench_ui_smoke.py` with plan fixtures covering:
    - 8/8 complete;
    - missing direction;
    - partial required layer;
    - modified-but-complete;
    - landing/block state;
    - filters;
    - deterministic Enter/open direction;
    - no plan-file mutation.
  - Run any existing plan validation smoke selected by ownership.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Task overrides: `none`
- Deferred:
  - UX5 final consistency/accessibility/responsive closeout.
  - Any future visual plan editor remains separately scoped.

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

## Handoff

- Next action: after UX3 lands, request the mandated refresh and reconcile the landed artist-state/browser projections before making this packet ready.
- Best starting files: `ui/widgets/plan_table.py`, `ui/service.py::animation_plan`, `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json`, and landed UX1/UX2 state projections.
- Blockers or open questions: implementation is intentionally blocked until refresh/sign-off.
