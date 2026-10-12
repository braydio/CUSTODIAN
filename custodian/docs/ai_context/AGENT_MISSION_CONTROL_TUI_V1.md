# CUSTODIAN Mission Control V1 — TUI-First Operations Plan

**Status:** approved planning direction; NOT IMPLEMENTED. **Date:** 2026-10-12.
**Repository authority:** existing `dispatch.py`, `task_packet_contract.py`, `workflow_control.py`, `workstream.py`, `paired_review_runner.py`, `run_trace.py`, and independently reviewed OR1/OR2 once landed.
**Authoring chat:** not-recorded; replace only with the exact current conversation URL when supplied. Do not substitute an older CUSTODIAN chat.
**Proposed umbrella identity:** `agent-mission-control-v1`. Implementation slices use individually claimable stable IDs below.

## Decision and intended experience

Build a **TUI-first, local-first operator console**, aesthetically closer to Lazygit, btop, and k9s than a tile-oriented web analytics dashboard. Python **Textual is the preferred candidate**, contingent on dependency/packaging and existing-tooling inspection. Ratatui is a fallback only if a demonstrated integration/performance requirement outweighs a new Rust boundary. Do not implement two UIs. Defer optional browser/remote/mobile presentation; reuse one structured snapshot/action protocol if ever added.

Launch target (proposed, not yet existing): `custodian mission` or a repository tool alias to `python3 custodian/tools/agent/mission_control.py`. The default screen should answer: (1) who is *verified* executing and on what; (2) what landed or changed since last acknowledgement; (3) what needs attention, why, and by whom; (4) what is really claimable next; (5) how much metered token activity is attributable to each workstream.

### Visual and interaction doctrine

- Density and hierarchy over cards: a continuous high-information terminal surface, restrained graphite/brass/teal palette, subtle focused row, compact status line, prominent command palette; avoid a generic boxed KPI grid or decorative operator-game HUD.
- Lazygit-inspired navigation: left narrow workstream/queue selector, wide evidence/activity/diff center, optional right inspector or attention sidebar; responsive collapse for 80x24 terminals; resizable panes only when justified; persistent bottom key-help/status bar.
- Distinguish active focus from notification severity using color *and* glyph/text. Support terminal dark/light, 16-color fallback, unicode/ascii fallback, keyboard first and mouse optional.
- Keys proposed: `j/k` navigate, `Enter` inspect, `/` search, `1..6` change screens, `a` attention, `t` telemetry, `c` claim preview, `r` recovery inspector, `?` help, `q` exit. No collision with typed command/dialog focus.
- Screens: **Now / Live / Workstreams / Queue / Tokens / Events**. Global fuzzy search, filters, sort, drilldown breadcrumbs, event timestamps, last refresh/source health, context-aware next action. Never fabricate percent-complete or an agent's current thought.
- Attention inbox has priority, actionable vs informational distinction, acknowledgment and dedup; examples: review findings, validation failure, ambiguous owner, recoverable exit, dependency unlock, missing acceptance evidence. Since-last-visit digest is cursor based, not re-announced every refresh.
- Workstream detail: family/root, implementation/review/correction lineage, exact packet state and dispatcher eligibility, actor/lease provenance, last verified events, trace, Git SHA, tests, tokens/cached/uncached/reasoning and confidence; show current state separately from historical windows.

## Authority and truth model

