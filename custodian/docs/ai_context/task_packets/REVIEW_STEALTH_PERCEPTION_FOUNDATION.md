# REVIEW: STEALTH PERCEPTION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-stealth-perception-foundation`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `stealth-perception-foundation`
- Locks: `stealth-perception, enemy-runtime, vaultwing-runtime`
- Review: `none`
- Review target workstream: `stealth-perception-foundation`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/STEALTH_PERCEPTION_FOUNDATION.md`
- Reviewed main: `0c80f6a5a1c64168a39b841fa5de362d98728664`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove the shared acoustic seam is typed, deterministic, cross-family, and behavior-neutral rather than a new universal AI layer.
- Reviewed implementation acceptance: Use the archived implementation packet's full acceptance contract. Require one typed event/observation path for Enemy + Vaultwing, behavior-equivalent Enemy outcomes, bonded/allegiance correctness, no parallel Vaultwing hearing math, and no behavior/target policy migration into shared stealth code.
- Review evidence: Archived implementation packet/summary; landed stealth event/observation/profile/service files; Enemy/Vaultwing consumer diffs; focused real-event acoustic contract evidence; Enemy/Vaultwing/relationship/ranged regressions; validation-manifest ownership.
- Correction threshold: Weak Variant/Dictionary event handling on a production path, duplicate consumer acoustic math that defeats the shared seam, sensing that directly assigns hostility/behavior, Enemy search/detection drift, bonded Vaultwing hostility regression, simulation-tick nondeterminism, or material proof gaps create bounded correction work.
- Focused validation: Re-run the narrow real-event Enemy+Vaultwing acoustic contract first, then the directly selected Enemy perception, `vaultwing_runtime`, relationship and ranged/noise regressions, changed-file closeout, and `git diff --check`.
- Review focus: emitted facts vs receiver-derived observation ownership; relationship after sensing; no universal behavior controller; exact preservation of existing Enemy/Vaultwing gameplay outcomes; focused validation ownership.
- Acceptance: Findings-first fresh-context review ends in a passed durable receipt or bounded correction/re-review pair; reviewer does not patch the reviewed implementation.
- Non-goals: No S2-S6 expansion, alarm design, Vaultwing bond/runtime cleanup, NPA-8, balance changes, or presentation work.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `vaultwing-runtime-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `mechanical post-review live-main reconciliation only; Vaultwing hardening scope is already locked`
- Next action: If this review passes (including any bounded correction cycle), continue autonomously into `vaultwing-runtime-hardening`; refresh only exact file/test references from reviewed main.
- Blockers or open questions: `none`
