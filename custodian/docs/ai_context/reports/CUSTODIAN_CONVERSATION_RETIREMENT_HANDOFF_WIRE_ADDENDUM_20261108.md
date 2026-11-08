# CUSTODIAN | Conversation Retirement & Engineering Handoff
## Section 9. CUSTODIAN WIRE Private Observation Pilot

- **Milestone:** 2026-11-08
- **Status:** One-shot private publication and private reader readback demonstrated; scheduled-consumer ingestion, recurring production, and independent review acceptance remain unverified.
- **Scope:** Historical handoff addendum to the existing conversation-retirement handoff (Sections 1–8). This document does **not** replace that handoff, alter workstream state, or constitute a review receipt.
- **WIRE authoring/continuation conversation:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aef43f4-321c-83ea-b0b7-0457218d9cef

### Executive-summary addition: fourth engineering effort

**CUSTODIAN WIRE:** Private pilot publication and connected Dropbox readback demonstrated on November 8, 2026; automated hourly consumer intake, recurring producer operation, and the separate exporter/transport review gates remain pending. Keep WIRE's review and transport workstream identities distinct from the general paired-review provenance recovery campaign and from Operator/gameplay work.

### Verified and reported milestones

The host operator reported executing the existing `custodian/tools/iteration/wire_pilot.py` tool on the Arch development host:

1. `doctor` returned Ready with source-health checks passing.
2. `once` published a sanitized observation through private Dropbox.
3. `verify` reported successful private readback and verification.
4. The connected ChatGPT Dropbox reader subsequently retrieved the private `latest.json` pointer and its referenced observation document. Pointer fields, observation schema, source revision, evidence digest, observed timestamp, and recorded counts matched. This **does not by itself establish a fresh independent cryptographic hash of the raw Dropbox download bytes**: a connected text extraction/readback is not equivalent to authenticated original-byte access.

These are distinct evidence levels. The one-shot producer and private reader path are demonstrated. The hourly consumer's own intake/validation and independent engineering acceptance are **not** demonstrated by these results.

### Historical publication identity

| Field | Recorded value |
| --- | --- |
| Source revision | `ee2d0c829b3d5860f5d20a6be46e3d94693fe518` |
| Observation time (UTC) | `2026-11-08T13:40:47Z` |
| Pointer publication time (UTC) | `2026-11-08T13:40:52Z` |
| Content SHA-256 declared by pointer | `f6da23bedd4b0cf4b1a413f72bce773d83dfc392f68bd972417d7d7be3b2ecfc` |
| Declared content bytes | `252944` |
| Exporter evidence SHA-256 | `28f653801ff12d05b455b05d815d214017720cfd25597dac441d73e807425bb8` |
| Pointer schema | `custodian.wire.pilot.latest.v1` |
| Observation schema | `custodian.wire.observation.v1` |

The private lane is `/CUSTODIAN/wire/operational_observations/v1/`. The pointer is `latest.json`; its immutable content is addressed under `observations/<content_sha256>.json`. These paths identify a **private** Dropbox location, not a public WIRE artifact or a live service. Do not copy raw observation material, private host metadata, or credentials into `custodian-wire` or any public feed.

### Historical operational snapshot: November 8, 13:40:47 UTC

| Metric | Observed/report-recorded value |
| --- | ---: |
| Raw active packet records | 482 |
| Managed packet records | 421 |
| Distinct workstreams | 421 |
| Detailed packet records | 420 |
| Aggregate-only packet records | 62 |
| Unidentified packet records | 61 |
| Claimable automatic packets | 7 |
| Claimed packet records | 84 |

The observation declares `raw_dispatch_inventory=complete` and `active_inventory=partial`. Its source-health fields report dispatch/recovery/snapshot `ok` and origin/main `current`; however, `dispatcher_audit_generated_utc` is null. The raw inventory's own capture age therefore is not independently established. Counts are historical as-of measurements, not continuously refreshed telemetry. `claimed` does not prove a host process is running; neither a completed archive nor a Git branch disappearance proves canonical teardown. Do not interpret unreported states as zero.

### Existing watcher and remaining acceptance

- Hourly automation: **CUSTODIAN Project Watch** (`6ae469bd15e88191825a1ee14b478f60`). Preserve its schedule.
- The last watcher execution examined in the handoff was reportedly **8:20 a.m. EST**, before the **8:40 a.m. EST** pilot publication. Thus **scheduled automated consumer ingestion of this observation has not been proven**.
- The pilot content validator defaults to **600 seconds** maximum observation age (`wire_pilot.py`); source inputs use a separate **180-second** freshness limit. A correct historical pointer is not necessarily fresh. Validate fresh observation time, source timestamps, byte length, exact-content SHA-256, exporter evidence digest, schema allowlist, source revision, coverage and denominator consistency before permitting private operational counts into any public aggregate.
- The standing limited pilot authorization permits **opt-in private observation intake without dispatcher claims, packet locks, or prior independent PASS**. That exception is **not** an acceptance receipt and does not authorize host, packet, review or automation modifications.
- Independent review debts remain separate: `review-agent-wire-observation-export-v1` and `review-agent-wire-pilot-exporter-reconciliation-v1`. Preserve any original claimed reviews and their evidence. The older `agent-wire-observation-transport-v1` must be reconciled against the functioning opt-in pilot before adding another transport or producer.
- A successful `once` publication does **not** imply a persistent producer, trusted producer identity, atomic production-grade delivery, real-time liveness, reviewer acceptance, or verified teardown.

### Next actions, in dependency order

1. **WIRE consumer owner:** Inspect a subsequent hourly run's own evidence for successful fetch, exact-byte and schema validation, freshness and bounded coverage of an observation that was still fresh **at the actual time of intake**. Do not retroactively label a stale observation ingested.
2. **Existing review owners:** Complete the preserved independent review workstreams and record genuine acceptance or explicit findings without recreating claims or rewriting historical review evidence.
3. **Transport owner:** Reconcile the earlier transport implementation packet against the working private pilot to prevent duplicate infrastructure or conflicting ownership.
4. **Host/operator, after separate authorization:** Decide whether/how to schedule a regular private producer and retain fail-closed freshness, readback and privacy enforcement. Do not start a service as part of monitoring.
5. **WIRE editor:** Publish only aggregated, sanitized, evidence-backed operational information; when an observation is stale, unverifiable or partially scoped, retain the existing public dated snapshot and report unknown instead of inventing live or zero counts.

### Relevant repository source and review references

- Exporter and pilot source: [`custodian/tools/iteration/wire_pilot.py`](../../../tools/iteration/wire_pilot.py), [`custodian/tools/agent/wire_observation_export.py`](../../../tools/agent/wire_observation_export.py), [strict schema](../../../tools/agent/schemas/wire_observation.v1.schema.json).
- [Observation exporter independent review](../task_packets/REVIEW_AGENT_WIRE_OBSERVATION_EXPORT_V1.md).
- [Pilot exporter reconciliation independent review](../task_packets/REVIEW_AGENT_WIRE_PILOT_EXPORTER_RECONCILIATION_V1.md).
- [Earlier private observation transport packet](../task_packets/AGENT_WIRE_OBSERVATION_TRANSPORT_V1.md).

**Handoff boundary:** Preserve this as a distinct WIRE milestone alongside the original recovery, retirement, and Operator handoff. No workstream is declared complete by this documentation publication; no automation schedule, pilot service, dispatcher record, claim, review or WIRE feed is modified.