1. **Dispatch eligibility:** call existing dispatcher decision/audit; `Status: ready` or README index inclusion alone is never claimability.
2. **Canonical packet parsing:** use `task_packet_contract.py`; do not parse only header regexes as lifecycle authority. A packet is landed by verified Git/finish evidence, and accepted only by genuine paired independent receipt with zero blocking findings and correction-chain closure.
3. **Session activity:** local Codex rollout telemetry and `run_trace.py` produce metered observations, not OS liveness. OR1 verified supervised process/boot/PID/start identity is prerequisite for label `LIVE`; unsupervised/foreign/unreachable stay `UNKNOWN`. OR2 may later provide PARKED/recovery and exact owner lease. Mission Control cannot reclassify or free locks independently.
4. **Token accounting:** cumulative rollout counters de-duplicated by session/turn and source; cached input ⊂ input, reasoning ⊂ output. Separate complete versus incomplete/aborted; do not turn tokens into subscription dollars or equate throughput with productivity. Workstream attribution may be unclassified/ambiguous; report coverage, source and confidence; never silently inherit previous turn's workstream. Review/correction tokens aggregate to root *only* as an alternate grouping, never count twice.
5. **Dates and denominator:** compare current queue composition against current *outstanding managed entries*; historical completed/accepted metrics are separate and time-windowed. No mixing historical archived packet count with active outstanding share. Token window may only cover a subset of workstream lifecycle.
6. **Events:** derive evidence-linked `claimed`, `landed`, `review_passed`, `review_findings`, `correction_created`, `became_eligible`, `process_exited`, `parked`, `needs_human` from Git/packet/trace/OR1 evidence as available, with stable event IDs and idempotent restart/replay. Absence of logs is not proof of completion or idleness.
7. **Persistence/security:** local SQLite or equally durable lightweight store for snapshots, user acknowledge cursor and event deltas. Keep private local data out of Git; no raw prompts, credentials, environment secrets, agent transcripts or arbitrary file contents in UI exports. Offline read-only mode works without GitHub API access, but marks remote snapshots stale.

## Contextual action policy

The TUI starts **read-only by default**. Inspect Evidence/Diff/Dependencies/Tokens/Process/Trace are safe. Future action gateway must call existing workflow CLI/function boundaries with typed, allowlisted actions and request-specific expected workstream, packet blob, branch ref/SHA, claim/lease run token and snapshot revision, where applicable. Every mutation requires server-side fresh eligibility check, preview then user confirmation for impactful actions, race-safe execution, structured receipt and local audit event; never arbitrary shell from UI fields.

Potential gated controls: Claim Next (dispatcher-owned), Run Eligible Review (paired coordinator), Resume Same Workstream (workstream + OR2 owner proof), Rerun Focused Validation (approved recipe), Inspect/Apply Recovery (OR2 only after accepted review), Create/Refresh Correction proposal (no fake acceptance), Open Worktree/Packet and Acknowledge/Defer Notification. Controls are hidden/disabled with reason if evidence is missing. No dashboard-owned kill, lock theft, direct main writes, forced merges, bypassed receipts, review PASS synthesis, destructive workspace cleanup or implicit Codex launch. All proposed controls must specify explicit failure/cancellation cases.

## Suggested data contract

`snapshot --json` exposes schema version, `generated_at`, origin/main SHA and fetch age, collection health, independent authorities and their availability, lifecycle counts with denominators, workstreams (root/family/packet/lifecycle/owner/claims/dependencies/provenance), sessions (liveness vs token observation), aggregate metrics with attribution coverage and time window, deduplicated event list, attention items with evidence and recommended action, and eligible actions with server-side preflight provenance.

Read-only incremental collectors can poll local changed files every 5–15 s and remote Git roughly every 30–60 s, with cache/stale indicators and bounded CPU/IO. No reparse of full multi-GB rollout archive on every keypress; incremental offset/index strategy and archive rotation tests. Browser/UI must not trigger dispatch or broad validation through refresh.

## Planned bounded implementation slices (NOT YET AUTHORED OR CLAIMABLE)

Each slice requires its **own V2 implementation packet and post-land fresh-context paired review** in `custodian/docs/ai_context/task_packets/`, using canonical templates, current reviewed SHA, targeted preflight, managed index refresh only for promoted `ready/auto` packets, and normal closeout. Do not create placeholder ready packets without validation.

