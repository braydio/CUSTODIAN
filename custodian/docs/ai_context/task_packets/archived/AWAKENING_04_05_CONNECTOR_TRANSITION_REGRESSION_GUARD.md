# AWAKENING 04→05 CONNECTOR TRANSITION REGRESSION GUARD

> **Archived as superseded.** The final source-preserving 1502×2048 registered composition and its fade ownership are covered by the completed correction/review packets and `awakening_registered_composition_traversal_smoke.gd`. This older packet's 1024×576 identity is retired; do not dispatch it.

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-connector-transition-regression`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-awakening-04-05-registered-composition-fade-repair-v1`
- Locks: `awakening-04-05-connector-presentation`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: this downstream packet owns only a regression harness, not production behavior, and may close as superseded when its dependency already proves the full contract`
- Reviewed main: `52135e3401a9efd49b011e676171373c3bef37b2`
- Goal: Historical regression-only follow-up. It is blocked because the newly confirmed production fade defect is now owned by `awakening-04-05-registered-composition-fade-repair-v1`, which also absorbs the required bidirectional evidence.
- Completion boundary: After the existing connector visual-closeout workstream is complete/archived, add or reuse the narrowest stable runtime/Moment Forge coverage for traversal from Dust Lung through the single 04→05 dogleg connector into Locker Reliquary and back through that same connector, with synchronized alpha/evidence capture around both room handoffs. Do not reopen art direction or connector geometry unless the new regression proves a concrete technical defect.
- Current measured state: **This packet is now downstream of reviewed `awakening-04-05-registered-composition-correction-v1`, which supersedes the previously reviewed rotated connector placement with the user's exact shared 1502×2048 composition and is expected to add the same durable bidirectional traversal proof. Do not execute this packet's old fade-specific assertions unchanged. After the dependency lands, first check whether its committed scenario/telemetry fully satisfies this packet; if so, close this packet as superseded rather than duplicating the harness. If a residual regression gap remains, refresh only that gap.** The active legacy packet `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT.md` correctly targets the current room-canvas seam but still carries obsolete three-segment review labels from the retired multi-piece connector implementation. It does not define a durable named bidirectional traversal scenario, and its acceptance can therefore prove static joins while still missing a direction-dependent alpha pop during forward/backtracking. The current repository already provides Moment Forge and focused Awakening smoke infrastructure, so this regression surface can be bounded without creating a new presentation system.
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

## Closure Decision — 2026-10-06

- Decision: **Option 1 — close this workstream as superseded after `review-awakening-04-05-registered-composition-correction-v1` archives complete, provided that review confirms the upstream packet's required bidirectional durability evidence.**
- Do **not** merge or rebase `agent/awakening-04-05-connector-transition-regression` onto current main. Its checkpoint `456f8a89e` is donor evidence only.
- Preserve the donor branch until the replacement implementation/review evidence is durable. The branch is the only copy of the old scenario and must not be deleted before that comparison.
- The old scenario's reusable ideas are limited to its deterministic fixed-step traversal fixture, checkpoint/evidence structure, forward/reverse symmetry checks, and Moment Forge registration pattern. Its concrete C→B→A waypoint names, legacy three-piece connector assumptions, and fade assertions are **not** salvageable.
- In particular, the donor scenario asserts transient Zone04/Zone05/connector alpha values around `0.0` and `0.5`; the replacement `awakening-room-connectors-polish` contract requires the visible room and single connector presentation to remain fully opaque at the joins. Those old assertions encode superseded behavior and must never be landed unchanged.
- If the upstream review passes its bidirectional single-connector/opaque-overlap acceptance, archive this packet as superseded/no additional implementation and then retire the donor branch through the repository's normal archive/branch-ledger workflow.
- If that review exposes a real residual regression-coverage gap, keep this same workstream identity but refresh from current main and implement **only that residual gap**. Mine the donor for fixture technique if useful; do not rebase or transplant the stale scenario wholesale.


## Handoff

- Next action: The dispatcher auto-claims only after `review-awakening-room-connectors-polish` is complete and archived; then either close as superseded or implement only the residual regression gap.
- Best starting files: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/tools/validation/awakening_first_return_smoke.gd`; `custodian/tools/iteration/run_moment.py`; `custodian/tools/iteration/scenarios/`.
- Blockers or open questions: Blocked by `review-awakening-04-05-registered-composition-fade-repair-v1`. Do not claim this stale regression packet. After that review, archive as superseded unless a concrete residual regression-only gap remains.


## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a`
- Refresh instruction: After `review-awakening-room-connectors-polish` is complete, inspect its landed bidirectional scenario, telemetry, and changed validation ownership. If they already prove both joins in both directions under the new opaque-overlap contract, disposition this packet as superseded/no additional implementation. Otherwise narrow execution to only the remaining regression gap inside the claimed workstream; no manual status flip or ChatGPT refresh is required.