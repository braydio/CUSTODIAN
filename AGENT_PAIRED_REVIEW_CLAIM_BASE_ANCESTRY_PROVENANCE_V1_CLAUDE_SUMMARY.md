# Paired Review Claim Base Ancestry Provenance V1 Summary

## Result

Implemented the bounded earlier-claim ancestry correction in source/test commit `4a89ce3c61b773619edf0206ae8905fb231e60b5`.

The split-landing resolver now accepts a landing trace's single earlier claim only when its run identity, canonical local/remote claim refs, claim commit subject, single parent, and ancestry to the selected published claim base all verify. The selected published claim base remains the source-span base; the earlier failed-claim base never widens validation.

## Evidence

- Historical source-bearing archive `agent-paired-review-source-bearing-archive-gate-v1` now resolves with base `8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8`, source head `5b5de5717ae10aa5bbacbd53433571aae016c555`, and exactly that source commit. The expected changed code/test paths are `paired_review_host_validation.py` and `test_paired_review_runner.py`.
- Git proves `83bdbd1e53fdcb06b18a5a5645f70a050c3cba01` is an ancestor of `8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8`; the resolver still returns `8fa7c190` as its base.
- Regression cases cover valid earlier ancestry, wrong claim ref, mismatched claim subject/run, event run mismatch, duplicate claim events, unrelated ancestry, and reversed ancestry.
- `python3 -m unittest test_paired_review_runner -v` from `custodian/tools/agent`: 82 tests passed. This includes the historical queue case, archive-only and main-sync controls, 6519, and W1.
- `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py` passed.
- Changed-file validation passed both selected suites with complete coverage of both changed files; `git diff --check` passed.
- SHA-256 checks for the three protected review-run directories matched their pre-change values. Their claims and the existing source-bearing recovery worktree remain present and unmodified.
- The implementation commit contains only the validator and its tests. This closeout commit contains only the archived packet, summary, and generated packet index.

## Friction and corrections

- The first automatic packet handoff stopped because the review override did not exactly match the repository template. Corrected the override; the next handoff run passed and promoted/indexed the pair.
- The first direct unittest invocation used a package-qualified path that did not fit the test module's sibling imports. Ran the test suite from `custodian/tools/agent`, which passed.
- Early negative fixture variants reused trace refs. Split those checks into independent test fixtures so each rejection proves only its intended condition.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Initial authoring metadata and test invocation did not match the repository's exact workflow conventions; early negative fixtures also reused trace refs.
- Root cause / contributing factors: The handoff validator requires an exact bounded review override, the test file imports sibling modules directly, and multiple fixtures initially reused one run identity.
- Prevention / pipeline improvement: Copy the review override from `AGENT_REVIEW_PACKET_TEMPLATE.md`; invoke the suite from `custodian/tools/agent`; keep negative trace fixtures independently isolated.
- Tooling / docs drift discovered: The package-qualified unittest command in the initial packet did not import in this checkout; the validated invocation runs from `custodian/tools/agent`.
- Follow-up: none
- What worked: The exact historical resolver case validated the ancestry policy against immutable Git traces while protected review evidence stayed byte-identical.

## Next Handoff

- Next workstream: `review-agent-paired-review-claim-base-ancestry-provenance-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401
- Refresh reason: none
- Next action: Run the fresh-context independent paired review. Only after PASS, produce the read-only recovery plan for preserved run `20261019T024516Z-fcfcefa2d521` and stop without applying it or launching its reviewer.
- Blockers or open questions: The three original review claims, traces, worktrees and evidence remain held and unchanged. Do not continue W1.
