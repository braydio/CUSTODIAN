# AWAKENING 04→05 CONNECTOR TRANSITION REGRESSION GUARD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-connector-transition-regression`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `awakening-reliquary-dust-lung-connector`
- Locks: `awakening-04-05-connector-presentation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `f733635`
- Goal: Make the repaired Dust Lung ↔ Locker Reliquary handoff durable by adding one repeatable bidirectional runtime/presentation regression path that can expose seam pops without requiring the user to manually rediscover the connector camera positions.
- Completion boundary: After the existing connector visual-closeout workstream is complete/archived, add or reuse the narrowest stable runtime/Moment Forge coverage for traversal from Dust Lung through connector C→B→A into Locker Reliquary and back A→B→C, with synchronized alpha/evidence capture around both room handoffs. Do not reopen art direction or connector geometry unless the new regression proves a concrete technical defect.
- Current measured state: The active legacy packet `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT.md` correctly targets the current room-canvas seam and requires C/B/A/overview stills after a fade-first fix. It does not define a durable named bidirectional traversal scenario, and its acceptance can therefore prove static joins while still missing a direction-dependent alpha pop during forward/backtracking. The current repository already provides Moment Forge and focused Awakening smoke infrastructure, so this regression surface can be bounded without creating a new presentation system.
- Evidence: User runtime captures on 2026-09-29 show the remaining failure specifically at room/connector boundaries; the closeout packet requires direct C/B/A/overview evidence; `custodian/game/world/awakening/awakening_first_return.gd` owns zone/connector alpha; `custodian/tools/validation/awakening_first_return_smoke.gd` owns static scene/fade assertions; `custodian/tools/iteration/run_moment.py` and `custodian/tools/iteration/scenarios/` are the live repeatable experiential-regression path.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; archived/completed `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT.md` when this dependency clears; `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; live Awakening controller and focused smoke.
- Work surface: Awakening connector presentation regression coverage only: the existing Awakening smoke and/or one narrowly scoped Moment Forge traversal scenario plus its capture/telemetry fixture. Touch runtime presentation code only if the new regression proves a concrete residual bug after the dependency lands.
- Change: Add one stable bidirectional connector traversal regression path. It must exercise both room handoffs in both travel directions, sample/record the relevant Zone04, Zone05, and connector presentation alpha state near the transitions, and produce deterministic evidence frames at useful authored ticks. Prefer extending existing Moment Forge/Awakening validation seams over creating one-off capture scripts. If no suitable scenario framework seam exists, add the smallest connector-specific capture fixture and index it in the existing validation/review tooling. Keep subjective baseline approval human-owned; automate the reproducible evidence and objective alpha/state assertions.
- Preserve: Approved 1024×576 connector source/runtime identity; Layout A/B/C rectangles; room positions; traversal/collision/progression/P-9/camera/lighting behavior; the closeout workstream's final accepted fade/compositor behavior; existing Moment Forge scenario semantics and resource budget.
- Non-goals: No new generated connector art; no room movement; no connector topology changes; no new foreground extraction; no global camera/HUD work; no automatic subjective art-direction verdict; no broad Awakening walkthrough automation.
- Acceptance: One named repeatable command/scenario exercises Dust Lung→C→B→A→Locker Reliquary and the exact reverse path. Evidence includes authored-tick frames at both room joins in both directions plus alpha/state telemetry sufficient to diagnose a pop without manual camera hunting. Objective assertions fail if the connector disappears inside the dogleg, if Zone04/Zone05 is re-forced opaque solely by connector occupancy, or if forward/backtracking leaves presentation alpha in a different steady state at equivalent positions. Existing Awakening smoke/geometry/progression checks remain green. The scenario/capture is discoverable from the appropriate validation/Moment Forge index. No baseline is automatically approved; any genuinely subjective residual seam/art-direction judgment is reported as human review evidence rather than silently accepted.
- Validation: Run the new scenario/fixture first in the cheapest deterministic/no-capture mode, then one evidence capture for final proof. Run the focused Awakening scene/geometry/progression checks affected by the instrumentation. Run `python3 custodian/tools/iteration/run_moment.py --changed` only as selection/advice and execute only the connector scenario actually needed. Finish with one changed-file validation sweep per current validation-economy guidance.
- Task overrides: `none`
- Deferred: Broader Awakening end-to-end visual walkthrough automation and authored connector foreground occlusion remain separate work.

## Handoff

- Completed: Added a named fixed-step bidirectional Moment Forge traversal through the actual C→B→A dogleg and back A→B→C, with room/connector alpha probes at each midpoint, threshold, and connector checkpoint.
- Durable evidence: `reports/awakening_connector_04_05/bidirectional_v1/` contains the four 1280×720 handoff midpoint frames (both joins in both directions) and the synchronized probe/assertion receipt. Two additional B-checkpoint frames were captured in the Moment Forge run but are not retained because state telemetry already proves dogleg occupancy.
- No presentation/runtime behavior or connector geometry changes were needed; the accepted fade/compositor behavior remains intact.
- Closeout blocker: the required changed-file sweep exited 4 because the unrelated `review_pairing_contract` unit check found missing validation-script paths in two other ready packets (`ASSET_HANDOFF_BUNDLE_INSTALLER_V1.md`, `PROCGEN_PAUSE_AWARE_STREAMING.md`). That lower-tier failure skipped the newly registered Moment-tier scenario during this sweep, although the scenario had already passed its direct no-capture/evidence runs and all three Awakening smoke checks passed. Repository-wide context validation separately reports three existing packet-index inconsistencies. The branch is checkpointed with implementation and evidence committed; do not archive/finish until the packet-index validation blocker is resolved or explicitly dispositioned.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `custodian/tools/iteration/scenarios/traversal/awakening_connector_bidirectional_v1.json` and its fixture execute the actual C→B→A dogleg and exact reverse at fixed eight-pixel steps. The no-capture run passed all 109 assertions, including synchronized Zone04/Zone05/connector alpha, both fade midpoints and thresholds, restoration, and forward/reverse equality; the evidence run captured six authored frames, with the four required transition midpoint frames retained under `reports/awakening_connector_04_05/bidirectional_v1/`. `awakening_first_return`, `awakening_first_return_geometry`, and `awakening_first_return_progression` validations passed. The existing visual-closeout packet is archived and its accepted art/compositor remains untouched.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: The initial fixture named an intentionally unbound connector foreground and the fresh worktree lacked Godot import state; both were corrected. The required changed-file sweep then exited 4 because `review_pairing_contract` rejects missing validation-script paths in two unrelated ready packets, so the lower-tier failure skipped Moment tests in that sweep. The direct new scenario and all three Awakening smokes passed.
- Root cause / contributing factors: The flattened connector has no foreground node; isolated worktrees lack generated Godot import state; other ready packets reference missing validation scripts.
- Prevention / pipeline improvement: Fixed in-scope fixture and scenario registration; unrelated packet script references need a separate owner before the full changed-file sweep can be green.
- Tooling / docs drift discovered: Added the scenario's manifest, validation recipe, and FILE_INDEX entries. `check_ai_context.py` also reports existing inconsistencies for `ASH_BELL_FORLORN_RITUAL.md`, `BLACK_RELIQUARY_LIVE_MINIMAP.md`, and archived `OPERATOR_FAST_CHAIN_INBOX_RECONCILIATION.md`; the managed Ready/Auto Dispatch block is not initialized.
- Follow-up: manual-follow-up
- What worked: Fixed-step L-dogleg traversal plus matched alpha probes made the handoff state repeatable without camera hunting.
