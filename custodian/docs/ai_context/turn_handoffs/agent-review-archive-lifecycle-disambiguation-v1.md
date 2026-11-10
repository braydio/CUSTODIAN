<!-- V2 turn metadata -->
Task identity: agent-review-archive-lifecycle-disambiguation-v1
Task definition: custodian/docs/ai_context/task_packets/AGENT_REVIEW_ARCHIVE_LIFECYCLE_DISAMBIGUATION_V1.md at origin/main 6ef13efbbd1486f18d0f799817d6f521ef564c46
Remote branch: agent/agent-review-archive-lifecycle-disambiguation-v1
Acquisition mode: normal
Acquisition source: origin/main (no prior branch; fresh start)
Acquisition source commit: b71356412a96551f4f74b0b3a4aff8f48e18daa2
Checkpoint base: 781ecf984bec706849a37ad69e9bc7123afe62b1
<!-- /V2 turn metadata -->

# V2 Turn Handoff: Archive Lifecycle Disambiguation

Original goal: Correct the generic archived review target resolver so the authentic implementation-introduction commit is selected when a later restoration of the same archive blob produces multiple Add events.

Implemented: `custodian/tools/agent/review_receipt_delta.py` now authenticates exactly one multiple-event candidate using matching active packet identity in the candidate parent, complete archived identity, and later matching active-path retirement in candidate ancestry. It preserves unique-candidate behavior and fails closed when no or multiple lifecycle proofs qualify. `custodian/tools/agent/test_review_receipt_delta.py` adds four focused regressions.

Remaining: Obtain and complete the fresh paired independent review `review-agent-review-archive-lifecycle-disambiguation-v1`. Only after accepted review, retry the original `review-ash-bell-surface-lift-v2-asset-intake` using its preserved evidence. Keep documentation drift about conflicting root AGENTS.md legacy/V2 landing guidance out of this resolver scope and route it to its documentation owner.

Validation: Focused tests 4/4 passed; existing paired-review runner suite 326/326 passed; `py_compile` passed; `git diff --check` passed; `run_validation.py --changed --base origin/main --json` passed and covered both changed files with `agent_workflow_contract`. PR #135 merged with merge commit `6ef13efbbd1486f18d0f799817d6f521ef564c46`; implementation commit `781ecf984bec706849a37ad69e9bc7123afe62b1` is an ancestor of `origin/main`. Pre-merge Cross-platform filenames and Fast changed validation checks passed. PR: https://github.com/braydio/CUSTODIAN/pull/135

Resume: Use `python3 custodian/tools/agent/dispatch.py claim agent-review-archive-lifecycle-disambiguation-v1 --agent codex` or the supported V2 resume path after verifying the retained remote `agent/agent-review-archive-lifecycle-disambiguation-v1` branch and this handoff. Do not treat this checkpoint as task completion or review PASS.

Sources/evidence: Implementation packet and paired review packet on `origin/main` at `b71356412a96551f4f74b0b3a4aff8f48e18daa2`; code commit `781ecf984bec706849a37ad69e9bc7123afe62b1`; PR #135 merge commit `6ef13efbbd1486f18d0f799817d6f521ef564c46`; current orchestrator chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
