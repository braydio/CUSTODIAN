# AGENT VALIDATION GATE DRIFT REPAIR REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-validation-gate-drift-repair-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-validation-gate-drift-repair`
- Locks: `agent-workflow, task-packet-validation`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-validation-gate-drift-repair-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `36cb18230796ec844a7796f0a246085c96179e20`
- Parent implementation: `agent-validation-gate-drift-repair` (`custodian/docs/ai_context/task_packets/archived/AGENT_VALIDATION_GATE_DRIFT_REPAIR.md`)
- Parent review: `review-agent-validation-gate-drift-repair` (`custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_VALIDATION_GATE_DRIFT_REPAIR.md`)
- Findings addressed: `R0-01`
- Affected acceptance: The post-expiry workflow smoke proves expired temporary LFS/procgen markers remain absent from their former policy/tool targets.
- Current defect/evidence: `agent_workflow_smoke.py` checks only TEMP_PROCGEN_PACKET_ROUTING markers and policy text; it omits the `TEMP_LFS_DEGRADED_MODE_START` markers formerly present in four target files.
- Goal: Make the post-expiry regression check cover both removed temporary marker families.
- Completion boundary: The smoke rejects any reintroduced LFS start marker in `custodian/AGENTS.md`, `custodian/tools/agent/workstream.py`, `custodian/tools/agent/land_main.py`, or `tools/custodian_aliases.sh`, while keeping the procgen expiry checks and deleted-workflow assertion intact.
- Current measured state: The four live files contain no LFS marker, but the smoke does not search for it. `agent_workflow_contract` currently passes without proving that invariant.
- Evidence: Parent review finding `R0-01`; expiry commit `761d901c9ffe6c919f52168acecef24a9c7e95c6`; `custodian/tools/validation/agent_workflow_smoke.py`.
- Task-specific authority: The archived parent implementation packet's post-expiry smoke requirements; the former marker targets in commit `761d901c9ffe6c919f52168acecef24a9c7e95c6`; `custodian/tools/validation/agent_workflow_smoke.py` and `validation_manifest.json`.
- Work surface: `custodian/tools/validation/agent_workflow_smoke.py`; `custodian/tools/validation/validation_manifest.json` only if ownership must change; focused workflow validation.
- Required correction: Add `TEMP_LFS_DEGRADED_MODE_START` to the exact former marker targets in the post-expiry check, including the `custodian/AGENTS.md` target alongside its procgen markers. Preserve the assertion that `.github/workflows/expire-lfs-degraded-mode.yml` is absent.
- Preserve: Existing procgen marker assertions, deleted workflow state, validation manifest gate, packet path resolution, and all gameplay/runtime files.
- Non-goals: Do not restore the temporary workflow or guards; do not change packet path mapping; do not modify reviewed implementation outside this focused smoke correction.
- Acceptance:
  - The smoke asserts the LFS marker is absent from all four former targets and continues asserting procgen markers are absent from their former policy target.
  - `python3 custodian/tools/validation/agent_workflow_smoke.py` and `python3 custodian/tools/validation/run_validation.py --test agent_workflow_contract --json` pass.
  - The expiry workflow remains absent and no runtime/game files change.
- Validation: Run `python3 custodian/tools/validation/agent_workflow_smoke.py`, `python3 custodian/tools/validation/run_validation.py --test agent_workflow_contract --json`, and `git diff --check`.
- Task overrides: `none`
- Deferred: No additional expiry-marker families beyond those removed by the cited expiry commit.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Acceptance evidence: The post-expiry smoke checks TEMP_LFS_DEGRADED_MODE_START in all four former files, retains procgen checks in custodian/AGENTS.md, and a temporary negative control proved an injected LFS marker fails. The focused smoke and agent_workflow_contract gate pass.
- Superseded/legacy production path disposition: `removed`
- Evidence: `python3 custodian/tools/validation/agent_workflow_smoke.py`; `python3 custodian/tools/validation/run_validation.py --test agent_workflow_contract --json`; temporary LFS-marker negative control; `git diff --check`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The original post-expiry assertion omitted the former LFS guard marker family.
- Root cause / contributing factors: The implementation retained the old procgen-specific marker list while checking all four former target files.
- Prevention / pipeline improvement: Added explicit per-file marker targets and verified a synthetic reintroduction fails.
- Tooling / docs drift discovered: none.
- Follow-up: `review-agent-validation-gate-drift-repair-review-corrections-1`
- What worked: The existing manifest gate exercised the smoke without changing gate ownership.


## Independent Review

- Status: `passed`
- Review workstream: `review-agent-validation-gate-drift-repair-review-corrections-1`
- Reviewed on main: `35b670d4c`
- Review modes: `code, workflow`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_AGENT_VALIDATION_GATE_DRIFT_REPAIR_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

### Review Notes

- Parent finding `R0-01` is fixed. The smoke checks `TEMP_LFS_DEGRADED_MODE_START` in all four former targets, retains the procgen absence checks in `custodian/AGENTS.md`, and still asserts that the expiry workflow is absent.
- The focused smoke and manifest-backed `agent_workflow_contract` gate pass on live main. Isolated fixtures confirmed that reintroducing each LFS marker, either procgen marker, or the expiry workflow causes rejection.
- The implementation commit changes only the workflow smoke, task packet/index metadata, and its closing summary; no runtime/game files changed.
