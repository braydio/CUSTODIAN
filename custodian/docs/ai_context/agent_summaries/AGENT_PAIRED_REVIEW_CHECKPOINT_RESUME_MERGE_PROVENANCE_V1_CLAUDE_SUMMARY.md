# Paired Review Checkpoint-Resume Merge Provenance V1

Workstream: `agent-paired-review-checkpoint-resume-merge-provenance-v1`

## Result

Added a narrowly authenticated checkpoint → clean resume → main-sync merge case to the paired-review source-span resolver. The resolver now requires the exact two-parent ordering, a same-trace checkpoint and unique later resume on the same run/branch/absolute worktree, a later no-op main-sync witness for the second parent, and an exact deterministic `git merge-tree --write-tree` result. It rejects additional merges and malformed or ambiguous lifecycle pairings.

Implementation-owned paths now come only from first-parent non-merge commits. The source-span provenance records the sync merge SHA, both parents, tree proof, event positions and identifiers, and separate inherited, owned, and overlapping path sets. Overlapping files remain owned. Lifecycle documentation clarifies that `worktree_resumed` records the synchronized HEAD and does not create a retroactive `main_sync(changed=true)` event.

The exact historical Grunt attestation history `f76854cf → d0e44dd8 → 08236e69 → ff48e1d0 → 447c358c` passes source-span resolution, owner-path selection, complete code/test coverage, and immutable coordinator evidence revalidation. The replay excludes inherited `paired_review_runner.py` and `workstream.py` from the Grunt-authored inventory. Five mutated trace variants fail closed. The six-file attestation acceptance test also passes with exact pinned Git inputs.

## Validation

- `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` — 126 tests passed.
- `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py` — passed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — passed, 5/5 selected checks.
- `git diff --check` — passed.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The initial replay fixture used stale project-root attestation bytes and an invalid synthetic Reviewed main. The attestation verifier also located only the original add commit, not the later commit carrying the exact expanded authorization.
- Root cause / contributing factors: Persistent checkout content lagged fetched main, and the exact attestation was deliberately expanded in a later reviewed commit.
- Prevention / pipeline improvement: Test fixtures now load exact pinned Git inputs and bind review evidence to the real archive identity. The verifier identifies the unique commit containing the exact attestation blob.
- Tooling / docs drift discovered: The lifecycle primer did not explain checkpoint-resume synchronization provenance; clarified in the same change.
- Follow-up: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1`
- What worked: Full historical replay exercised downstream coverage and immutable evidence checks before recovery.

## Next Handoff

- Next workstream: `review-agent-paired-review-checkpoint-resume-merge-provenance-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f
- Refresh reason: none
- Next action: Run the fresh-context paired review. Only after its independent PASS, retry the held Grunt attestation review's read-only same-run host-validation plan.
- Blockers or open questions: none
