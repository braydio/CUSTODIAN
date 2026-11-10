# REVIEW: CUSTODIAN Isolated Worker Proof V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-isolated-worker-proof-v1`
- Category: `platform-performance`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `agent-isolated-worker-proof-v1`
- Locks: `none`
- Review: `none`
- Review target workstream: `agent-isolated-worker-proof-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_ISOLATED_WORKER_PROOF_V1.md`
- Reviewed main: `81c39888de2231a424d9e64b9893212882f713c0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently establish that the landed test-only worker proof meets every implementation acceptance claim and does not overstate unavailable host or credential evidence.
- Reviewed implementation acceptance: Independently verify all eight acceptance claims in the archived implementation packet, including actual process credentials/cgroup, IPv4 and IPv6 loopback and CDP denial, external DNS/HTTPS, host credential and privileged-interface isolation, toolchain and verified Git LFS reads, model execution placement if claimed, disabled/non-recurring lifecycle, safe provisioning/removal, and redacted evidence. Any unavailable model or read-only LFS identity remains an unmet gate.
- Review evidence: Reuse the committed test suite, sanitized proof report, exact service properties, recorded tool/source versions, and implementation validation receipts. Independently inspect the landed launcher, unit, provisioning/removal behavior, and the recorded host evidence; re-run only the smallest safe probes needed to resolve a material evidence gap.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or evidence gap preventing confidence in a required isolation claim. Route non-blocking documentation friction or optional hardening to deferred work. Any credential, loopback, cgroup, publisher-authority, or false-PASS defect is blocking.
- Focused validation: Validate unit semantics and systemd property evidence; test fail-closed IPv4/IPv6 loopback and `127.0.0.1:9223`; verify DNS and tool access within the service; check account/groups, cgroup membership, host-home/Codex/GitHub/Docker-socket denial, sanitized environment, actual read-only LFS provenance, and service non-persistence. Use the implementation's exact commands and outputs; do not substitute configuration review for live host proof.
- Review focus: Challenge whether systemd IP filtering actually attaches to every worker process; whether environment/config/home isolation is complete; whether the worker can see owner credentials, Docker, user-session interfaces, connected MCP/browser/CDP access, or write-capable Git identity; whether DNS and toolchain access are tested through the actual service; whether read-only LFS and model-credential claims are evidence-backed; whether provision/removal scripts fail closed; whether no recurring/boot execution remains; whether any future publisher contract requires `SO_PEERCRED` plus explicit workstream/action/ref/current-generation checks; and whether the archived proof report leaks private data.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects and material acceptance-proof gaps create `agent-isolated-worker-proof-v1-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code. Do not mark the implementation accepted if any required host gate was not actually run or a credential identity is not proven read-only.
- Non-goals: Do not redesign the worker architecture, deploy it for production, change GitHub settings or credentials, implement the publisher/broker, or fix the reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Follow the current repository `AGENT_REVIEW_PACKET_TEMPLATE.md` procedure and reviewer-independence gate. Claim only after the implementation is complete and archived on `origin/main`; start a fresh context and reconstruct the proof from the archived packet, summary, live files, tests, and host evidence. Never use implementation-session reasoning as evidence.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df
- Refresh reason: `none`
- Next action: `After the independent review verdict, follow the implementation program's completion or correction lifecycle and report any unproven host gate to the authoring chat.`
- Blockers or open questions: `none`