| Slice | Stable workstream ID | One coherent acceptance boundary | Dependency |
| --- | --- | --- | --- |
| MC1 | `agent-mission-control-data-model-v1` | Read-only versioned truthful JSON snapshot, packet/dispatcher adapter and fixture coverage; no UI | existing dispatcher/parser |
| MC2 | `agent-mission-control-telemetry-v1` | Reuse/refactor uploaded Codex usage tracker extraction; incremental/deduplicated metrics and confidence | reviewed MC1 |
| MC3 | `agent-mission-control-events-v1` | Evidence-linked state deltas, Git landings/receipt history, durable dedup/cursors | reviewed MC1 |
| MC4 | `agent-mission-control-tui-v1` | Textual full-screen six-view Lazygit-style UI, accessible keyboard navigation, responsive fallback and drilldown, read-only | reviewed MC2 + MC3 |
| MC5 | `agent-mission-control-supervisor-integration-v1` | Consume OR1/OR2 process/lease/recovery evidence fail-closed; do not duplicate supervision or unblock locks | accepted OR1, OR2 as needed |
| MC6 | `agent-mission-control-validation-v1` | Resilience/security/performance/telemetry integrity and docs/CLI integration, full vertical slice review | reviewed MC4 and MC5 |
| MC7 | `agent-mission-control-attention-center-v1` | Attention ranking, owner/actionability, acknowledgement, notification dedup and since-last-visit summary | reviewed MC3 + MC4 |
| MC8 | `agent-mission-control-action-gateway-v1` | Allowlisted guarded existing-workflow actions, preflight, preview/confirm, audit, race/security fixtures | reviewed MC4 + MC7; OR2 for recovery mutations |

Sequence is a design DAG, not a promise of automatic claimability. It may be narrowed after live-code inspection; avoid over-splitting coherently owned code. First usable milestone: MC1–MC4 yields read-only TUI, without waiting for OR2. Later guarded actions intentionally follow verified authority integration. Estimate: eight implementations plus eight paired reviews if no justified slice consolidation.

## Acceptance and anti-regression for entire program

- A new clone with no Codex logs and disconnected remote renders `unknown`/stale honestly, never invented active counts; `q` exits without mutation.
- A live-but-silent process is never marked orphan solely because a timestamp ages. Remote branch alone is not a live process.
- A review whose receipt has findings is never accepted or an upstream accepted prerequisite; final correction review can close a root only with actual valid receipt.
- Existing dispatcher determines eligibility identically with TUI closed/open; no new claims or repo mutations from polling, filtering or viewing.
- Restart, duplicate rollout archive, shared session UUID, truncated JSONL, missing reasoning counters and log rotation do not inflate token totals.
- Selected family drilldown reconciles exact implementation/review/rework buckets to a single token grand total.
- At 80x24, shortcuts, selection and essential attention information stay usable; keyboard/mouse behavior, no escape from dialog confirmations, accessible severity distinctions verified.
- Actions fail closed on stale SHA, lost lease, wrong owner, changed dependencies, disconnected origin, missing reviewer evidence; no arbitrary command interpolation.
- Plan documentation reconciles CURRENT_STATE, backlog, packet README and FILE_INDEX only as evidence requires. Do not mark implementation landed because plan exists.

## Planned command/interface and repository location

Proposed entrypoint: `custodian/tools/agent/mission_control.py`; possible package under `custodian/tools/agent/mission_control/` (collectors, adapters, models, metrics, events, storage, action gateway, Textual widgets and focused tests). Actual file layout is to be chosen during MC1/MC4 after inspecting live code, avoiding duplicate parsing and god files. No asset production or Asset Pipeline V2 asset family is required: this is developer tooling, not game art. Future visual mockup images, if commissioned, must be inventoried through Asset Pipeline V2 rather than silently dropped into runtime assets.

## Explicit non-goals now

This planning change writes no TUI, no action server, no scheduler, no automatic notification daemon, no executable task packets, no process/branch/lease changes, no plugin installation and no gameplay/UI runtime changes. Existing Usage Observatory remains usable until replaced via verified migration.

## Current drift watch

- `AGENT_AUTOMATION_BACKLOG.md` and `CURRENT_STATE.md` describe OR1/OR2 as not implemented; preserve that truth until evidence changes.
- `task_packet_index.py` is a bounded managed README generator; it is not claimability.
- The uploaded `codex_usage_tracker.py` supplies turn-level telemetry and a self-contained browser dashboard but uses its own packet-header inference; it must not become a second lifecycle authority.
- The new plan has no ready packets. Promote only after exact source/branch refresh, implementation/review pair authoring and validation.

**Next authoring step:** retrieve this conversation's exact URL, inspect current `origin/main`, then create MC1 and its paired review using `AGENT_TASK_PACKET_TEMPLATE.md` / `AGENT_REVIEW_PACKET_TEMPLATE.md`; establish snapshot schema before writing the remaining packets.
