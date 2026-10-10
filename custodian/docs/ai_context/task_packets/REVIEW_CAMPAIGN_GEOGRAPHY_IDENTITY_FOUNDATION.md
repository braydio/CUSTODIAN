# REVIEW · F15-B1 Campaign Geography Identity Foundation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-campaign-geography-identity-foundation`
- Kind: `review`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `campaign-geography-identity-foundation`
- Locks: `campaign-geography`
- Review: `none`
- Review target workstream: `campaign-geography-identity-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CAMPAIGN_GEOGRAPHY_IDENTITY_FOUNDATION.md`
- Reviewed main: `fb2f634b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently determine whether F15-B1 establishes a deterministic, collision-safe, data-only Domain/Location/Edge identity contract and repeatable CampaignVisit reference without taking authority from F02, F06, F14, or REMAP-3.
- Reviewed implementation acceptance: All seven acceptance conditions in the archived implementation packet, with special attention to injective keys for valid dotted identifiers; reciprocal typed adjacency; stable seeds and generation provenance across repeat construction/visits; fail-closed duplicate, missing, incompatible-version and invalid-ingress cases; route node separation; absence of gameplay nodes, terrain changes and disk persistence.
- Review evidence: Reconstruct the contract from current `origin/main`, the implementation diff, focused committed tests/fixtures, changed-file validation receipt and durable implementation summary. Compare its claims with the approved D1–D7 decision record and existing campaign/session, identity, F14 actor, F02 terrain/route and REMAP-3 ownership.
- Correction threshold: Any identity collision or ambiguous key encoding for valid inputs; nondeterministic drift across visits; asymmetric or dangling adjacency accepted as valid; route/scene/chunk ID treated as a geographic LocationId; incompatible generation or invalid provenance accepted; accidental runtime node, terrain-output, actor, or disk-save authority; or a test/evidence claim unsupported by committed output is a blocking finding. Numeric scale, final visual presentation and exact streaming implementation are explicitly deferred and must not be invented as review requirements.
- Focused validation: Run the smallest focused tests for the new registry/contract, including all negative controls and repeated-visit fixtures. Inspect the exact key codec and all public construction/validation paths. Run changed-file validation, packet-index consistency, paired-review validation and `git diff --check` when available; do not run a broad Godot sweep or require travel/streaming evidence for this data-only foundation.
- Review focus: (1) Address uniqueness and dotted-valid identity behavior. (2) Edge ownership, reciprocity, directionality semantics and duplicate detection. (3) Deterministic seed/version/provenance semantics and second CampaignVisit behavior. (4) Strong distinction among Domain/Location/RouteNode/scene/chunk identifiers. (5) Fail-closed API behavior and useful machine-inspectable reasons. (6) No duplicate visit, actor, geography or persistence authority. (7) Ensure B1 does not absorb B2 semantic metadata, C2 actor handoff, or F15-C playable travel.
- Acceptance: Record a findings-first independent verdict on the landed implementation using a newly started reviewer context. List exact evidence and test commands, state which claims were independently reproduced, and assign stable `R0-NN` findings. If a correctness defect is confirmed, create only the smallest bounded correction packet and fresh re-review within the two-cycle limit. Passing this review accepts B1 only; it does not authorize B2, C2, F15-C, world-scale selection, final visual presentation or exact production streaming implementation.
- Non-goals: Do not edit implementation/runtime/design files under review, choose numerical geography scale, decide final visuals/streaming, add scene/terrain/spawner/actor behavior, or make unrelated packet-index/NPA repairs part of F15-B1 findings. Do not claim, start or launch this review until the implementation has landed and archived complete.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only its durable review receipt, this review packet's lifecycle/archive metadata, the required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: Review acceptance alone does not authorize implementation of later world generation, actor residency, streaming, or traversal work; obtain the relevant future design decision after B1 evidence.
- Next action: Return accepted B1 results and specific gaps to the authoring conversation for the next separately scoped decision.
- Blockers or open questions: none within the review boundary.
