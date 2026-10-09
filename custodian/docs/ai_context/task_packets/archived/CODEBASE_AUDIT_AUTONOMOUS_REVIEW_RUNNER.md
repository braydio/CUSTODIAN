# CODEBASE AUDIT AUTONOMOUS REVIEW RUNNER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `codebase-audit-autonomous-review-runner`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-task-packet-queue-stranding-hardening-review-corrections-1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-codebase-audit-autonomous-review-runner`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new process-spawning control-plane seam; independent review must falsify duplicate claims, non-fresh contexts, unsafe recovery, and accidental queue/finish coupling`
- Reviewed main: `7eddb322aca7871a9146fe4e6952fe265039f8cd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Make paired CUSTODIAN reviews actually launch in a mechanically fresh Codex context without user message relay, while preserving the existing dispatcher, workstream, review-lineage and human-gate authorities.
- Completion boundary: Add one bounded synchronous paired-review runner and integrate it into the agent successor instructions. When an already-completed implementation/correction names an eligible paired review with no human refresh, the outer execution flow can invoke one script that preflights Codex, claims that exact review via the existing dispatcher, launches fresh `codex exec --ephemeral` in the claimed review worktree, supervises the process, persists runner evidence outside the worktree, and verifies the durable post-run state. `workstream.py finish` itself remains unchanged except for test/helper imports if strictly required; no general worker daemon or alternate queue is added.
- Current measured state: CUSTODIAN already has fetched-`origin/main` dispatch, remote claim CAS, per-workstream mutexes, isolated worktrees, push-first recovery, serialized landing, finite correction/re-review lineage, durable `*_CLAUDE_SUMMARY.md` handoffs, and autonomous same-series successor instructions. Paired review packets require `Reviewer context: fresh`, but the lifecycle currently contains no executable launcher; agents either reuse a manually fresh context or rely on user/session orchestration. F11 source audit confirms queue-stranding hardening is archived complete. Current Codex CLI supports non-interactive `codex exec`, `--ephemeral`, JSON event output and `--output-last-message`; runtime implementation must still inspect installed `codex exec --help` rather than assuming stale local flags.
- Evidence: `design/04_architecture/codebase_systems_audit/F11_AGENT_VALIDATION_AUTOMATION.md`; `custodian/tools/agent/{dispatch,workstream,workflow_control}.py`; `custodian/tools/agent/test_{dispatch,workstream,review_contract}.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; root/local `AGENTS.md`; `.agents/skills/custodian-next/SKILL.md`; archived `TASK_PACKET_QUEUE_STRANDING_HARDENING*`, `AGENT_REVIEW_PIPELINE*`, `AGENT_DISPATCH_CLAIM_RECEIPT_HARDENING`; active `ULTRA_CODEX_PACKET_WORKER.md` only as adjacent non-interactive-Codex precedent.
- Task-specific authority: F11 decision lock above; existing dispatcher remains sole packet eligibility/claim authority; existing workstream lifecycle remains sole landing/teardown authority; existing review/correction contract remains sole review-lineage authority.
- Work surface: New `custodian/tools/agent/paired_review_runner.py` (or equivalently focused name); focused tests beside agent tooling; `AGENT_WORKSTREAM_LIFECYCLE.md`; root/local `AGENTS.md`; `.agents/skills/custodian-next/SKILL.md`; `CURRENT_STATE.md` / `FILE_INDEX.md` only as consequence-driven documentation; validation manifest if the repository requires registration.
- Change:
  1. Implement a CLI such as `python3 custodian/tools/agent/paired_review_runner.py <review-workstream>`.
  2. Before any claim, fetch current `origin/main`; verify the named packet exists, `Kind: review`, `Status: ready`, `Dispatch: auto`, has no ChatGPT/user refresh/human gate, and names a completed review target/dependency. Reject ordinary implementation packets and global-next usage.
  3. Preflight a usable Codex executable and supported non-interactive exec interface **before claim**. Use the installed CLI's help/version at runtime rather than hard-coding assumptions that may age. The canonical fresh-session property is `codex exec --ephemeral`.
  4. Claim the exact review through existing `dispatch.py claim <id> --agent codex-reviewer` or shared dispatcher API; parse/verify the structured receipt and use only its returned worktree/packet identity.
  5. Launch one synchronous Codex process with cwd set to the claimed review worktree. Feed a generated prompt via stdin telling the reviewer to read root/local AGENTS, the claimed review packet, archived implementation packet + implementation summary, live diff/current main and required validation; explicitly forbid resuming/using the implementation-session transcript or editing reviewed implementation code. The process must complete the normal review workstream lifecycle, including durable summary/receipt and finish/landing when validation permits.
  6. Run Codex with the least automated permissions that the installed CLI can support while still allowing the repository's normal review commands and lifecycle. Do not bake credentials or secrets into prompts/logs. Keep sandbox/approval flags runtime-detectable/configurable and document the selected local default.
  7. Persist runner metadata, Codex JSONL/event output and final-message capture under Git-common-directory workflow state (for example `.git/custodian-review-runs/<workstream>/<run-id>/`), not the task worktree or tracked tree. Never print credential contents.
  8. After Codex exits, fetch and verify state. Success requires a durable review summary and either: review workstream completed/landed; or a clearly preserved active/blocked review workstream with its durable summary explaining the blocker. A zero process exit without durable state is failure.
  9. If preflight fails, no claim is created. If process launch/execution fails after claim, preserve the claim/worktree/branch and emit a recovery card with run-log path; never silently delete/reclaim it.
  10. Update autonomous successor instructions so paired-review successors invoke this runner rather than being claimed inside the implementation model context. Corrections remain ordinary implementation workstreams; each paired re-review routes through this runner again.
