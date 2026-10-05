# AWAKENING 04→05 CONNECTOR TRANSITION REGRESSION GUARD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-connector-transition-regression`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-awakening-room-connectors-polish`
- Locks: `awakening-04-05-connector-presentation`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: this downstream packet owns only a regression harness, not production behavior, and may close as superseded when its dependency already proves the full contract`
- Reviewed main: `43cb6ae3f6dc6da4924e0f8c031e68e2f2be1e78`
- Goal: Make the repaired Dust Lung ↔ Locker Reliquary handoff durable by adding one repeatable bidirectional runtime/presentation regression path that can expose seam pops without requiring the user to manually rediscover the connector camera positions.
- Completion boundary: After the existing connector visual-closeout workstream is complete/archived, add or reuse the narrowest stable runtime/Moment Forge coverage for traversal from Dust Lung through the single 04→05 dogleg connector into Locker Reliquary and back through that same connector, with synchronized alpha/evidence capture around both room handoffs. Do not reopen art direction or connector geometry unless the new regression proves a concrete technical defect.
- Current measured state: **This packet is now downstream of reviewed `awakening-room-connectors-polish`, which changes the connector art source and alpha contract and is expected to add the same durable bidirectional traversal proof. Do not execute this packet's old fade-specific assertions unchanged. After the dependency lands, first check whether its committed scenario/telemetry fully satisfies this packet; if so, close this packet as superseded rather than duplicating the harness. If a residual regression gap remains, refresh only that gap.** The active legacy packet `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT.md` correctly targets the current room-canvas seam but still carries obsolete three-segment review labels from the retired multi-piece connector implementation. It does not define a durable named bidirectional traversal scenario, and its acceptance can therefore prove static joins while still missing a direction-dependent alpha pop during forward/backtracking. The current repository already provides Moment Forge and focused Awakening smoke infrastructure, so this regression surface can be bounded without creating a new presentation system.
- Evidence: User runtime captures on 2026-09-29 show the remaining failure specifically at room/connector boundaries; the closeout packet requires direct connector/room-junction evidence; `custodian/game/world/awakening/awakening_first_return.gd` owns zone/connector alpha; `custodian/tools/validation/awakening_first_return_smoke.gd` owns static scene/fade assertions; `custodian/tools/iteration/run_moment.py` and `custodian/tools/iteration/scenarios/` are the live repeatable experiential-regression path.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; archived/completed `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT.md` when this dependency clears; `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; live Awakening controller and focused smoke.
- Work surface: Awakening connector presentation regression coverage only: the existing Awakening smoke and/or one narrowly scoped Moment Forge traversal scenario plus its capture/telemetry fixture. Touch runtime presentation code only if the new regression proves a concrete residual bug after the dependency lands.
- Change: Add one stable bidirectional connector traversal regression path. It must exercise both room handoffs in both travel directions, sample/record the relevant Zone04, Zone05, and connector presentation alpha state near the transitions, and produce deterministic evidence frames at useful authored ticks. Prefer extending existing Moment Forge/Awakening validation seams over creating one-off capture scripts. If no suitable scenario framework seam exists, add the smallest connector-specific capture fixture and index it in the existing validation/review tooling. Keep subjective baseline approval human-owned; automate the reproducible evidence and objective alpha/state assertions.
- Preserve: Approved one-piece 1024×576 connector source/runtime identity; exact current 04→05 dogleg walkable footprint; room positions; traversal/collision/progression/P-9/camera/lighting behavior; the closeout workstream's final accepted fade/compositor behavior; existing Moment Forge scenario semantics and resource budget.
- Non-goals: No new generated connector art; no room movement; no connector topology changes; no new foreground extraction; no global camera/HUD work; no automatic subjective art-direction verdict; no broad Awakening walkthrough automation.
- Acceptance: One named repeatable command/scenario exercises Dust Lung→the single 04→05 connector→Locker Reliquary and the exact reverse path. Evidence includes authored-tick frames at both room joins in both directions plus alpha/state telemetry sufficient to diagnose a pop without manual camera hunting. Objective assertions fail if the single connector disappears anywhere inside the dogleg, if Zone04/Zone05 is re-forced opaque solely by connector occupancy, or if forward/backtracking leaves presentation alpha in a different steady state at equivalent positions. Existing Awakening smoke/geometry/progression checks remain green. The scenario/capture is discoverable from the appropriate validation/Moment Forge index. No baseline is automatically approved; any genuinely subjective residual seam/art-direction judgment is reported as human review evidence rather than silently accepted.
- Validation: Run the new scenario/fixture first in the cheapest deterministic/no-capture mode, then one evidence capture for final proof. Run the focused Awakening scene/geometry/progression checks affected by the instrumentation. Run `python3 custodian/tools/iteration/run_moment.py --changed` only as selection/advice and execute only the connector scenario actually needed. Finish with one changed-file validation sweep per current validation-economy guidance.
- Task overrides: `none`
- Deferred: Broader Awakening end-to-end visual walkthrough automation and authored connector foreground occlusion remain separate work.

## Handoff

- Next action: The dispatcher auto-claims only after `review-awakening-room-connectors-polish` is complete and archived; then either close as superseded or implement only the residual regression gap.
- Best starting files: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; `custodian/tools/iteration/run_moment.py`; `custodian/tools/iteration/scenarios/`.
- Blockers or open questions: Dependency only. Do not begin while the visual-closeout workstream still owns connector presentation.


## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Refresh instruction: After `review-awakening-room-connectors-polish` is complete, inspect its landed bidirectional scenario, telemetry, and changed validation ownership. If they already prove both joins in both directions under the new opaque-overlap contract, disposition this packet as superseded/no additional implementation. Otherwise narrow execution to only the remaining regression gap inside the claimed workstream; no manual status flip or ChatGPT refresh is required.