# REVIEW: VAULTWING RUNTIME HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-vaultwing-runtime-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `vaultwing-runtime-hardening`
- Locks: `vaultwing-runtime`
- Review: `none`
- Review target workstream: `vaultwing-runtime-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VAULTWING_RUNTIME_HARDENING.md`
- Reviewed main: `0c80f6a5a1c64168a39b841fa5de362d98728664`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove Vaultwing bond timing, restore reconciliation and relationship compatibility are fixed-step and semantically correct without duplicating the reviewed stealth/perception seam.
- Reviewed implementation acceptance: Use the archived implementation packet's full acceptance contract. Require fixed-tick-only bond gameplay clocks, live-transition vs restore separation, allegiance-sensitive hostile eligibility, correct group compatibility disposition, no unjustified dead-field removal, and no reintroduced Vaultwing-only hearing.
- Review evidence: Archived implementation packet/summary; landed Vaultwing actor/controller/bond-state diffs; predecessor stealth review receipt; focused bond/runtime/relationship/world-spawn/acoustic evidence; validation ownership.
- Correction threshold: Any gameplay clock still mutated by render process, restore replaying first-bond side effects, hostile eligibility ignoring allegiance, semantic targeting depending on stale group membership, removed state with surviving consumers, duplicate hearing/acoustic evaluation, or material proof gaps creates bounded correction work.
- Focused validation: Re-run `vaultwing_bond` with live-vs-restore controls, `vaultwing_runtime`, `actor_relationship_contract`, applicable `vaultwing_world_spawn`, predecessor acoustic regression, changed-file closeout and `git diff --check`.
- Review focus: deterministic simulation ownership; one-time transition semantics; relationship/targetability truth; compatibility-group disposition; preservation of wild combat/bond tuning; shared-perception boundary remains intact.
- Acceptance: Findings-first fresh-context review ends in a passed durable receipt or bounded correction/re-review pair; reviewer does not patch the reviewed implementation.
- Non-goals: No NPA-8 implementation, companion commands, global save design, mounting, ecology redesign, new art/audio, or broader Vaultwing controller refactor.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: After this review passes (including any correction/re-review), bring the reviewed shared perception seam, reviewed Vaultwing runtime/bond/relationship seam, and current NPA program status back to this conversation. Author NPA-8 only if the earlier NPA predecessor program has reached the cross-family convergence point; do not freeze a generic actor API early.

## Handoff

- Next workstream: `non-player-fauna-bonded-command-convergence`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `the pre-NPA-8 Vaultwing chain is complete; NPA-8 must be authored from reviewed live seams plus the then-current NPA-7/predecessor evidence`
- Next action: Stop autonomous execution here. Open the Authoring chat and paste `non-player-fauna-bonded-command-convergence`; remeasure and author NPA-8 only when the broader NPA sequence permits it.
- Blockers or open questions: `NPA-8 intentionally has no active packet yet; prior NPA slices must establish the final cross-family seam first`
