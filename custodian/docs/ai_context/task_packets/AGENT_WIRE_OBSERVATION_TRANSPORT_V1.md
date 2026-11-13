# CUSTODIAN WIRE PRIVATE OBSERVATION TRANSPORT V1

- Packet schema: custodian.task_packet.v2
- Workstream: agent-wire-observation-transport-v1
- Category: agent-ops
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P2
- Depends on: `agent-wire-observation-export-v1`
- Locks: none
- Kind: implementation
- Review: `none`
- Review stage: post-land
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: `Paired review retired 2026-11-12 by owner decision; focused validation is the acceptance gate.`
- Reviewed main: 38545e4c12b848861284d77c299790c046df6f62
- Authoring chat: not-recorded
- Visual review: none
- Goal: Make a validated, sanitized CUSTODIAN operational observation privately retrievable for the existing hourly WIRE editorial process, with deterministic bounded change records between consecutive valid observations.
- Completion boundary: Add an opt-in local producer that validates and privately uploads only custodian.wire.observation.v1 documents, publishes versioned immutable content plus a bounded atomic latest pointer in a dedicated Dropbox lane, verifies exact readback, and deduplicates unchanged evidence. Add a pure comparison API/CLI for two valid consecutive observations that emits bounded factual change and blocker records. Do not schedule the producer, change the ChatGPT task, or change public WIRE. Execution is mechanically gated on genuine PASS/acceptance of review-agent-wire-observation-export-v1.
- Current measured state: The sanitized local exporter and strict schema are landed at 38545e4c12b848861284d77c299790c046df6f62. custodian/tools/iteration/dropbox_transport.py resolves a configured rclone remote and runs rclone without exposing credential contents; current authorization does not establish a dedicated destination or ChatGPT read access. No telemetry transport or producer schedule currently exists in this scope.
- Evidence: custodian/tools/agent/wire_observation_export.py; custodian/tools/agent/schemas/wire_observation.v1.schema.json; custodian/tools/agent/test_wire_observation_export.py; custodian/tools/iteration/dropbox_transport.py; custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md; archived exporter packet and its genuine paired-review receipt after acceptance.
- Task-specific authority: AGENTS.md; custodian/AGENTS.md; the archived exporter packet; custodian/tools/iteration/dropbox_transport.py; the existing Dropbox/rclone configuration and any available connected Dropbox read capability. Transport code must not inspect or print credential contents.
- Work surface: New custodian/tools/iteration/wire_observation_transport.py, new custodian/tools/iteration/wire_observation_changes.py, focused synthetic/offline tests and narrowly registered validation entries if required. Reuse the existing schema and dropbox_transport.py; do not modify either shared transport behavior or the exporter absent a separately proven need and authorized correction.
- Publication inputs: `custodian/tools/agent/wire_observation_export.py`; `custodian/tools/agent/schemas/wire_observation.v1.schema.json`; `custodian/tools/agent/test_wire_observation_export.py`; `custodian/tools/iteration/dropbox_transport.py`; `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md`; `custodian/tools/validation/validation_manifest.json`.
- Change: Add a separately invoked producer that accepts a bounded local JSON file, validates the exact observation schema and digest before any network operation, rejects all other schemas/extra fields/oversized documents, and uploads only that sanitized document. Use existing rclone configuration through dropbox_transport.py and a dedicated private location /CUSTODIAN/wire/operational_observations/v1/. Publish a content-addressed/versioned observation and a bounded atomic latest pointer; verify remote bytes, size, schema, and SHA-256 readback before reporting success. Never upload raw task-administrator snapshots, create public links, touch the artwork/implementation-handoff lanes, change shared visual-review transport, or disclose credentials. Repeated identical evidence must avoid duplicate versioned objects and preserve the existing valid pointer. Any schema, digest, authentication, connection, upload, or readback failure must return a safe failure and leave no pointer to an unverified document. The producer must not run task-administrator collection, dispatcher/recovery audits, Git fetches, or services.

  Add a pure consecutive-observation comparison that accepts only two valid schema-conforming documents with matching source identity and valid timestamps/digests. It emits a deterministic, size-bounded JSON change record with explicit before/after evidence times and revisions. Keep packet counts distinct from unique workstream counts. Distinguish packet creation from actual workstream progress; ready from dispatcher claim eligibility; claimed from executing; landed from independently accepted; and archived from clean teardown. Treat historical evidence as historical unless the new observation freshly establishes it. Record dependency and review-gate changes only from documented dependency IDs and explicit dispatcher/review evidence. Identify blockers using actual dispatcher classifications and documented dependencies only; do not infer priority, downstream impact, execution, review acceptance, or cleanup. Unavailable or conflicting evidence yields explicit unknown/coverage limitations, never invented zeroes.
