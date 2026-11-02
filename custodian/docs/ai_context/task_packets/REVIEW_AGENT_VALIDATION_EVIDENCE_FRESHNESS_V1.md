# REVIEW: AGENT VALIDATION EVIDENCE FRESHNESS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-validation-evidence-freshness-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-validation-evidence-freshness-v1`
- Locks: `validation-infrastructure`
- Review: `none`
- Review target workstream: `agent-validation-evidence-freshness-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_VALIDATION_EVIDENCE_FRESHNESS_V1.md`
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify Agent Validation Evidence Freshness V1 against the landed code and all numbered implementation acceptance items.
- Reviewed implementation acceptance: 1) Deterministic report fingerprints for same sources/manifest/test ID/flags/runner inputs; 2) changed file, staged diff, manifest, warning patterns, version, asset state, selected tests or unknown env yields recheck_required/unknown; 3) old run reports lacking provenance become unknown; 4) red/skipped/timeout never reusable as proof; 5) comparator emits actionable minimal rerun selection rationale but final runner/finish remains unchanged; 6) independent tests demonstrate same SHA yet changed dirty bytes blocks exact_match; 7) two consecutive identical inputs return same explanations; 8) no resource/import cache mutates through read-only comparison.
- Review evidence: Two repeat-report provenance dumps and stale/dirty/changed-manifest fixtures; PF2/PF4 regression outcomes, final validation JSON.
- Correction threshold: Any stale evidence considered authoritative green or failure/skip omitted is a blocker; unnecessary repeat-running is optional optimization.
- Focused validation: Focused unit and temporary Git repo tests for clean/dirty/staged/different manifest/warnings/source/test selection/runner version and missing provenance; PF2 triage and PF4 preflight regression; run_validation.py selected focused checks before changed-file sweep; check_ai_context.py --json, pairing/index, git diff --check.
- Review focus: Independently prove no acceptance bypass or false exact-match from partial fingerprint; accurate per-test invalidation and immutable reports.
- Acceptance: Produce a findings-first fresh-context review of exact landed SHA with stable R0-NN IDs for material defects/gaps, bounded corrections and repeat review where required. Complete/archive only this review packet and permitted evidence; never edit implementation.
- Non-goals: No redesign, no implementation fixes during review, no bypass of lifecycle/validation/user gates.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after exact implementation is archived complete on origin/main.
2. Start from fresh independent context with exact archived packet, implementation summary and original accepted SHA; do not carry implementer transient reasoning.
3. Review both positive and negative cases, status/claim/provenance gates and original acceptance contract; reuse immutable evidence only where valid.
4. Record evidence-based R0-NN findings/receipt, complete within bounded review override, never edit reviewed implementation.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `If the reviewed change is accepted, report pipeline-efficiency milestone with measured results.`
- Blockers or open questions: `none`
