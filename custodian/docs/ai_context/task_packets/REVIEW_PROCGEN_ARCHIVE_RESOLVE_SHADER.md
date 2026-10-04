# REVIEW: PROCGEN ARCHIVE RESOLVE SHADER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-archive-resolve-shader`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-archive-resolve-shader`
- Locks: `procgen-presentation`
- Review: `none`
- Review target workstream: `procgen-archive-resolve-shader`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ARCHIVE_RESOLVE_SHADER.md`
- Reviewed main: `efc93352b6ddabf9e698b73e5e6564755ac6404a`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that AR2 changes only the Archive Resolve rendering language, preserves reviewed AR1 scheduling/authority, uses one shared bounded shader/material path, freezes with the presentation clock, and leaves settled world art completely ordinary.
- Reviewed implementation acceptance: Reuse the archived AR2 packet acceptance after its required ChatGPT/user refresh. Objective obligations include unchanged AR1 phase/order identity, shared-material/batched rendering, no per-cell material/tween growth, pause-safe time, deterministic custom data, disabled/reduced-effects parity, settled transparency/no tint, and no visible chunk/grid presentation. Human aesthetic approval is evidence that the external visual gate occurred, not something this technical reviewer may substitute its own taste for.
- Review evidence: Archived AR2 packet/summary; reviewed AR1 receipt and live owner/render primitive; shader/material setup and custom-data schema; focused AR2 smoke; AR1 regression; aggregate frontier metrics; recorded Dropbox visual-review manifest/path and user decision when AR2 completion required it.
- Correction threshold: Shader/material behavior that violates AR1 authority, pause/determinism, batching/performance, settled-world neutrality, disabled/reduced-effects parity, or required objective acceptance is correction-worthy. Subjective preferences already routed through the human visual gate are not automatic correction findings unless they expose a concrete acceptance failure.
- Focused validation: Run AR2's focused shader/material checks first, then the reviewed AR1 smoke and affected streaming/runtime-health regressions. Inspect live instance/material counts and pause behavior rather than accepting screenshots as proof. Confirm the completion summary records the compact Dropbox review manifest/user decision if subjective visual acceptance was required. Use packet/review-pairing/docs checks and `git diff --check`.
- Review focus: Ensure the shader consumes AR1 state rather than creating presentation scheduling; custom data remains deterministic; one shared material serves the frontier; no shader-global uncontrolled time drives pause-sensitive phases; overlap/dither/registration cannot expose the 32 px grid or chunk rectangles; settled instances disappear/fully transparentize; reduced-effects only changes presentation intensity; no permanent full-world tint/post-process appears.
- Acceptance: Produce a findings-first independent review. Blocking defects or material evidence gaps create `procgen-archive-resolve-shader-review-corrections-1` plus paired re-review. A clean/non-blocking-only result makes AR3 eligible for its mandatory ChatGPT/user refresh in the recorded authoring chat. Do not edit reviewed AR2 runtime code in this review.
- Non-goals: Do not re-tune subjective shader taste, implement AR3 semantic echo/spawn choreography, redesign AR1, or generate new world art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `procgen-archive-resolve-semantic-echo`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: AR3 must be re-derived against the reviewed AR2 shader/material/custom-data contract and the current semantic-owner surface before spawn/reacquisition/echo choreography is implemented.
- Next action: After this review passes, bring the AR2 implementation summary, Independent Review receipt, and human visual-review decision/Dropbox manifest back to the recorded ChatGPT planning chat and refresh AR3 in place.
- Blockers or open questions: AR3 must remain blocked/manual until that refresh completes.
