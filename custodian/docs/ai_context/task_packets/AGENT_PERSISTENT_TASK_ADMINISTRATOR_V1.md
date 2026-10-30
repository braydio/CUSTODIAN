# AGENT PERSISTENT TASK ADMINISTRATOR V1 — P0 BOOTSTRAP

- Packet schema: custodian.task_packet.v2
- Workstream: agent-persistent-task-administrator-v1
- Category: agent-ops
- Status: draft
- Dispatch: manual
- Priority: P0
- Depends on: none
- Locks: agent-administration-bootstrap
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-persistent-task-administrator-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: Persistent process, untrusted model decisions and workflow recovery evidence require independent review before any future mutation permission.
- Reviewed main: 64c9f407744e6569b620ac0ad6ef3c9beedcd6fe
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Visual review: none
- Goal: Ship the first genuinely usable P0, host-local persistent task administrator with read-only recovery-frontier inventory, durable event/history store, low-token Codex operator and versioned status feed for PR #101 Quickshell grouping, without gaining execution/claim/lock authority.
- Completion boundary: One idempotent observer/service with no model calls on unchanged polls, bounded Codex app-server (or supported exec fallback) diagnostic turns, durable evidence-linked incident decisions, guarded typed PROPOSAL-only operator output, read-only JSON CLI, isolated service install/uninstall and focused host smoke; service must remain disabled until explicitly enabled.
- Current measured state: Existing dispatch.py audit --json, queue_frontier.py, workstream_recovery.py, session_supervisor.py and worktree_backlog_census.py provide separate evidence; no persistent reasoning administrator is installed by this packet. Historical 2026-10-17 census is stale baseline, not a live queue. PR #101 category taxonomy is open at this authoring time and must be merged and checked before readiness promotion. OR1 code exists but its review is not established as passed; OR2 and LF1 are not proved accepted/installed.
- Evidence: design/04_architecture/AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md; PR https://github.com/braydio/CUSTODIAN/pull/101; custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; current agent tooling and lifecycle.
- Task-specific authority: AGENTS.md, custodian/AGENTS.md, design/04_architecture/AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md, custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md, and existing dispatcher, task packet contract, queue frontier, OR1 observer, RunTrace and review outcome owners.
- Work surface: New narrowly scoped custodian/tools/agent/task_administrator.py, custodian/tools/agent/task_admin/ modules and tests, and source-controlled disabled-by-default systemd user unit/installer; relevant validation manifest ownership and concise current-state documentation only.
- Publication inputs: design/04_architecture/AGENT_PERSISTENT_TASK_ADMINISTRATOR_V1.md, custodian/tools/agent/dispatch.py, custodian/tools/agent/queue_frontier.py, custodian/tools/agent/workstream_recovery.py, custodian/tools/agent/session_supervisor.py, custodian/tools/agent/task_packet_contract.py, custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md, custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json, custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md
- Change: Reuse immutable dispatcher/recovery snapshots in one read-only normalized adapter; group blocker-root causes and link protected originals; implement private fsynced event/state journal and evidence digest/dedup; add opt-in systemd user observer, read-only status/queue/why/history/snapshot --json commands, and Codex app-server bounded DIAGNOSE/ESCALATE operator with strict structured output that cannot execute mutations. Surface PR #101 category IDs, unknown legacy categories, exact authoring chat and lifecycle evidence to the new Quickshell read-only interface. Add test harness for unsupported Codex version/auth, no-action polls, restart replay, source staleness, duplicate supervisors and malicious model outputs. No arbitrary shell or worker launches.
- Preserve: Dispatch selection and claim order, existing P0 packets, all remote Git refs, current root and all worktree bytes, review independence, unknown/live owner locks, historical private evidence, human visual/canon decisions, Asset Pipeline V2; no repo status mutation via observation.
- Non-goals: No automatic dispatch/claim, resume, park, lock release, review PASS, closeout apply, cleanup, Godot/art changes, separate category manifest, browser service, or Quickshell local source mutation in slice A. B/C own authorized execution and remediation.
- Acceptance: A read-only host run and restart prove zero Git/packet/worktree/process mutation, correct dispatcher-sourced queue outcomes and distinct review/acceptance fields, idempotent deduped incident ledger, model called only on evidence changes with finite limits, strict rejected unapproved action, PR #101 category and Uncategorized fallback visible in JSON, no invented liveness, configured user service off by default, guarded startup/shutdown, and exact original authoring-chat links.
- Validation: New synthetic temp-Git and process tests for adapter/provenance/duplicate PID/restart/corruption, zero changes on poll, empty disconnected queue, untrusted Codex response, token budget exhaustion and schema checks; targeted existing test_dispatch, test_task_packet_contract, test_session_supervisor, test_next_execution_boundary, test_queue_frontier when present. Run python3 custodian/tools/agent/check_packet_categories.py on both packet files after PR #101 lands; validate_task_packet_authoring.py both; check_ai_context.py --json; validate_review_pairing.py; task_packet_index.py; canonical run_validation.py --changed --base origin/main --json; git diff --check; host service status/restart smoke when available.
- Task overrides: none
- Deferred: P0 slice B agent-task-administrator-delegation-v1 and P0 slice C agent-task-administrator-recovery-v1 with separately reviewed authority, plus read-only Quickshell consumer integration under agent-task-administrator-quickshell-v1 after local source discovery.

## Priority and publication gate

This is the owner's **first P0 campaign** ahead of prior P0 scheduling at the next safe assignment boundary. Current dispatcher only orders P0 ties by path, so select this packet by its exact workstream ID after promotion/eligibility verification; do not edit other P0s, bypass active claims or implement new priority levels. The isolated bootstrap must not use agent-workflow lock to jump into contested runtime authority or affect extant workers.

The PR #101 category registry and validator must land before promoting this pair, then run targeted authoring and category validation and publish both together. Current draft/manual is intentional pending this exact publication prerequisite. The paired independent review may start only after genuine implementation landing, not merely after this planning publication.

## Handoff

- Next workstream: review-agent-persistent-task-administrator-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Refresh reason: none
- Next action: Verify PR #101 is green and landed; promote this same packet/review pair together and claim by exact ID after the live dispatcher says eligible.
- Blockers or open questions: PR #101 still unmerged at authoring; true host run and service verification need the actual Arch machine.