- Preserve: Exporter schema and output contract; dispatcher, task-administrator, recovery, claims, locks and review outcomes; Dropbox credential configuration; visual-review and implementation-handoff transport; public WIRE feed/publisher; existing hourly automation; Render; Quickshell; all live service/scheduling state.
- Non-goals: Uploading raw snapshots or logs; public GitHub telemetry or public Dropbox links; modifications to existing hourly ChatGPT automation or public WIRE; enabling a timer/service; installing tools; broad/new credentials; running a monitoring daemon; changing dispatcher or review authority.
- Acceptance:
  - Synthetic offline tests prove strict schema allowlisting, digest/freshness preservation, no raw snapshot accepted or uploaded, credential redaction, request/size bounds, and no dispatcher/task-administrator/Git invocation.
  - Mocked rclone tests prove exact byte/size/schema/SHA readback, content deduplication, atomic latest-pointer behavior, and fail-closed authentication/connectivity/upload/readback failures without reporting false success or replacing a good pointer.
  - A bounded documented manual integration probe verifies the exact private Dropbox object using the existing connection without creating a public link. Verify whether the connected ChatGPT Dropbox source can retrieve that exact location/document; if this cannot be established from available approved access, state the limitation and leave scheduled activation unavailable.
  - Consecutive-observation fixtures prove all distinctions and transitions in Change, dependency/review gate transitions, stable deterministic output, explicit unknowns, and bounded record size. No priority score or downstream-impact field exists.
  - Real local producer can upload only an already validated synthetic sanitized document to the dedicated private lane, read it back byte-for-byte, and safely deduplicate it. Do not upload live host telemetry in this task.
  - python3 custodian/tools/agent/check_packet_categories.py <changed packet paths> and targeted authoring validation pass; focused tests, schema validation, git diff --check, and complete canonical changed-file validation pass.
  - Independent paired review accepts the landed implementation before any schedule or hourly-consumer change is considered.
- Validation:
  - python3 -m unittest <new transport and comparison test modules> -v using mocked rclone for offline failure cases.
  - Run focused real transport integration only with existing approved rclone credentials and the exact dedicated private path; upload only synthetic sanitized data and verify remote bytes/size/digest/schema/readback and deletion/retention behavior without public links.
  - Validate synthetic observation fixtures with the canonical wire_observation.v1.schema.json; test malformed schema, bad digest, stale/future timestamp, oversized input, and forbidden fields.
  - Run focused before/after fixtures for creation vs progress, readiness vs eligibility, claim vs execution, landing vs acceptance, archive vs teardown, historical vs fresh evidence, packet vs workstream counts, and dependency/review transitions.
  - Verify the producer path contains no task-admin collector, dispatcher/recovery audit, Git fetch, or service scheduling invocation.
  - python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json with complete applicable changed-file coverage; do not launch broad sweeps.
- Task overrides: none
- Deferred: Any producer timer/user-service installation; changes to the hourly ChatGPT WIRE task, consumer prompt, public WIRE feed/publisher, or source authority; live operational telemetry publication before transport acceptance and separate integration authorization.

## Handoff

- Next workstream: review-agent-wire-observation-transport-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: After the exporter receives genuine independent acceptance, recheck the exact accepted schema, helper APIs, Dropbox consumer access, and current validation paths before transport implementation.
- Next action: After review-agent-wire-observation-export-v1 is genuinely passed and archived, claim this packet only if the dispatcher confirms eligibility and all destination/access prerequisites are satisfied.
- Blockers or open questions: Dedicated Dropbox destination and ChatGPT scheduled-task read access must be verified using existing approved credentials/capabilities; no public URL fallback is permitted.
