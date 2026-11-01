# REVIEW: Sepulcher V2 Recovery Source Salvage (Exact Replay)

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-sepulcher-v2-recovery-source-salvage-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `agent-sepulcher-v2-recovery-source-salvage-v1`
- Locks: `sepulcher-v2-recovery-source-salvage`
- Review: `none`
- Review target workstream: `agent-sepulcher-v2-recovery-source-salvage-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_SEPULCHER_V2_RECOVERY_SOURCE_SALVAGE_V1.md`
- Reviewed main: `878009b2ba90e801b3d20a4abd675732e51f137a`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently verify that the stranded V2 correction's exact three code blobs were salvaged through a new authenticated claim rather than retroactively accepting an unwitnessed merge or changing original evidence.`
- Reviewed implementation acceptance: `A1-A6 in archived AGENT_SEPULCHER_V2_RECOVERY_SOURCE_SALVAGE_V1.md; only the three required Git blobs and new workstream closeout should be authored.`
- Review evidence: `Immutable originals 332ecf8bd7fdb4a46bc931dc49071911213d3d04, bfc7ad394818eae9b48598085dd56dba3ea6981c, f48fe5f62e6f0b4c99c2437f459311c81c30ff3d; source SHA three-file manifest; original claim status/run evidence and preserved V2 failed validation pair; new claim/first-parent trace and actual fresh host validation; adversarial runner failed report and Godot tests.`
- Correction threshold: `Wrong file blob, any unrelated source file, false old checkout disposition, duplicate live editor, missing new claim provenance, new unwitnessed merge, test that accepts a fake suite PASS, V2 real Operator regression, or any changed original held review evidence blocks independent acceptance.`
- Focused validation: `Compute Git blob identity for all three rescued code files; inspect source diff and trace; run focused runner tests and three cold V2 Godot smokes plus neighboring V1 smoke, validation manifest and workstream preflight; verify old branch and original run unchanged; git diff --check.`
- Review focus: `This is a *new legitimate source land*, not retroactive validation of agent-sepulcher-v2-host-validation-recovery-v1. Retain original missing-witness failure as unresolved history and original V2 review as failed host evidence/no reviewer verdict. New green tests and reviewed code are required, and no artistic acceptance is implied.`
- Acceptance: `Findings-first fresh independent PASS only if exact source/behavior/provenance tests and old-evidence preservation are all supported. Never permit original review PASS, forged or late checkpoint, or bypass to finish old original workstream. Named R0-NN findings and bounded correction if blocked.`
- Non-goals: `No original workstream source/history rewrite, claim termination, old review replay, production Operator cutover, art generation, or blanket witness policy exception.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, its own review packet lifecycle/archive metadata and required closing summary, plus bounded correction/re-review packets; do not edit reviewed implementation or unrelated work.`

## Procedure

1. Claim only when newly landed salvage implementation is archived complete, with fresh context and verified exact source file identities.
2. Replay source-Git and old-run preservation negatives independently. Verify original branch still at pinned head and no unauthorized prior-run mutation.
3. Verify new code/runner tests and cold Godot runtime smoke rather than accepting executor self-report. Ensure fresh source-span witness is real if new main advancement occurred.
4. Publish canonical technical review receipt; keep human Operator/floor art choice and original claim disposition as separate incomplete obligations.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; the review outcome does not invent missing historical lifecycle evidence`
- Next action: `If accepted PASS, issue a separate authorized original-claim disposition assessment and fresh V2 technical review against newly corrected main; then return the four original V2 screenshots for user art assessment.`
- Blockers or open questions: `Any unreconciled change to original branch, old review run or new validation source must fail closed.`
