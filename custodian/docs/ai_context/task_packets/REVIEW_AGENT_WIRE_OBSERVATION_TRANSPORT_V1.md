# REVIEW: CUSTODIAN WIRE PRIVATE OBSERVATION TRANSPORT V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-wire-observation-transport-v1
- Category: agent-ops
- Kind: review
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P2
- Depends on: agent-wire-observation-transport-v1
- Locks: none
- Review: none
- Review target workstream: agent-wire-observation-transport-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_OBSERVATION_TRANSPORT_V1.md
- Reviewed main: 38545e4c12b848861284d77c299790c046df6f62
- Authoring chat: not-recorded
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify that the landed private telemetry transport and observation comparison satisfy their packet acceptance without exposing host-private data or changing canonical CUSTODIAN state.
- Reviewed implementation acceptance: Enforce observation schema/digest before upload; upload only sanitized observations to a dedicated private Dropbox lane; atomically publish bounded versioned content and pointer; verify exact remote readback; deduplicate unchanged evidence; fail closed; never trigger another dispatcher audit; deterministically compare valid consecutive observations with truthful gate/progress distinctions and bounded factual blockers.
- Review evidence: Archived implementation packet and closing summary, exact landed diff, focused synthetic/offline and mocked-rclone test results, canonical validation report, exact synthetic private Dropbox readback evidence if a real integration probe was possible, and exact connected ChatGPT Dropbox retrieval evidence or an explicit access limitation.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap preventing confidence in required acceptance. Route optional improvements to deferred/next slice; unresolved access/authentication boundary is a blocker, not assumed success.
- Focused validation: Independently run the new transport and comparison tests, schema/digest/redaction adversarial cases, dedup/readback/failure cases, and changed-file validation as needed. Inspect the exact host transport probe without exposing credentials or making a public link. Verify no schedule, public feed, dispatcher, task-admin, recovery, or shared visual-review transport changed.
- Review focus: Fail-closed schema validation, no raw-snapshot path, no credential/private-host leakage, exact immutable content and pointer publication ordering, good-pointer preservation on failure, unchanged-evidence deduplication, size and time bounds, evidence freshness and source identity, truthful distinctions in change/bottleneck records, consumer retrieval claim, and strict non-mutation/no-schedule behavior.
- Acceptance: Produce findings-first independent review of live main. Record a passed receipt or concrete findings with stable cycle-scoped IDs (R0-NN), class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects or material proof gaps create agent-wire-observation-transport-v1-review-corrections-1 and its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not create/enable a schedule, modify the hourly ChatGPT task or public WIRE, publish public telemetry, redesign dispatcher/review authority, or fix the implementation in the review workstream.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Claim only after the transport implementation is landed, complete, and archived; start a fresh reviewer context.
2. Read root and local AGENTS instructions, this packet, the archived implementation packet, summary, exporter/schema, transport/comparison sources, focused tests, and validation evidence.
3. Reconstruct transport behavior from code and synthetic tests; treat implementation summaries and producer output as claims to verify.
4. Independently verify exact schema and digest checks, size bounds, private destination separation, upload/readback bytes and metadata, atomic pointer behavior, deduplication, and safe failure. Confirm no credential disclosure, raw snapshot acceptance, public link, or extra audit.
5. Verify all comparison distinctions and dependency/review gate transitions from synthetic evidence; reject invented execution, acceptance, teardown, priority, downstream impact, or zero counts.
6. Verify ChatGPT connection retrieval only through an existing approved private connection. If it cannot be established, record an evidence gap/blocker; do not substitute a public URL or claim scheduled-task access.
7. Inspect changed paths and lifecycle evidence to confirm the implementation is observational, has not changed canonical project state, and has not installed/enabled a service or modified the public feed/hourly task.
8. Record findings first. Use correction packets only for confirmed blockers; otherwise record passed or findings and bounded dispositions.
9. Complete/archive this review packet through the canonical review lifecycle. Do not change the reviewed implementation.
