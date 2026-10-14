# REVIEW OPERATOR UNARMED FAST → DODGE HANDOFF V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-unarmed-fast-dodge-handoff-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `operator-unarmed-fast-dodge-handoff-v1`
- Locks: `operator-runtime`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, animation`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: independent reverse-direction input cancellation and FX timing must not be self-certified
- Review target workstream: `operator-unarmed-fast-dodge-handoff-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_UNARMED_FAST_DODGE_HANDOFF_V1.md`
- Reviewed main: `b654ea569e2f212e97a3dd3b22998eff3bfba358`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `conditional`
- Goal: Independently falsify fast-attack→roll input and VFX regression repair with exact landed evidence.
- Completion boundary: Fresh-context review of canonical code, real actor simulation, visible-clock action and overlay ownership, then exact passed receipt or stable R0 findings. Do not edit reviewed implementation.
- Current measured state: Draft review paired to pending `operator-unarmed-fast-dodge-handoff-v1`; implementation neither claimed nor landed at authoring.
- Evidence: Exact `operator.gd` code, new/changed attack→roll tests and test results, current Fists profile metadata and pinned implementation SHA.
- Task-specific authority: original packet acceptance A–H, current dodge/animation owner authority, `paired_review_runner.py` and immutable receipt validation.
- Work surface: Reviewer evidence/receipt only and related bounded correction packets. No gameplay code edits.
- Change:
  1. Reproduce Fast 01–04 roll presses at early/open/late cadence, including buffered-next-attack competition; confirm deterministic eventual dodge with no dropped input and no early iframe.
  2. Force hidden legacy full-body animation to have a mismatched frame count while modular clock is visible. Ensure buffered roll still resolves.
  3. Force dodge rejection (cooldown, stamina, UI/death/impact) and confirm no lost state, stale hitbox, infinite action or VFX.
  4. Confirm nonlooping authored FX does not replay merely from repeated `_update_animation` calls, does not persist behind dodge; a genuinely new link restarts normally and follows correct sector.
  5. Re-run existing roll→fast buffer, charged rolls, Flow, action arbitrate, fast-chain frames, contact/hitbox, animation owner tests; use original minimal Moment Forge evidence only if it actually demonstrates the transition.
  6. Emit exact `passed` or `findings` review outcome under supported coordinator authority; do not fabricate a pass or archive nonpassing outcome via unsupported lifecycle.
- Preserve: original packet's non-goals and art/roll cadence; immutable reviewed target bytes except canonical review receipt.
- Non-goals: no additional art or melee design redesign, no bypass of review environment/recovery gates.
- Acceptance: exact pinned implementation commit with all A–H falsified/verified, no blocking defects or gaps, target receipt added only under supported current schema, green nonzero and fully covered changed-file validation; findings remain blocking if anything fails.
- Validation: focused attack→roll tests, same companion tests in implementation packet, canonical changed-file suite, receipt-delta, review pairing, packet index, diff check. Reject fake zero-test green and any stale evidence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: none.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Next action: Record truthful disposition and return to the original Longform LF1 / shared review closeout workstream; do not claim unrelated `agent-workflow`.
- Blockers or open questions: implementation not landed; reviewer cannot waive failed input or FX correctness.
