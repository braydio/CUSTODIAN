# Grunt Raster Scope Attestation V1 — Execution Summary

## Result

Partial; implementation remains fail-closed and is not ready to land or review. The exact post-hoc Markdown attestation and its accepted-review verifier are implemented locally, but the packet's historical replay acceptance cannot pass without addressing additional original-archive source paths that are outside the published three-file attestation.

The attestation verifier checks the exact original archive SHA, archived packet blob, three Markdown blob IDs and regular-file modes, canonical JSON bytes, unique Git origin, and an archived independent PASS. It uses the repository's `review_outcome` and `verify_review_receipt_delta` authorities. The coordinator source-span provenance includes fields for the attestation commit/blob/digest and approval packet identities when the full source-span gate succeeds. No broad Markdown matcher was added.

A synthetic Git-history test shows the exact attestation is rejected before review acceptance, accepted after a canonical independent PASS and target receipt, and rejected after attestation mutation or forged findings outcome. The original Grunt source-span replay then continues to the existing source/test documentation gate and fails closed on these additional exact paths:

- `custodian/tools/iteration/raster_pipeline/__init__.py`
- `custodian/tools/iteration/grunt_candidate_ab/grunt_raster_plan.json`
- `custodian/tools/validation/validation_manifest.json`

The archived Grunt packet names the containing directories and roles, but not these exact paths. The current task authorizes only the three Markdown files. Extending the exception to these source/data paths or introducing directory-based source authorization would exceed the packet's exact scope and could weaken a separate source/test gate. A bounded packet refresh or separately reviewed exact authorization is required before the original Grunt replay can pass.

## Validation

- `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` — PASS, 114 tests.
- Focused synthetic attestation approval/tamper test — PASS.
- `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py` — PASS.
- `git diff --check` — PASS.
- Historical Grunt source-span replay with the synthetic accepted attestation — correctly stops at the three undocumented source/data paths above; packet acceptance A1 remains unmet.
- No `run_validation.py --changed` sweep: the task is stopped at the packet's explicit scope boundary before implementation closeout.
- No changes to the held Grunt review run, claim/worktree, raster implementation, or human visual-review evidence.

## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: The published correction packet identified the three undeclared Markdown files as the only known source-scope mismatch, but the full historical replay exposed three additional source/data paths rejected by the unchanged exact source/test documentation gate.
- Root cause / contributing factors: The archived Grunt packet uses parent-directory and role descriptions for those paths; the coordinator's source/test gate requires file-level documentation and the current attestation packet permits exactly three Markdown paths.
- Prevention / pipeline improvement: Before publishing a provenance correction, replay the entire historical source span through every downstream gate, not only the first failing gate; enumerate all exact rejected paths before fixing packet scope.
- Tooling / docs drift discovered: The failure occurs after the Markdown gate; source/test path authorization still lacks an exact-file contract for the three listed entries.
- Follow-up: manual-follow-up
- What worked: Canonical Git history fixtures verified accepted-review gating, tamper detection, and forged-outcome rejection without touching the preserved Grunt run.

## Next Handoff
- Next workstream: none
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f
- Refresh reason: The full original Grunt source-span replay reveals three additional exact source/data path rejections outside the correction packet's three-file Markdown attestation.
- Next action: Refresh the correction scope to authorize these exact source/data paths with their historical blob IDs and modes, or define a separate narrowly reviewed source-scope authorization; then rerun the full historical replay and all existing source/test negatives.
- Blockers or open questions: Whether to expand the correction packet to these exact source/data paths; no change is authorized to the original archived Grunt packet or generic directory/prefix matching.
