# REVIEW: RECIPROCAL CONTINUITY CANON DRIFT GUARD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-reciprocal-continuity-canon-drift-guard`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `reciprocal-continuity-canon-drift-guard`
- Locks: `lore-canon-validation`
- Review: `none`
- Review target workstream: `reciprocal-continuity-canon-drift-guard`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/RECIPROCAL_CONTINUITY_CANON_DRIFT_GUARD.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `c49cf7bb8cc25f91240179f6fb340177c59323e6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently verify that the landed canon-drift guard actually fails closed on the superseded Reciprocal Continuity/Ash-Bell failure modes without turning legitimate history, devotional language, or supersession records into false positives.
- Review focus:
  - rule ownership is concentrated in one focused validator rather than duplicated between Python and shell grep;
  - the validator tests semantic invariants from active authority instead of banning every occurrence of words such as `Unarrival`, `Ninth Bell`, or `provenance`;
  - representative negative/mutation controls really fail;
  - historical/pre-design/archive material can retain retired statements when clearly historical;
  - active-authority checks cover Orra's role, the Ninth Answer/Open Interval ordering, West Gate separation, later-devotional Ninth Bell, procedural continuity fields, Hub continuity-anomaly ontology, and retired runtime IDs;
  - changed-file/manifest ownership actually selects the guard for protected canon/validator edits;
  - no lore or runtime behavior was redesigned under cover of validation hardening.
- Acceptance: Findings-first fresh-context review on live `main` records a clean/non-blocking pass or creates the bounded correction/re-review sequence. Reviewer must independently exercise at least one positive control and one mutation/negative control, not accept the implementation summary alone.
- Non-goals: Do not rewrite lore, rename devotional/player-facing content, alter runtime behavior, or broaden into faction/Twin/level design review.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Review Checks

1. Read the archived implementation packet, closing summary, Reciprocal Continuity Doctrine, Ash-Bell Continuity authority, and live validator.
2. Verify current canon still matches the audit closure facts from `1ad40547`.
3. Run the focused validator normally.
4. Independently introduce or use its isolated mutation fixture for at least one retired Ash-Bell-history rule and one retired ontology/runtime-ID rule; prove nonzero failure and useful diagnostics.
5. Verify at least one intentional "Ninth Bell"/Unarrived/provenance historical or devotional use remains accepted.
6. Inspect validation-manifest ownership and changed-file selection evidence.
7. Record findings first with stable IDs and dispositions.
8. If blocking findings exist, queue only the narrow correction + paired re-review required by the live review pipeline.

## Handoff

- Next action: Auto-dispatch after `reciprocal-continuity-canon-drift-guard` lands.
- Blockers or open questions: Dependency only.
