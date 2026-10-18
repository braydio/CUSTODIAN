# REVIEW: Paired Review Source-Span Main-Sync Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-source-span-main-sync-recovery-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-source-span-main-sync-recovery-v1`
- Locks: `paired-review-source-span-provenance`
- Review: `none`
- Review target workstream: `agent-paired-review-source-span-main-sync-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SOURCE_SPAN_MAIN_SYNC_RECOVERY_V1.md`
- Reviewed main: `d26d8d535ddfa63240a29ad655e27bfa9ddb8802`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently falsify main-sync trace binding and source-span integrity without touching either preserved review run.`
- Reviewed implementation acceptance: `Verify implementation acceptance 1–5: canonical archive remains fixed, landing merge must have the exact ordered parents and recorded main_sync, original source is not pulled from merge, archive-only closeout paths are strictly bounded, and all tampering/ambiguity controls fail closed.`
- Review evidence: `Pinned source and tests plus original existing remote diagnostics trace; exact 06cbe952,48a0bfc4,1fa679c3,f12717e6,623dd45d history; immutable protected run evidence and committed validation report.`
- Correction threshold: `Findings or a follow-up correction only for a genuine provenance/security/coverage failure. Do not broaden to generic merge support or alter claims.`
- Focused validation: `Reproduce exact historical source-span resolution and all negative cases using real Git graph fixtures, compare source blobs across archive/merge, validate unchanged direct-archive W1 regression, exercise post-run re-resolution; run focused suites and changed-file coverage.`
- Review focus: `One exact matching trace; archive identity separation; ordered parent/SHA/evidence binding; archive-only closeout allowlist; no source/test modification hidden in merge; no fabricated duplicate provenance; stable immutable original run evidence.`
- Acceptance: `Produce a findings-first fresh-context independent verdict with exact resolved source base/head, canonical implementation SHA and landing merge identity. Passing requires actual historical source-span resolution and all adversarial tests; no simulated passing receipt and no mutation of the two original runs.`
- Non-goals: `Do not change implementation source in reviewer context; do not apply or relaunch W1 or correction-1 review; do not release W2/W5 or alter checkout .gitignore.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `review-agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Next packet state: `preserved host_validation_recovery; exact same-run continuation only after accepted independent review`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Refresh reason: `none`
- Next action: `From a safe clean coordinator checkout, re-plan and explicitly authorize same-run recovery of preserved 20261018T014101Z-f4fd619029aa after this independent review passes. If correction-1 review passes, regenerate the original W1 plan against current main and only then apply its authorized digest; W2/W5 stay blocked until W1 acceptance.`
- Blockers or open questions: `Existing host-validation recovery evidence is immutable; requires verification against the live local worktree and six original W1 hashes before any apply.`
