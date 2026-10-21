# Review Paired Review Failed Host Validation Import Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-failed-host-validation-import-recovery-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-failed-host-validation-import-recovery-v1`
- Locks: `paired-review-host-import-recovery`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-paired-review-failed-host-validation-import-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`
- Reviewed main: `f635c33d8bb209d9cbc4fafb4aff88af27084867`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify failed-host-report replacement, generated Grunt import-sidecar classification, unsafe deletion, source mutation hiding, unbounded retries, and forged PASS before the recovery can be used on the protected claimed run.
- Current measured state: Original protected reviewer workstream `review-agent-paired-review-missing-archived-disposition-continuation-v1` remains in host-validation recovery with run `20261020T165418Z-53992bd05f83`, its failed import/TLS report and 12 adjacent PNG import sidecars untouched, no independent verdict. Do not try to claim or repair that run from this reviewer worktree.
- Evidence: Exact original run/claim, protected sidecar filenames and hashes, original full report-pair SHA256, new bounded continuation proof, code/test changes, canonical validation reports and reviewer artifact authorizations. Reference both `custodian/tools/agent/paired_review_runner.py` and `custodian/tools/agent/paired_review_host_validation.py`.
- Work surface: Review-only reads of `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`. Only canonical bounded review receipt, packet archive, index and root summary may be authored.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_MISSING_ARCHIVED_DISPOSITION_CONTINUATION_V1.md`
- Review focus: Independently verify the manifest diff is EXACTLY `paired_review_runner_unit.timeout_sec: 30 -> 90`, a finite bound with every other manifest test/owner/tier/selection unchanged. Confirm canonical `--test paired_review_runner_unit` and expanded changed-file validation are genuinely green, not inferred from a direct unittest PASS. Replay COMPLETE original failure -> exact 12-file preservation -> append-only new full host validation -> optional bounded TLS retry -> independent disposition -> target receipt and coordinator closeout. Confirm genuine Godot import/test failure is never whitelisted and no unsafe file cleanup or network TLS disable occurs. Test false positive .png.import, wrong sibling, symlink, staged/modified tracked source, changed file between plan/apply, swapped original report, original run sidecar deleted without byte-verified copy, extra attempts, wrong branch/ref, fake reviewer PASS and missing archived review. Compare original protected Git refs and evidence before/after read-only inspection.
- Acceptance: Fresh-context findings-first R0-NN review of A1-A9 of archived implementation, including separate negative controls and proven full historical replay. PASS only if no blocking findings/material gaps, all impacted tests green, original run/claim unchanged, no missing provenance or incomplete cleanup. Otherwise publish findings, do not accept protected reviewer as passed.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; focused Godot artifact safety/negative fixtures; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`, exact manifest-delta audit against the pinned implementation parent, and canonical reviewer validation. No new visual media or unbounded broad sweeps.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Inspect implementation's exact landed source span and independent evidence, then replay a real temporary-Git failure with the 12 Grunt sidecars.
2. Deliberately corrupt failure report and provenance, plan digest, generated import contents, source hash, worktree status, and child retry identity. Reject any path that silently upgrades failure to PASS.
3. Finish with canonical accepted reviewer outcome or truthful findings and bounded correction. NEVER apply recovery to the original Grunt-related claim in this packet.

## Handoff
- Next workstream: `none`
- After genuine PASS the existing original review run's read-only recovery planning becomes eligible; separate host operator authorizes apply.
