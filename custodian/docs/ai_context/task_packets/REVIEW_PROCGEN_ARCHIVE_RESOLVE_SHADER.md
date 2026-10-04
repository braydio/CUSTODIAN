# REVIEW: PROCGEN ARCHIVE RESOLVE SHADER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-archive-resolve-shader`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-archive-resolve-shader-recovery-1`
- Locks: `procgen-presentation`
- Review: `none`
- Review target workstream: `procgen-archive-resolve-shader-recovery-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1.md`
- Reviewed main: `73a3239fbb81df50a8b7bdc108291961b165896b`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Review modes: `code, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the final recovered AR2 state: the landed shader/render implementation plus renderer-backed recovery evidence, preserving reviewed AR1 scheduling/authority, one shared bounded shader/material path, pause-safe timing, actor readability, and fully ordinary settled world art.
- Reviewed implementation acceptance: Reuse the refreshed AR2 packet acceptance. Objective obligations include unchanged AR1 state/order/lifecycle fingerprints; exactly one shared ShaderMaterial on the existing ArchiveResolveVeil; render-only custom data written deterministically on slot assignment/reuse rather than becoming a second scheduler; existing instance COLOR.a remaining the veil/progress channel; pause-safe presentation_time rather than shader-global TIME for pause-sensitive motion; REQUESTED/READY concealment; disabled/reduced-effects parity; bounded fail-open slot overflow; settled transparency/no tint; no screen-texture/full-screen architecture; and no visible cell/chunk grid. Human aesthetic approval is evidence that the external visual gate occurred, not something this technical reviewer may substitute its own taste for.
- Review evidence: Archived parent AR2 packet and implementation commit `085a38a5`; archived `PROCGEN_ARCHIVE_RESOLVE_SHADER_RECOVERY_1.md` + its closing summary; reviewed AR1 receipt and live owner/render primitive; shader/material/custom-data implementation; focused AR2 smoke; graphical-renderer compile/runtime evidence; Moment Forge evidence; Dropbox manifest/path; and the explicit user/ChatGPT visual decision from the recorded authoring chat.
- Correction threshold: Shader/material behavior that violates AR1 authority, pause/determinism, batching/performance, settled-world neutrality, disabled/reduced-effects parity, or required objective acceptance is correction-worthy. ARR1 follow-ups are also objective acceptance now: a bypassable live-disable path, actor/veil ordering that can hide z2 enemies/allies/items/projectiles beneath Archive Resolve, missing committed production-map live-toggle/undersized-pool proof, or a still-conditional claimed road-decal reload proof is correction-worthy. Subjective preferences already routed through the human visual gate are not automatic correction findings unless they expose a concrete acceptance failure.
- Focused validation: Run AR2's focused shader/material checks first. Then directly verify ARR1 R0-01 through R0-04: (1) exported owner enable writes and the live ProcGenTilemap enable API share one safe transition path with REQUESTED/READY/RESOLVING state present; (2) `ContractMap` effective sibling/draw order leaves z2 gameplay actors/items/projectiles above the veil without disturbing z3/z4 foliage/front-wall occlusion; (3) committed production-map validation covers live disable/re-enable and undersized-slot overflow, not only owner fixtures; (4) the road-decal unload/reload test guarantees a real piece and asserts removal + queued/immediate restoration unconditionally. Then run the reviewed AR1 smoke and affected streaming/runtime-health regressions, requiring S1 `1773840677` unless an independently approved baseline changed. Inspect live instance/material counts and pause behavior rather than accepting screenshots as proof. Confirm the completion summary records the compact Dropbox review manifest/user decision if subjective visual acceptance was required. Use packet/review-pairing/docs checks and `git diff --check`.
- Review focus: Ensure the shader consumes AR1 state rather than creating presentation scheduling; any MultiMesh custom data is render-only, deterministic, and written on assignment/reuse instead of full-frontier scans; COLOR.a remains the existing progress/veil-opacity signal unless the refreshed packet explicitly documents an equivalent render-only encoding; one shared material serves the frontier; no shader-global uncontrolled TIME drives pause-sensitive phases; world-space variation/dither/registration cannot expose the 32 px grid or chunk rectangles; misregistration stays <=1 px and does not introduce screen-texture/full-screen sampling; settled instances disappear/fully transparentize; reduced-effects only changes presentation intensity; no permanent full-world tint/post-process appears. Treat the scene-order correction as part of the shader presentation boundary: Archive Resolve may cover terrain/walls but must not hide gameplay actors merely because they share z2.
- Acceptance: Produce a findings-first independent review. Do not pass if real-renderer compile/runtime evidence or the explicit human visual decision is missing. Blocking defects or material evidence gaps create `procgen-archive-resolve-shader-review-corrections-1` plus paired re-review. A clean/non-blocking-only result makes AR3 eligible for its mandatory ChatGPT/user refresh in the recorded authoring chat. Do not edit reviewed AR2 runtime code in this review.
- Non-goals: Do not re-tune subjective shader taste, implement AR3 semantic echo/spawn choreography, redesign AR1, or generate new world art.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `procgen-archive-resolve-semantic-echo`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: AR3 must be re-derived against the reviewed AR2 shader/material/custom-data contract and the current semantic-owner surface before spawn/reacquisition/echo choreography is implemented.
- Next action: After this review passes, STOP. Bring the AR2 parent implementation evidence, renderer-recovery summary, Independent Review receipt, and human visual-review decision/Dropbox manifest back to https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7 and refresh AR3 in place before any AR3 claim.
- Blockers or open questions: AR3 must remain blocked/manual until that refresh completes.