- Preserve: Remote claim CAS/mutex semantics; exact-successor routing; no unrelated global queue hopping; finite automatic review-cycle cap; review packets cannot edit reviewed implementation; existing validation/landing authority; persistent checkout preservation; human visual/canon/planning stops; arbitrary agent IDs remain supported outside this runner.
- Non-goals: No persistent daemon/service; no Ultra worker redesign; no new task queue; no generalized multi-agent scheduler; no cloud Agents API/app-server migration; no model selection UI; no background detached reviews; no auto-resolution of human gates; no changes to game/runtime code.
- Acceptance: (1) missing/unsupported Codex fails before claim; (2) non-review or human-gated successor is refused; (3) exact eligible review is claimed once through existing dispatcher; (4) duplicate/parallel runner cannot spawn a second reviewer for the same workstream; (5) subprocess invocation proves fresh non-resumed ephemeral context and exact review worktree cwd; (6) prompt is derived from durable repo authority and does not include parent-session transcript; (7) Codex nonzero/crash after claim preserves recoverable branch/worktree plus run evidence; (8) process zero without durable summary/receipt fails closed; (9) successful review completion is recognized after fetch and returns its durable Next Handoff to caller; (10) review finding -> correction handoff does not run correction inside reviewer context; (11) correction's paired re-review launches another fresh Codex process; (12) human-required and cycle-cap states stop; (13) no global queue hop; (14) `workstream.py finish` remains usable with Codex absent; (15) one harmless docs-only/synthetic end-to-end rehearsal proves claim -> fresh exec -> durable review result without touching production implementation.
- Validation: Add temporary-repository unit/integration coverage for preflight-before-claim, exact review claim, duplicate refusal, structured receipt/worktree verification, generated prompt isolation, mocked Codex pass/nonzero/crash, durable log location, durable-summary verification, correction/re-review routing and human/cycle stop. Run existing dispatcher/workstream/review-contract/queue-stranding suites. Add a fake `codex` executable fixture so CI needs no network/model access. Perform one bounded local live rehearsal only if it can use a harmless synthetic/docs-only review packet and leave no durable queue residue. Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: General persistent packet worker/scheduler; remote/Ultra review execution; provider abstraction; resource-budget scheduling; parallel review pools; automatic model choice.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: A first integration-test pass caught a summary-classification ordering bug; it was fixed and the test now covers zero-exit without a durable landed receipt. Godot validation initialized nine unrelated Operator `.import` sidecars in the worktree; they were classified as disposable generated metadata and removed.
- Root cause / contributing factors: The active/blocked result path needed the durable summary loaded before checking its blocker explanation; a fresh validation worktree also lacked the editor import cache.
- Prevention / pipeline improvement: The fake-Codex integration now exercises successful durable-state recognition and zero-exit fail-closed recovery. Existing worktree setup guidance should continue to expect Godot-generated import sidecars after validation.
- Tooling / docs drift discovered: none
- Follow-up: `review-codebase-audit-autonomous-review-runner`
- What worked: Existing dispatcher receipts remain the sole claim authority; a temporary repository test exercises exact worktree launch without touching production implementation.

