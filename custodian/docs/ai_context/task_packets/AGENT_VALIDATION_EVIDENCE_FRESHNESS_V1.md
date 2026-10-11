# AGENT VALIDATION EVIDENCE FRESHNESS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-validation-evidence-freshness-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-agent-bounded-task-context-v1`
- Locks: `validation-infrastructure`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-validation-evidence-freshness-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Independent fresh-context review required for high-impact pipeline safety and resource-use changes`
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Goal: Explain precisely when a previously green validation report is still evidentially relevant and why a changed-tree/post-sync sweep must rerun, without caching a PASS past the authoritative finish gate.
- Completion boundary: Enhance the existing runner/triage and workstream preflight metadata with deterministic input provenance and a read-only freshness comparison command; leave test execution and final finish acceptance unchanged.
- Current measured state: The long Codex run repeats changed-file sweeps after sync and receives opaque failure/staleness messages. `run_validation.py` output currently reports test selection and changed_files/coverage but not a complete execution input identity. PF2 validation_failure_triage.py describes baseline-red origin but does not determine test artifact equivalence. PF4 workstream.py preflight reports report status; its finish still correctly requires genuinely green post-sync validation.
- Evidence: 2026-10-11 Codex conversation, custodian/tools/validation/run_validation.py and validation_manifest.json, validation_failure_triage.py, custodian/tools/agent/workstream.py closeout_preflight/validation_green, GodotJobBudget and project lock, existing PF2/PF4 archived packets/review findings.
- Task-specific authority: run_validation.py is sole test-execution and source-selection authority; validation_manifest.json owns tests; PF2 triage for failure classification; workstream.py finish owns required reports. Read-only comparison is evidence metadata, not a validation grant.
- Work surface: Add additive `provenance` metadata to existing runner JSON only when deterministically available; implement small `custodian/tools/validation/validation_evidence_freshness.py` comparator plus focused tests; optionally enhance workstream.py preflight diagnostics without changing green predicate.
- Change: Capture named immutable Git commit SHA (and dirty/untracked relevant-state marker), input source tree/patch digest, validation manifest and warning-registry digest, selected test IDs/reasons, exact CLI selector/tier/base, test/resource hash where practical, Godot/Python runner version and import state required by those tests. A comparison of supplied earlier report and current environment should return `exact_match`, `recheck_required`, or `unknown` with explicit reasons and test IDs. Match only on defensibly complete evidence, never infer from unchanged commit alone when worktree dirty, test artifacts, imports, env or manifest differ. After main advances, explain added/changed tests/files and only schedule the canonical required sweep from its actual selector; display already supported focused evidence for review planning but never let reused JSON satisfy workstream.py finish or post-sync gate. Preserve failed/timeouts/skips from PF2 without suppressing them.
- Preserve: All existing exit codes/green gate, coverage and fatal Godot import handling, tier-blocking, writer/concurrency budget, fresh reviewer independence and no implicit LFS download.
- Non-goals: No skipping required changed-file/post-sync checks, no new test runner, no automatic waiver, no global content cache, no arbitrary previously-green baseline treated as green finish, no CI provider redesign.
- Acceptance: 1) Deterministic report fingerprints for same sources/manifest/test ID/flags/runner inputs; 2) changed file, staged diff, manifest, warning patterns, version, asset state, selected tests or unknown env yields recheck_required/unknown; 3) old run reports lacking provenance become unknown; 4) red/skipped/timeout never reusable as proof; 5) comparator emits actionable minimal rerun selection rationale but final runner/finish remains unchanged; 6) independent tests demonstrate same SHA yet changed dirty bytes blocks exact_match; 7) two consecutive identical inputs return same explanations; 8) no resource/import cache mutates through read-only comparison.
- Validation: Focused unit and temporary Git repo tests for clean/dirty/staged/different manifest/warnings/source/test selection/runner version and missing provenance; PF2 triage and PF4 preflight regression; run_validation.py selected focused checks before changed-file sweep; check_ai_context.py --json, pairing/index, git diff --check.
- Task overrides: `none`
- Deferred: General green-test caching, skip-by-hash execution, distributed CI artifact cache and performance tuning of unrelated Godot tests.

## Handoff

- Next workstream: `review-agent-validation-evidence-freshness-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After completed implementation landing/archival, initiate this exact independent fresh-context paired review.`
- Blockers or open questions: `none`
