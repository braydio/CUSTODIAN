# PAIRED REVIEW HOST VALIDATION: BRACED WORK SURFACE PATHS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-braced-work-surface-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-source-scope`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-braced-work-surface-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fail-closed independent-review validation provenance is security-critical`
- Reviewed main: `a563a872dbe11a582c776bc329c334cdda73c543`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Goal: Let the existing coordinator host validator recognize exact implementation source files declared in bounded braced Work surface notation without widening review source authority.
- Completion boundary: Exact bounded brace-list expansion works only for the archived target packet's `Work surface` header, existing positive provenance for MF1 resolves, forged/undeclared source paths still reject, and all relevant paired-review tests pass. No protected MF1 run, claim, or archived packet is mutated.
- Current measured state: MF1's actual source-bearing implementation+archive landed at `645f1a701696045149fbf9dd3c988cbbadfcf06b`; later main `a563a872dbe11a582c776bc329c334cdda73c543` only edited an unrelated task packet. Archived MF1 `Work surface` declares `custodian/tools/operator/motion_foundry/{__init__,schema,rig,motion,render,qa,cli}.py` plus an explicit smoke. `paired_review_host_validation.py::_split_landing_source_span` currently builds `documented` from literal paths and checks `is_documented`; it neither recognizes nor expands this exact brace-list. As a result the pending `review-operator-motion-foundry-core-v1` host validator rejects otherwise documented MF1 source files pre-review. The reviewer has NOT started.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py` around the `documented` and `is_documented` source-span check; `custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_MOTION_FOUNDRY_CORE_V1.md`; `custodian/tools/validation/validation_manifest.json` `paired_review_runner_unit`; preserved local run `.git/custodian-review-runs/review-operator-motion-foundry-core-v1/20261019T113817Z-30745c8a87a1`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` host-validation recovery; the current `_split_landing_source_span` source/traces/paths gate; the archived implementation packet's original Work surface (read-only); exact report/source hash verification. Current review baseline remains immutable.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`. Do not edit `paired_review_runner.py` unless a proven minimal compatibility change is required. Do not edit any existing MF1 packet, implementation source, review worktree, claim, source trace or run evidence.
- Publication inputs: `none`
- Change: 
  1. Add one small pure helper near existing repository-path recognition that expands **only** backtick-delimited, repo-relative, bounded brace alternatives in the target packet's `Work surface` header: `custodian/<literal-directory>/{name_a,name_b,...}.py` -> exact `custodian/<literal-directory>/name_a.py`, etc. Strictly validate a `custodian/` prefix, literal safe directory segments (no `.`, `..`, empty segments, slash in option, wildcard, nested brace, or absolute path), a finite positive number of distinctive safe identifier alternatives (suggest 2..32), and approved implementation suffixes (the current `_IMPLEMENTATION_SUFFIXES`, or narrower explicit `.py` if sufficient). Reject malformed/ambiguous expressions rather than treating them as wildcard authorization. Preserve already recognized explicit source paths and explicit Work surface markdown behavior.
  2. Extend the existing `documented` path set only with this helper's exact expanded paths in `_split_landing_source_span`, using the `header_field(target_packet_text, "Work surface")` value. Do **not** broaden the fallback `name in target_packet_text`, packet token similarity, or `_IMPLEMENTATION_SUFFIXES`. The exact `code_paths`/archive checks, trace verification, file-mode restrictions, selected test ownership and post-validation file hashes remain mandatory.
  3. Add dedicated table-driven helper tests plus synthetic real-Git source-bearing archive fixture coverage to `PairedReviewHostValidationTests`: positive grouped MF1-style seven-module declaration; missing one declared module rejects; extra path with plausible prefix or basename rejects; malformed/nested/escape/absolute or wildcard form never authorizes a path; a lookalike brace expression **outside Work surface** cannot authorize an implementation file; standalone literal paths and markdown gate remain unchanged. Include a real source-span resolver regression pinned to the archive+source-bearing closeout and the actual MF1 `645f1a70` commit where local trace refs are available. Treat absent local historical trace as missing environment evidence, not a test PASS.
  4. Keep this tooling packet's own Work surface as **two explicit paths** (not braced); do not make its fresh review depend on recovering MF1 first.
- Preserve: Original MF1 archived-packet bytes and pinned review/main SHA; existing claimed `agent/review-operator-motion-foundry-core-v1` branch/worktree; entire `20261019T113817Z-30745c8a87a1` run evidence; no forced claim release, no premature PASS, no unrelated queue/validation changes. Existing rejection for unrelated code, undocumented markdown and executable/symlink paths must remain green.
- Non-goals: No rerun of MF1 implementation, no modification of the Motion Foundry code, no rewrite of the archived packet's Work surface, no new review runner or bypass of host validation, no reviewer verdict authoring, no direct recovery apply in this workstream.
- Acceptance: Exact seven expanded `motion_foundry/*.py` paths plus explicit smoke are treated as documented; undeclared eighth file and outside-header brace remain rejected; untrusted path traversal, malformed braces and widened filename matching rejected; strict archive provenance/trace/validation coverage still checked; focused tests and changed-set validation pass. Report true green/red results without masking nonzero command exit codes.
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner.PairedReviewHostValidationTests` if module import from repository root works; otherwise the supported local `python3 custodian/tools/agent/test_paired_review_runner.py` test entrypoint. `python3 custodian/tools/validation/run_validation.py --changed --json`, `git diff --check`. Use the current validation manifest's `paired_review_runner_unit` owner and preserve real failure codes. If a live MF1 historical source-span positive requires protected local state, do not mutate it; rely on fresh isolated real-Git fixtures plus read-only positive tracing and report any remaining gap.
- Task overrides: `none`
- Deferred: Do not recover the original review in this tooling claim; after independently accepted tooling review, the original review's coordinator owner performs same-run host-validation continuation.

## Dependency and Protected Recovery Note

This packet deliberately has `Depends on: none`: depending on `review-operator-motion-foundry-core-v1` would deadlock because that review is the consumer blocked by this validator defect. The narrow `paired-review-source-scope` lock must **not** require, steal, or release MF1's existing `operator-motion-foundry` lock. Do not claim or enter its protected worktree during implementation.

## Next Handoff

- Next workstream: `review-agent-paired-review-braced-work-surface-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Fresh independent review of the exact parser expansion and provenance guard, then return to the original protected MF1 review run, not a new review claim.`
- Blockers or open questions: `Original MF1 run is protected in host_validation_recovery; no reviewer has launched. This tool change alone does not assert recovery.`
