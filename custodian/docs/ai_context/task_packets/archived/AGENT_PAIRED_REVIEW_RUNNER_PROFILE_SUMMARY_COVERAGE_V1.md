# Paired-review bootstrap profile summary coverage

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-runner-profile-summary-coverage-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-runner-publication-input-grammar-v1`
- Locks: `paired-review-runner-checkout-profile`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-runner-profile-summary-coverage-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `The tracked sparse profile gates fresh independent reviews; exact dependency coverage must be checked independently before any review claim.`
- Reviewed main: `57f796040cc3e3a51a213b529a2baeeef6fa9627`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Visual review: `none`
- Goal: Add the exact root-level implementation summaries required by the pending grammar review and this profile correction’s own paired review to the existing lightweight bootstrap profile.
- Completion boundary: Correct only the existing tracked profile JSON, prove the exact two paths are covered without broadening the sparse checkout, and land through the normal workstream lifecycle with a fresh paired review.
- Current measured state: The grammar implementation is landed and its changed-file validation is green. The canonical runner rejects the existing bootstrap profile before claim because it omits `AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1_CLAUDE_SUMMARY.md`. Full checkout is unavailable on this host (2,651,750,400 bytes available versus 7,264,125,076 required). No review claim or reviewer process was created.
- Evidence: RC-083 in the Authoring chat; failed safe preclaim run `20261031T153657Z-fc9d201d733a`; exact tracked profile contents; exact archived grammar packet and active paired review packet.
- Task-specific authority: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/agent/paired_review_runner.py`; archived grammar implementation packet and its active review packet.
- Work surface: `custodian/docs/ai_context/worktree_profiles/agent_ops_paired_review_bootstrap_v1.json` only.
- Publication inputs: `custodian/docs/ai_context/worktree_profiles/agent_ops_paired_review_bootstrap_v1.json`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change: Add only these two exact root paths to `include_paths`: `AGENT_PAIRED_REVIEW_RUNNER_PUBLICATION_INPUT_GRAMMAR_V1_CLAUDE_SUMMARY.md` and `AGENT_PAIRED_REVIEW_RUNNER_PROFILE_SUMMARY_COVERAGE_V1_CLAUDE_SUMMARY.md`. Keep every existing profile entry and the bounded sparse path set intact.
- Preserve: All current profile entries, existing claims and locks, the landed grammar implementation and its summary, all historical packets and review evidence, and the runner’s fail-closed coverage check.
- Non-goals: Change runner/provisioning code; add wildcard or broad root inclusion; rewrite historical packets; launch a reviewer; change grammar, adapter, or provisioning verdicts; attempt a full checkout.
- Acceptance: (A1) The profile changes by exactly two root summary include paths and no other paths. (A2) Its digest is valid and `worktree_provisioning.inventory` accepts the candidate profile against the committed task tree. (A3) The runner-equivalent exact prefix matcher covers the root summary required for the profile-correction paired review and the landed grammar correction paired review; the canonical runner rechecks both after publication before launching reviewers. (A4) No claim or reviewer process is created before the corrected profile is published. (A5) The grammar implementation remains unchanged.
- Validation: Exact JSON diff and path assertions; profile parser/inventory validation at the committed candidate; exact prefix-matcher coverage assertions for both summary paths; category and task-packet authoring checks; `git diff --check`. The canonical runner rechecks published profile coverage before each fresh review claim.
- Task overrides: `TASK OVERRIDE: Change only the tracked lightweight bootstrap profile JSON; do not edit the runner, historical packets, or reviewed implementation.`
- Deferred: General profile generation from canonical dependency closure; grammar, adapter and provisioning reviews remain sequenced successors.
- Summary backlink: Include the exact Authoring chat URL in all durable summaries and handoffs.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: The tracked profile has exactly two additional root summary paths, with every prior include preserved and no broad root inclusion. JSON parsing, unique-path assertions, and exact delta comparison passed. The changed-file validator passed its complete selected coverage (1/1). Candidate-tree profile parsing/inventory and runner-equivalent exact prefix coverage are recorded in the validation report. After landing, the canonical runner will recheck each exact dependency closure before either fresh reviewer claim.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The canonical runner first rejected the profile because it lacked the landed grammar summary. The bounded correction added that exact path plus this implementation summary, which the profile itself must expose for the fresh paired review.
- Tooling/docs drift discovered: The reusable sparse profile enumerates root-level implementation summaries individually, so newly landed summaries need explicit profile entries.
- Follow-up: The canonical runner must validate and launch this profile correction's paired review; after PASS, validate and launch the existing grammar correction review.
- What worked: The runner failed closed before claim creation, and the path-exact profile update resolves the missing dependency without broadening the checkout.
