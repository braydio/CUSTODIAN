# AGENT VALIDATION FAILURE ATTRIBUTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-validation-failure-attribution-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `validation-infrastructure`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-validation-failure-attribution-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Independent review must falsify any red-to-green shortcut`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in durable implementation/review/recovery/closeout summaries and final Next Handoff.
- Goal: Make changed-file failure reports attributable to exact tests, selection owners, skip reasons and explicit immutable baseline evidence without weakening green-closeout requirements.
- Completion boundary: Deliver read-only validation_failure_triage.py and focused tests consuming canonical run_validation.py result JSON and manifest; make only minimal additive runner metadata changes if required.
- Current measured state: run_validation.py already emits failed/timeout/infrastructure_error/skipped, fatal diagnostics and lower_tier_failed skips. Stealth Perception reported 56 pass/3 baseline fail/16 skip; H5 reported 38 pass/2 fail/1 timeout/1 skip. No surveyed canonical triage joins an immutable baseline result and ownership reason.
- Evidence: custodian/tools/validation/run_validation.py and validation_manifest.json; STEALTH_PERCEPTION_FOUNDATION_CLAUDE_SUMMARY.md and HUB_MUSTER_CONTINUITY_PORT_DEPLOYMENT_CLAUDE_SUMMARY.md preserved on their agent branches; project validation recipes.
- Task-specific authority: Existing run_validation.py output schema, validation_manifest.json and workstream.py finish validation report gate.
- Work surface: Create custodian/tools/validation/validation_failure_triage.py plus focused tests; add only necessary provenance fields to run_validation.py and manifest/docs.
- Change: Implement triage changed-report.json [--baseline baseline-report.json] --json. For every failure/timeout/skip/infrastructure error report exact test ID, manifest owners/rule, failure diagnostics, duration vs timeout, skip blocker and baseline provenance SHA when explicitly supplied. Show baseline-red, candidate-only-red or unknown without calling a baseline-red failure unrelated or waived. Optional direct clean-baseline recheck must isolate worktree, use existing writer lock and check LFS/import first.
- Preserve: A red sweep remains red; skipped is not passed; an absent or mismatched immutable baseline is unknown; no implicit network LFS or root worktree mutation.
- Non-goals: No second test runner, rerun scheduler, baseline-waiver system, auto-claim or finish bypass.
- Acceptance: 1) H5/Stealth/NPA-7-shaped fixtures preserve all failing/skipped IDs; 2) baseline-red+candidate-red remains FAIL; 3) baseline-green+candidate-red flagged regression; 4) missing/incorrect baseline cannot be invented; 5) timeout/fatal/import errors never waived; 6) deterministic read-only output with source test owner and skip reasons.
- Validation: Run focused unit/negative fixture tests, then canonical validation-runner and manifest contract checks, python3 custodian/tools/agent/check_ai_context.py --json, pairing/index checks, python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json, git diff --check.
- Deferred: Automatic cross-repo benchmark comparisons, acceptance waivers and CI performance dashboards.

- Task overrides: `none`

## Handoff

- Next workstream: `review-agent-validation-failure-attribution-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After complete validation, landing and archive, initiate its fresh-context paired review.`
- Blockers or open questions: `none`
