# REVIEW: AWAKENING INTERACTION FEEDBACK + CRÈCHE CONSOLE ACTIVATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-interaction-feedback-console-activation`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `awakening-interaction-feedback-console-activation`
- Locks: `awakening-runtime, gameplay-hud-interaction-prompts`
- Review: `none`
- Review target workstream: `awakening-interaction-feedback-console-activation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_INTERACTION_FEEDBACK_CONSOLE_ACTIVATION.md`
- Reviewed main: `218df82e2e5d8241cb349c21c05f0439570948a4`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Independently prove that Awakening interaction prompts remain readable for the full actionable interval, long readouts no longer die after the HUD's two-frame lease, and the already-ingested Crèche console activation FX actually plays once in the live scene.
- Reviewed implementation acceptance: Verify every acceptance item in archived `AWAKENING_INTERACTION_FEEDBACK_CONSOLE_ACTIVATION.md`.
- Review evidence: prompt lifetime traces before/after target loss; readout dwell timing; HUD suppression/modal behavior; console FX scene node/Asset V2 runtime path; 8-frame playback timing; first-vs-repeat interaction; unchanged progression/recovery alcove; generic readout/Sundered Keep compatibility.
- Correction threshold: Prompt flicker/expiry while target stays valid, stale prompt after target loss, readout <4s, proximity overwrite during dwell, global arbitrary timeout replacing explicit ownership, activation texture still orphaned, wrong marker/frames/FPS, replay on second read, duplicate baked console body, or regression in generic readout consumers is blocking.
- Focused validation: dedicated HUD prompt persistence smoke; Awakening progression/console-FX smoke; generic WorldReadout compatibility; Sundered Keep prompt refresh; Asset V2 status/doctor; renderer evidence only if actual on-screen FX visibility is not structurally proven.
- Review focus: The user's report is a direct experiential defect. A passing unit test that merely calls `show_interaction()` is insufficient; hold the Operator in range long enough to prove the prompt stays present and sample the console FX across its full one-second clip.
- Acceptance: findings-first fresh review. Pass only when prompt lifetime, readout dwell, exact existing FX consumption, once-only playback, and compatibility are all independently demonstrated.
- Non-goals: no UI redesign, new art, connector/spine work, or broad interaction architecture rewrite inside review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `awakening-lower-upper-spine-connection`
- Next packet state: `ready after this review passes`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Refresh reason: `none`
- Next action: Archive normally; the reviewed prompt/console feedback fix releases the lower→upper spine slice.
- Blockers or open questions: `none`
