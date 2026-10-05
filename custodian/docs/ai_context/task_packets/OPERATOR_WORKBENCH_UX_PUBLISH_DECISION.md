# OPERATOR WORKBENCH UX V1 - PUBLISH DECISION SURFACE

> **REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> This is a planning packet based on `main@330422023f9a92362915af46b9658585e7c1d450`.
> Do not claim or implement it yet. Request a fresh OPUI repository/interface
> review after UX2 has landed. Remove this banner only after the packet is
> reconciled against current main and explicitly signed off for execution.

- Packet schema: `custodian.task_packet.v2`
- Series: `operator-workbench-ux-hierarchy-v1`
- Workstream: `operator-workbench-ux-publish-decision`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `operator-workbench-ux-workbench-home`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `7cfa2c12f5a99a90bfe087117856d16c92f8772a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Background-sync addendum chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Roadmap: `design/02_features/animation/OPERATOR_WORKBENCH_UX_HIERARCHY_ROADMAP.md`
- Goal: Make Publish a fast, comprehensible decision surface that leads with what will change and whether publication is safe, while moving unchanged rows, exact paths and backend audit detail behind progressive disclosure.
- Completion boundary: Redesign the Publish preview/modal only. Consume the already-landed publication-readiness/recovery authority and UX1 artist-facing status vocabulary. Do not change the source/runtime transaction, landing semantics, mirror implementation, validation requirements, or Git authority.
- Current measured state:
  - `ui/dialogs/publish.py` currently renders a summary followed by full DIRECT and MIRROR tables, checkbox controls, dependency/compatibility pass labels, optional full validation and hidden details.
  - DIRECT/MIRROR rows give UNCHANGED operations the same table presence as CREATE/REPLACE.
  - Mirror rows are shown even before mirror promotion is enabled.
  - `PublishView` currently exposes old/new frame counts, direct/mirror operations, publishing layers, timing, contract-changed bool, dependency audit, compatibility preflight, publish enable/block reason, and LAND PENDING.
  - Current primary wording uses pipeline concepts such as MIRROR PROMOTION, Dependency audit and Compatibility preflight.
  - Current `WorkbenchService.publish_preview()` determines CREATE/REPLACE/UNCHANGED from normalized candidate pixels and existing canonical targets.
  - The landed publish-readiness authority provides structured publication preparation/block/recovery truth. The new `operator-workbench-background-base-sync` prerequisite owns routine launch-time reconciliation of a behind, ahead-zero art checkout when local dirt is provably Workbench-owned and byte-preservable.
  - Raw `behind N` is repository commit distance, not a count of Operator animation changes. If background reconciliation succeeded before Publish, this dialog should see `MAIN READY`; it must not make the artist manually resolve ordinary repository lag or interpret the raw count as pending art work.
  - Publish preparation remains an independent safety recheck before canonical mutation. Unsafe/failed launch reconciliation remains a real structured blocker and is not papered over by UX.
  - Active Workbench design requires mirror publication to be explicit/default-off. The FX-adoption prerequisite owns any CLI/default drift correction.
- Evidence:
  - supplied OPUI Publish screenshot from 2026-10-01
  - `custodian/tools/operator/ui/dialogs/publish.py`
  - `custodian/tools/operator/ui/state.py::PublishView/PublishRow`
  - `custodian/tools/operator/ui/service.py::publish_preview/publish`
  - `custodian/tools/operator/animation_workbench.py::publish`
  - `custodian/tools/operator/operator_art_worktree.py`
  - active Workbench design and prerequisite publish-readiness/background-base-sync/FX-adoption packets
- Task-specific authority:
  - Workbench publication transaction remains unchanged authority.
  - Land/publication readiness comes from the landed publish-readiness authority; routine launch-time base reconciliation comes from `operator-workbench-background-base-sync`. UX3 consumes both structured projections and owns neither Git behavior.
  - UX1 owns artist-facing state vocabulary.
  - FX adoption owns CREATE-capable missing FX semantics and mirror default correctness.
  - This slice owns information hierarchy and decision presentation only.
- Work surface:
  - `custodian/tools/operator/ui/state.py`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/dialogs/publish.py`
  - narrow `ui/app.py` Publish-flow projection if required
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` only for regression
- Change:
  1. Reframe the top of Publish around one plain-language decision summary:
     - semantic animation and direction;
     - count of changed publishing layers/files;
     - frame/timing/canvas contract change if any;
     - main readiness;
     - saved/live warning only when relevant;
     - whether publication is ready, blocked, pending landing or a no-op.
  2. Add a structured change summary to `PublishView` or the refreshed equivalent rather than deriving primary UI meaning from formatted rows in the dialog. At minimum project counts for CREATE, REPLACE and UNCHANGED and explicit booleans/reasons for timing/contract changes.
  3. Determine timing change truth from authoritative source/workspace timing data. Do not infer "no timing change" merely from unchanged frame count.
  4. Hide UNCHANGED direct rows from the primary view by default. Replace them with compact language such as `1 unchanged layer hidden`. Keep the complete table in Details.
  5. If every direct publishing layer is UNCHANGED, timing/contract metadata is unchanged, there is no newly adopted binding, and there is no LAND PENDING commit, present `NOTHING TO PUBLISH` and disable the normal publish action. Confirm after refresh that no legitimate non-pixel publication path requires a commit before making this rule ready.
  6. Replace the pipeline-first DIRECT section with a compact CHANGES section. Example:
     `lower_body  REPLACE`, `upper_body  REPLACE`.
     CREATE/REPLACE must be visually stronger than unchanged information.
  7. Reframe MIRROR PROMOTION in artist language:
     `Also update WEST using a mirrored copy`.
     Keep the existing explicit opt-in checkbox/default-off contract.
  8. When mirror is disabled, do not show the full mirror operation table. Show at most the counterpart availability and a one-line consequence. When enabled, show only mirror CREATE/REPLACE rows by default plus a concise count of unchanged rows.
  9. Keep the technical fact `frame-wise mirror; temporal order preserved` in Details or secondary explanatory text, not as primary decision content.
  10. Collapse successful dependency audit + compatibility preflight into one positive readiness statement such as `READY TO PUBLISH`. If either fails, promote the exact blocking category and concise actionable reason into the primary surface.
  11. Consume the prerequisite readiness authority for main synchronization:
      - ready -> `MAIN READY`;
      - safely behind -> `MAIN UPDATE AVAILABLE · WILL PREPARE BEFORE PUBLISH` or refreshed equivalent;
      - dirty/diverged/recovery -> primary blocker with one concise reason.
      Full branch/ahead-behind/path classification belongs in Details.
  12. Improve Aseprite wording. Merely having Aseprite open should not look like a warning if the selected saved document is clean. Warn prominently when the matching document has unsaved changes and publication will use last saved state.
  13. Keep LAND PENDING as a distinct simplified screen:
      - semantic identity;
      - commit waiting to land;
      - main readiness/blocker;
      - one `RETRY LANDING` action;
      - no redundant source/pixel rows.
  14. Keep a Details toggle containing exact old/target paths, retired contracts, full operation tables, timing durations, dependency/compatibility internals, readiness diagnostics and other forensic data.
  15. Do not add extra publication steps. The normal successful path remains one reviewed `PUBLISH TO MAIN` action.
- Preserve:
  - Transactional export/source/runtime/catalog/resource publication.
  - Exact publication allowlist.
  - Source-conflict refusal.
  - Validation and rollback.
  - LAND PENDING and retry semantics.
  - Explicit mirror opt-in.
  - CREATE/REPLACE behavior from FX adoption.
  - One-button normal publish/land flow.
- Non-goals:
  - No change to Git synchronization implementation.
  - No change to mirror pixels or counterpart generation.
  - No weakening of dependency/compatibility checks.
  - No new source-binding semantics.
  - No Page 1/2 layout work.
  - No animation art/runtime changes.
- Acceptance:
  - A common two-layer REPLACE case is understandable at first glance without reading target paths or audit internals.
  - UNCHANGED rows are absent from the primary change list and counted compactly.
  - An all-unchanged/no-contract/no-timing/no-pending case clearly reads NOTHING TO PUBLISH and cannot create a meaningless publication transaction, subject to refreshed backend verification.
  - Contract/timing changes are called out explicitly.
  - Mirror-disabled state does not dump a full counterpart table; enabling mirror immediately shows the real counterpart CREATE/REPLACE consequence.
  - Successful audits reduce to one positive readiness state; failures expose the blocker rather than requiring Details.
  - Safe main update vs blocked main vs LAND PENDING are visibly distinct.
  - Matching unsaved Aseprite content warns that the last saved document will be used; merely open-and-clean Aseprite is not a warning.
  - Full technical detail remains available through Details.
  - Publish/landing behavior and exact generated changes are byte-for-byte governed by the existing backend.
- Validation:
  - Extend `operator_workbench_ui_smoke.py` for:
    - mixed REPLACE/UNCHANGED;
    - CREATE/REPLACE;
    - all-unchanged no-op;
    - frame/timing contract change;
    - mirror disabled/enabled;
    - safe-main-update;
    - main-blocked;
    - clean/open Aseprite;
    - unsaved matching Aseprite;
    - LAND PENDING.
  - Run `operator_workbench_mirror_publish_smoke.py` unchanged as a backend regression.
  - Run prerequisite publication-readiness focused smoke(s) selected by validation ownership.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Task overrides: `none`
- Deferred:
  - UX4 work queue.
  - UX5 final consistency/accessibility/responsive closeout.

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

- Next action: after UX2 lands, request the mandated refresh and verify the landed PublishView/readiness/FX-adoption surfaces before making this packet ready.
- Best starting files: `ui/dialogs/publish.py`, `ui/state.py::PublishView`, `ui/service.py::publish_preview`, and the landed publish-readiness projection.
- Blockers or open questions: implementation is intentionally blocked until refresh/sign-off; no-op publication must be revalidated against landed backend semantics.