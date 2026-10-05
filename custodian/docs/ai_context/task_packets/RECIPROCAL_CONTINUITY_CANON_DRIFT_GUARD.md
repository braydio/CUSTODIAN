# RECIPROCAL CONTINUITY CANON DRIFT GUARD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `reciprocal-continuity-canon-drift-guard`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `lore-canon-validation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-reciprocal-continuity-canon-drift-guard`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `validation infrastructure can silently become vacuous or overbroad; an independent pass should verify both drift detection and intentional historical-reference allowances`
- Reviewed main: `c49cf7bb8cc25f91240179f6fb340177c59323e6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Turn the already-landed Reciprocal Continuity / Ash-Bell canon correction into a fail-closed, focused regression contract so active docs/runtime cannot silently return to provenance-as-metaphysics, the superseded Ash-Bell history, or retired runtime knowledge IDs.
- Completion boundary: Done when one focused validation authority fails on the known retired ontology/history/runtime-ID regressions, allows intentional historical/negative references, is registered in changed-file validation ownership, and the existing lore-report helper no longer gives a false impression that report-only grep is an acceptance gate.
- Current measured state: Initial migration `110b837286be873ea93ea6a61d3397f8723e69d8` landed the Reciprocal Continuity model but its acceptance review requested convergence corrections. Correction `1ad4054763ee27a566b4c381f9485c11e5b0c3b5` now survives on live main: Orra is Station IX's officer, her late Ninth Answer ends the Open Interval, West Gate closure is separate, "Ninth Bell" is later devotional language, procedural lore uses continuity-anomaly/origin/source-integrity/provenance-status fields, Hub ontology uses continuity anomalies, and retired runtime IDs are not production keys. However `tools/lore/validate_reciprocal_continuity_migration.sh` currently reports grep matches with `|| true` and does not fail on regressions; no dedicated Reciprocal Continuity canon-doc smoke is registered in the validation manifest.
- Evidence: `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`; `design/03_world/THE_ASH-BELL_CONTINUITY.md`; `design/03_world/lore/CORE_LORE.md`; `design/03_world/PROCEDURAL_LORE_GENERATION.md`; `design/04_architecture/HUB_SYSTEM_META_PROGRESSION.md`; `custodian/docs/ai_context/{CURRENT_STATE,CONTEXT}.md`; `tools/lore/validate_reciprocal_continuity_migration.sh`; original migration commit `110b8372`; convergence correction `1ad40547`; `RECIPROCAL_CONTINUITY_CANON_AUDIT_CLAUDE_SUMMARY.md`.
- Task-specific authority: `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md` is the cosmology/continuity authority; `design/03_world/THE_ASH-BELL_CONTINUITY.md` owns Ash-Bell operational history; `design/03_world/lore/CORE_LORE.md` owns current lore summary; live validation-manifest conventions own test selection.
- Work surface: A new focused Python canon-doc validation smoke under `custodian/tools/validation/`; `custodian/tools/validation/validation_manifest.json`; `tools/lore/validate_reciprocal_continuity_migration.sh`; only directly stale AI-context/validation documentation exposed by implementation.
- Change: Make the focused smoke the fail-closed rule owner. Check explicit active-authority invariants rather than globally banning words that remain legitimate in history, devotional dialogue, supersession notes, or negative statements. Keep the shell migration script as a human forensic/report helper or make it delegate to the focused smoke before printing broader search context; do not maintain two competing rule sets.
- Change: At minimum protect these invariants: (1) Reciprocal Continuity Doctrine remains the highest cosmology/continuity authority; (2) Orra is Station IX's officer rather than coordinator of all nine stations; (3) Orra's late Ninth Answer terminates the Open Interval and West Gate closure does not; (4) "Ninth Bell" remains later survivor/devotional language rather than an original literal ninth bell/synchronization signal; (5) active procedural lore uses `continuity_anomaly`, `continuity_origin`, `source_integrity`, and `provenance_status` rather than an active `provenance_failure` ontology; (6) Hub/knowledge docs do not restore "unarrived source/event" or impossible-provenance metaphysics; (7) production runtime/content does not restore `ash_bell_ninth_bell` or `ash_bell_bellfall_containment`; (8) active AI context does not reassert Unarrival/provenance as the universal metaphysical root cause.
- Change: Include mutation/negative-control coverage that proves the smoke fails when representative retired wording/IDs are injected into an isolated fixture or validator input, while accepted historical/supersession wording remains allowed. A green scan of current files alone is insufficient.
- Preserve: Current Reciprocal Continuity doctrine; corrected Ash-Bell operational history; player-facing devotional "Ninth Bell", Unarrived Saint, and other intentional in-world terminology; historical archives/hardening logs as historical evidence; current faction canon; runtime behavior.
- Non-goals: No new lore. No rewrite of Reciprocal Continuity, Ash-Bell, Saint Orra, the Severing, Pale, Non-Recipient, factions, Twin Solaria, or Hub mechanics. No runtime behavior or save migration. Do not sanitize archived/pre-design history merely because it contains retired terms.
- Acceptance: Focused validation exits nonzero for each representative prohibited regression above; positive controls pass for the current doctrine/history and intentional devotional/historical uses; old production knowledge IDs are rejected without rejecting explanatory migration history; validation ownership selects the smoke when its protected authorities or validator change; the report helper clearly distinguishes diagnostic search output from pass/fail validation; current active canon passes unchanged.
- Validation: Run the new focused Reciprocal Continuity canon-doc smoke and its negative/self-test coverage first; run the existing faction canon-doc smoke if shared canon/index surfaces change; run changed-file validation with complete ownership coverage; parse `validation_manifest.json`; run `git diff --check`. Before closeout, update this packet with the exact created smoke path and final commands/results.
- Task overrides: `none`
- Deferred: Broader prose-style linting and unrelated faction/level canon checks stay with their existing validators.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Re-read live main and the two canon authorities at claim time. Mechanical path/helper drift may be reconciled by the execution agent; any newly discovered material lore judgment must stop and return to this chat rather than being silently decided in validation code.

## Handoff

- Next action: Claim `reciprocal-continuity-canon-drift-guard`, implement the fail-closed guard, validate it, land it, then run the paired fresh-context review.
- Blockers or open questions: None.
