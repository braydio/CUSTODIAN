# Agent Workstream Closeout Preflight V1

Implemented `workstream.py preflight <workstream-id> [--validation-report path] --json` as a read-only preview of the existing finish gates. It reports active versus archived associated packets, completion truth, stale archived entries in the managed index, classified untracked artifacts, exact summary backlinks and commit presence, paired review receipt/provenance/scope, cached branch state, and validation-report integrity. The JSON includes actionable blockers and labels post-sync/landing predicates as unknown until `finish` runs.

The preflight uses only read operations and cached refs. It does not fetch, acquire the lifecycle lock, create a run trace, synchronize, stage, commit, or modify refs/worktrees. The existing `finish` path and its landing policy are unchanged. The paired-review check now shares one helper between preview and finish so the report uses the same target-receipt and authorized-artifact-scope rule.

Documentation in `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` describes the command and its limits. Temporary-repository tests cover a ready state, active/incomplete packet states, false/missing completion truth, stale index entries, missing authoring-chat backlinks, untracked artifact classification, invalid and non-green validation reports, missing review receipts/provenance, stable JSON output, and preservation of file bytes, refs, and worktrees.

## Validation

- `python3 -m py_compile custodian/tools/agent/workstream.py custodian/tools/agent/test_workstream_artifacts.py` — passed.
- `python3 -m unittest custodian.tools.agent.test_workstream_artifacts -v` — 13 passed.
- `python3 -m unittest custodian.tools.agent.test_workstream -v` — 38 passed.
- `python3 custodian/tools/agent/check_ai_context.py --json` — passed with zero findings.
- `python3 custodian/tools/agent/validate_review_pairing.py` — passed; 67 auto review packets correctly paired.
- `python3 custodian/tools/agent/task_packet_index.py` — passed after packet archive.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — passed with complete coverage; all four selected checks passed.
- `git diff --check` — passed before final validation; rerun after summary update.

The CLI was exercised on the active worktree and returned a blocked JSON report with expected reasons: dirty worktree, active task packet, missing Completion Truth, uncommitted closing summary/backlink, and absent validation report. `post_sync.status` was `unknown`.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first fixture run had an incorrect blocker count and omitted the required Evidence field in its green Completion Truth sample.
- Root cause / contributing factors: The fixture conflated separate packet and completion-truth gates and did not fully model the shared contract.
- Prevention / pipeline improvement: Build temporary fixtures from the shared contract shape and assert each finish gate independently.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Reusing finish's existing validation and paired-review scope helpers kept the preview aligned with the authoritative closeout path.

## Next Handoff
- Next workstream: review-agent-workstream-closeout-preflight-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: Run the independent paired review from fresh reviewer context after this implementation lands.
- Blockers or open questions: none
