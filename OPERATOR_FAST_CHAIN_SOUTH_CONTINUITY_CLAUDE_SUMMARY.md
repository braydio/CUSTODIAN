# Operator Fast Chain South Continuity — Checkpoint

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73

The packet was claimed as `operator-fast-chain-south-continuity` in an isolated
worktree. No production art, runtime wiring, generated catalog, or gameplay
timing was changed. The required South Fast 02–04 poses are not present in the
authorized source tree: Fast 01 South exists, and Fast 02–04 have East/West
lower-body, upper-body, and FX strips at the required 6/7/8-frame 96×96 cell
contracts. The semantic inventory contains no South assets for those three
actions, so South still selects its East fallback.

The supported Source Session accepts an authored strip, applies one shared
normalization, and stages reviewed candidates; it does not create pose art.
Workbench and Art Agent V2 edit existing semantic animations, while the
documented native new-animation/pose-synthesis flow remains planned. Creating
distinct South poses from the available East/West material would invent the
missing poses and risk character redesign, which the packet explicitly
forbids. The task packet is therefore marked blocked with the precise required
input: reviewed South Fast 02–04 pose strips through an approved Operator
authoring path, or an explicit approved pose-synthesis workflow. Existing
production fallback behavior remains intact.

Evidence: `operator anim list unarmed --group attack --json` reports only E/W
for Fast 02 (6 frames), Fast 03 (7 frames), and Fast 04 (8 frames), for all
three required layers. `operator_animation_contract_report.py --strict --json`
reported 60/63 expected entries present, zero missing required entries, and
three unrelated missing optional entries. No compact visual review handoff was
published because no candidate art or runtime change exists to review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: required South pose sources are absent and current approved authoring tools do not synthesize new animation poses.
- Root cause / contributing factors: Fast 01 South and Fast 02–04 East/West sources do not encode the distinct new poses required for South.
- Prevention / pipeline improvement: provide approved reviewed source strips or establish an approved pose-synthesis workflow before resuming.
- Tooling / docs drift discovered: none
- Follow-up: manual-follow-up
- What worked: semantic inventory verified E/W coverage and exact frame contracts without modifying the production fallback.

## Next Handoff
- Next workstream: review-operator-fast-chain-south-continuity
- Next packet state: dependency-gated
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73
- Refresh reason: approved South pose source art or an explicitly authorized pose-synthesis workflow is required before implementation can satisfy its acceptance criteria.
- Next action: return to the linked authoring chat with the source gap; resume this workstream after reviewed Fast 02–04 South art is available.
- Blockers or open questions: none beyond the missing source/art decision recorded above.
