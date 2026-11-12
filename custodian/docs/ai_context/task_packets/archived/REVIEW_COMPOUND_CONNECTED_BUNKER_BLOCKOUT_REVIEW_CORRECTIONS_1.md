# REVIEW: CONNECTED BUNKER VERTICAL TRANSFER AND ISOLATION EVIDENCE R0-01 R0-02

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-compound-connected-bunker-blockout-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `compound-connected-bunker-blockout-review-corrections-1`
- Locks: `compound-layout`
- Review: `none`
- Review target workstream: `compound-connected-bunker-blockout-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/COMPOUND_CONNECTED_BUNKER_BLOCKOUT_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `885961a9cc2f11b5ba7c5f261b22df2476e818b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Summary backlink: Repeat exact Authoring chat URL in durable review summary and Next Handoff.
- Goal: Independently establish that R0-01 and R0-02 are fixed: each paired vertical entry is usable in the running game and layer isolation is proven on real collision, navigation and camera behavior.
- Reviewed implementation acceptance: A-F of the archived correction packet `COMPOUND_CONNECTED_BUNKER_BLOCKOUT_REVIEW_CORRECTIONS_1.md`.
- Review evidence: Reproduce the original R0-01 gap against the pre-fix commit, run the extended smoke on the fixed code, read the controller and tilemap diffs, and attempt to break the transfer (bounce, wrong pairing, room-to-room trigger, camera restore).
- Correction threshold: A housing that does not reach the network, a transfer between underground rooms, a second copy of layer state, camera bounds that intersect the other layer or are not restored, a smoke that still disables collision or navigation, or any `legacy`/`walled_yard` regression requires an explicit R1-NN finding.
- Focused validation: Freshly run the connected-bunker, profile, layout, runtime and minimap smokes; independently exercise both entries in both directions.
- Review focus: Active layer derived from position rather than stored; anchor pairing; bounce lockout; camera restore; honest collision and navigation evidence.
- Acceptance: Findings-first fresh-context disposition of R0-01 and R0-02 as fixed, unresolved or regressed with explicit evidence; no edits to the reviewed implementation during this review.
- Non-goals: No feature work, no visual or feel judgement, no edit to the archived parent review or its recovered `findings` outcome.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Codex takeover validation gate (2026-10-17)

- Recovery/evidence: `custodian/docs/ai_context/workstream_handoffs/COMPOUND_BUNKER_R1_CODEX_TAKEOVER_20261017.md`. The original Claude code was locally committed in an active claimed worktree but NOT landed when export ended. Its 77/77 run followed an unresolved design-spec merge conflict; it is not valid final acceptance evidence.
- Before THIS review, verify the original correction packet is archived complete on current main, its local merge finished with fresh post-merge validation, and a real review runner can claim this exact workstream. Run `paired_review_runner.py` as a FRESH reviewer; do not first `dispatch claim` the same review.
- Falsify R0-01 and R0-02 on actual code: two surface↔subsurface anchors, no bounce/room-to-room transfer, one layer authority, camera clamp/restoration, collision enabled and canonical `NavigationSystem` AStar2D (not the empty `NavigationRegion2D`). Preserve historical findings and fail closed on missing proof.

## Procedure

Use `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md` from a fresh reviewer context. Verify the pinned correction from its archived packet, then try to break the transfer before accepting it. A passing smoke alone is not sufficient: compare the evidence with the original R0-01 and R0-02 wording.

## Handoff

- Next workstream: `compound-interior-traversal-integration`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: On an accepted review, follow the named next workstream if eligible; otherwise stop with the exact successor.
- Blockers or open questions: `none`