## Independent Review

- Status: `findings`
- Review workstream: `review-codebase-audit-autonomous-review-runner`
- Reviewed on main: `97703d85ea7111abfa7b71884813df543a555813`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- R0-01: `blocking_defect`, domain `implementation`, disposition `correction` — The runner unconditionally supplies both `--sandbox workspace-write` and `--approve-for-me` in its Codex invocation. The installed Codex CLI rejects these mutually exclusive flags; the captured launch failed before the review agent started. This blocks acceptance of a usable fresh-review launch path and is reproduced by the actual launcher stderr. Remove the incompatible option or select a supported runtime combination, then exercise the real argument vector through a fake-Codex fixture that rejects mutually exclusive options and a bounded launch rehearsal.
- Focused validation: Runner tests 11/11 passed; dispatch 79/79, workstream 38/38, review-contract 5/5, queue/context 18/18 passed. `run_validation.py --changed --json` passed with zero changed files. `git diff --check` passed. `codex exec --help` explicitly documents automatic approval routing through the workspace-write sandbox; the captured run confirms the implementation currently passes the prohibited pair. The review could not exercise a successful real Codex review launch because the defect prevents process startup.
- Evidence limits: The prior runner launch record and stderr are durable under Git-common-dir run evidence `20261009T211138Z-1115421a9515`; no successful captured Codex launch exists. The fake-Codex tests currently accept and assert the incompatible pair, so they do not falsify this CLI contract.
- Detailed review summary: `REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER_CLAUDE_SUMMARY.md`
- Follow-up workstream: `codebase-audit-autonomous-review-runner-review-corrections-1`
- Reviewer independence: This review ran in the claimed fresh paired-review worktree, reconstructed from repository evidence only, and did not use implementation-session conversation content or edit reviewed implementation/runtime files.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Added a synchronous runner that fetches and checks the exact ready/auto review and complete archived target before claim; checks installed Codex flags before claim; claims only through `dispatch.py`; verifies the structured receipt and exact packet/worktree; launches `codex exec --ephemeral` in that worktree; streams redacted JSONL/stderr into Git-common-dir evidence; and verifies the landed archived review + summary or emits a recovery card. Fake-Codex tests cover preflight failure, human/non-review rejection, target checks, duplicate local runner refusal, receipt identity, fresh cwd/prompt isolation, secret redaction, nonzero exit, launch failure recovery, durable success, missing durable state, and Next Handoff return. Existing dispatch (79), workstream (38), review-contract (5), queue/context (18), and runner (11) unit tests passed. Changed-file validation passed 23/23 with complete coverage and no infrastructure errors; `git diff --check` passed. A bounded temporary-Git-repository rehearsal used only a synthetic review packet and left no repository queue residue.

## Handoff

- Next workstream: `review-codebase-audit-autonomous-review-runner`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d`
- Refresh reason: `none`
- Next action: After this implementation lands and archives complete, invoke `python3 custodian/tools/agent/paired_review_runner.py review-codebase-audit-autonomous-review-runner` from the synchronized coordination checkout. The child review must start fresh and inspect only durable repo evidence; it may use the runner itself because that code is already landed.
- Blockers or open questions: `bootstrap self-review must not fake independence by reviewing the runner implementation in the same implementation context`
