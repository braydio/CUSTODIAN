# Persistent Codex Task Administrator V1

**Status:** approved P0 architecture; production service NOT implemented.
**Workstream family:** `agent-persistent-task-administrator-v1`.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
**Inspected repository:** `braydio/CUSTODIAN` at `main@64c9f407744e6569b620ac0ad6ef3c9beedcd6fe` (2026-10-30). Refresh before work.
**Priority decision:** new top-priority P0 workflow-recovery campaign, superseding earlier P0 scheduling order at the next safe assignment boundary. Existing owners, claims, dependencies, review, test, visual, and preservation gates are NOT overridden.

## Goal and operating model

Run a low-overhead, persistent, user-enabled local administrator that (1) watches the actual task packet/dispatch queue; (2) ranks and resolves historical root blockers preventing safe landing; (3) delegates eligible implementation and independent review with a budget; (4) preserves original workstream identity across restarts; and (5) exposes a truthful status, attention, and control feed to Mission Control and the Quickshell taskbar.

Use one small host-local deterministic daemon (`systemd --user`) and one **Codex reasoning operator**, preferably through the locally supported Codex app-server protocol after a capability/version/auth probe. The daemon persists and does cheap event/poll reconciliation without LLM inference. Wake the operator only for new actionable ambiguity, root-cause diagnosis, competing safe remediation choices or escalations. A persistent service does NOT require an endlessly generating model turn; never assume a Codex session/history is itself task authority. Use versioned structured JSON operator proposals, bounded token/turn budget, redacted evidence and a separate action gateway; never accept model-generated arbitrary shell commands as authority.

### Reuse, do not duplicate, existing authorities

- `custodian/tools/agent/dispatch.py` and `task_packet_contract.py`: exact eligibility, dependency/lock checks, packet parsing and remote atomic claim. No second scheduler may declare claimable merely from Status, README, a remote branch or category.
- `workstream.py`, `workflow_control.py`, `persistent_checkout_sync.py`: canonical claim checkout, finishing, landing and guarded root synchronization.
- `session_supervisor.py` and `workstream_recovery.py`: OR1 local process identity and read-only inventory. A missing journal alone is not a veto; verify actual writer/process and preserve same-ID continuations. OR1 implementation code exists; accepted independent review must be independently established.
- OR2 `agent-orphan-recovery-fenced-parking-v1`: future exact-owner fenced parking/lease unlock. **No automatic park or lock release until OR2 is implemented, accepted and its actual authority available.**
- `paired_review_runner.py`, `review_outcome.py`, `review_receipt_delta.py`: review launch, genuine fresh-context disposition and correction-chain truth. Findings, human_required and archived complete are NOT fabricated PASS.
- `next_execution_boundary.py` and the proposed Longform LF1–LF4: scoped bounded worker execution, with actual implementation/acceptance checked at runtime. Do not independently reimplement a full longform runner.
- `queue_frontier.py`, `worktree_backlog_census.py`, blocker-inbox packet series, RunTrace: use recorded evidence and per-root diagnosis to reduce repeated investigations. No unsafe blanket cleanup.
- `AGENT_MISSION_CONTROL_TUI_V1.md`: future UI consumer, not a second execution owner.

## Priority and campaign precedence

The current packet grammar has `P0`–`P3` only; `dispatch.py claim-next` orders by numeric priority then packet path. Consequently P0 alone does **not** supersede earlier P0s. This program has explicit owner-approved **campaign precedence** for next safe launch. Initially use `dispatch.py claim <exact-workstream-id> --agent codex` rather than silently overriding global queue ordering. In the later accepted delegation slice, introduce a narrow campaign-scope selector that filters **dispatcher-confirmed eligible** choices; it must never override a failing dispatcher decision or add a synthetic P-1 priority. No retroactive edits to unrelated P0 packets. Existing live workers continue undisturbed. Exhausted campaign scope, budgets or an unresolved recovery gate stop further claims; no unrelated global queue hop.

Bootstrap packet `agent-persistent-task-administrator-v1` uses `Locks: agent-administration-bootstrap` and MUST NOT write or supersede existing `agent-workflow` authorities in that first slice. Mutating dispatcher, runner, lease or existing claimed work requires its later separately owned, reviewed slice.

## Recovery-first triage: what the operator may actually do

1. Read live `dispatch.py audit --json`, `workstream_recovery.py audit --json`, `git worktree list --porcelain`, optional current census, exact packet/review/RunTrace and branch/commit evidence. Rank root blockers by distinct downstream effects, severity and repairability; overlapping downstream counts are not additive.
2. Classify evidence as `INVALID_METADATA`, `REVIEW_PROVENANCE`, `REVIEW_FINDINGS`, `HOST_VALIDATION`, `POST_EXIT_RECOVERY`, `CLAIM_ONLY`, `LIVE_OWNER`, `DIRTY_OR_UNIQUE_WORK`, `ROOT_SYNC`, `MISSING_INPUT`, `HUMAN_VISUAL` or `UNKNOWN_PROTECT`. Historical counts are baselines, never live evidence.
3. Propose one typed action: `INSPECT`, `DIAGNOSE`, `DISPATCH`, `RESUME_ORIGINAL`, `RUN_INDEPENDENT_REVIEW`, `APPLY_APPROVED_REPAIR`, `VERIFY_CLOSEOUT`, `ESCALATE` or `HALT`. Include workstream, branch/ref and expected SHA, source run/receipt, evidence digest, chosen existing tool, risk, preconditions, budget and postcondition. The gateway rejects unknown verbs or missing proof.
4. Safe automatic repair **when currently authorized** can correct narrowly proven unclaimed packet/index/documentation drift using canonical tools, retry a verified idempotent closeout, resume an original clean same-ID claim with no competing writer under its lifecycle, or use an already accepted exact recovery procedure. Each mutation rechecks source identity, provenance and ownership against new reality under the existing lock/mutex, records before/after receipt, verifies landing, then re-audits descendants.
5. Dirty/untracked/unique local work, foreign/unknown owner, failure to prove a live process exited, unresolved review outcome, real failed validation, missing art/asset, human canon/visual decision or unaccepted OR2 remain protected. Never reset, clean, stash, delete/force-push, invent reviewer PASS, overrule owner authorization, or time-expire a quiet process. Emit one actionable intervention rather than retry endlessly.
6. If a confirmed defect is in the implementation, use an independently ownable scoped correction packet and fresh review; do not mutate already reviewed target code in a review workstream.
7. Track every incident through detected → diagnosed → planned → authorized → applied → verified / protected escalation, with fingerprints and replay-safe IDs. Avoid more agent reasoning on unchanged evidence.

## Codex operator and deterministic action gateway

- Preference: supported `codex app-server` over stdio with bounded initialization, thread/turn lifecycle, event streaming and explicit authentication/approval handling; perform local CLI/version capability probe and fall back to a separately budgeted supported `codex exec` invocation if app-server is unavailable. Do not assume a fixed Codex model, account entitlement, or unlimited usage. A failed/interrupted turn is not a completed decision.
- Operator has read-only evidence/context access and emits a strict response schema, no freeform executable commands. Gateway owns allowlisted mutations, expected branch/blob SHA and claim receipt, locks, policy decisions, idempotency, timeout/retry limit and durable audit. No permissive model sandbox or shell fallback to evade a denied command.
- No model call on unchanged periodic polling; invalidate diagnosis on real evidence change. Limit per-day turns/tokens, one Codex operator turn at a time, one initially active worker, review-first closeout before unrelated work, and one machine-wide expensive Godot validation at a time.
- User control: `observe`, `supervised-auto` and (later, after reviewed recovery/delegation) `continuous-auto`, plus `pause --drain`, `resume`, `status`, `queue`, `why` and `history`. Default to observe until the user explicitly enables unattended execution; persist approval scope and budget. Standing approval covers only nominated workstream family/queue scope and does not override mandatory per-case human decisions.
- Event/state store: private and fsync-safe beneath Git common dir, redacted hashes/receipts and monotonic IDs. Save no raw prompts, credentials, source files or token secrets in Git or UI. Crash/restart must reconcile remote and local facts before replaying any action.

## PR #101 category and Quickshell interface

PR #101 (`https://github.com/braydio/CUSTODIAN/pull/101`) defines `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`, `TASK_PACKET_CATEGORY_AUTHORING.md` and authoring validator `check_packet_categories.py`. It merged on 2026-10-30 at `main@38db9d88459c09ad0b9b5b7f24007913afebc0d2`. Its category registry and validator are now on main; verify the latest ref at implementation. Its canonical category for this program is `agent-ops`, inherited unchanged by its review/correction packets.

The administrator **consumes**, never forks, that registry. Categories remain purely editorial/display metadata, not a dispatch, priority, claim, or acceptance signal. Preserve the ordered nine category IDs/labels; missing category in legacy packets displays `Uncategorized` without guessing or bulk backfill.

Provide a local read-only machine-consumable `custodian.task_admin.snapshot.v1` protocol (JSON CLI first; optional UNIX socket after reviewed security pass) with: schema/revision/time/source health/origin-main SHA; canonical workstream/packet family; category ID and registry version; priority vs campaign order separately; dispatch eligibility and reasons; verified process evidence or UNKNOWN; implementation/review/correction phase; attention root cause; event IDs; short execution provenance; exact `Authoring chat` URL and known task/branch/review links. Never invent a URL. Quickshell Hybrid Shell v0.10 and Mission Control consume one shared snapshot; they must not independently parse lifecycle truth or fetch/mutate refs on render. Do not assume the separately installed local Quickshell source is in this repository. Install/update the consumer only after discovering its actual host path and repo provenance. The taskbar should show grouped queues, active/blocked/review attention, a one-click authoring-chat backlink and guarded controls through the administrator; no duplicate category configuration.

## Workstream sequence and separate review boundaries

| Campaign slice | Stable workstream | Work scope | Gate |
| --- | --- | --- | --- |
| A: P0 bootstrap | `agent-persistent-task-administrator-v1` | read-only, durable low-cost watcher, blocker-frontier evidence and bounded Codex reasoning operator, status JSON; service integration disabled by default | no agent-workflow mutation; fresh independent review |
| B: P0 delegation | `agent-task-administrator-delegation-v1` | allowlisted gateway, finite dispatcher-approved delegation and paired-review coordination, campaign precedence and budgets | reviewed A; verified accepted LF1/related runner authority; original locks |
| C: P0 remediation | `agent-task-administrator-recovery-v1` | safe approved exact-claim continuation, existing closeout/remediation procedures, incident closure and recovery telemetry | reviewed B; accepted OR1/OR2 for fenced parking; evidence-owner gates |
| D: display | `agent-task-administrator-quickshell-v1` | consume versioned snapshot in actual installed Quickshell / Mission Control; category and authoring-chat navigation, attention UI | PR #101 landed; snapshot contract validated; host source discovered |

Only slice A is packeted now; write the remaining packet pairs when their exact owners and prerequisites are verified. Slice D may advance independently as a read-only consumer after A and PR #101. Do not include gameplay, game art, Asset V2 changes, or any generated imagery in this program.

## Validation, acceptance and anti-regression

For slice A, prove read-only source inspection, stable frontier grouping, side-effect-free polling, stale/unreachable/contradictory sources marked UNKNOWN, no daemon duplicate, private ledger replay/restart, no model inference for no-change, Codex turn budget and response-schema rejection, safe failure if Codex app-server unsupported and no hidden dispatch/lock/review/checkout mutations. Installer/uninstaller must be reversible with explicit enable/disable, and host smoke must actually prove user service launch/restart before production service is called installed. Use temporary two-clone repositories for reference/provenance fixtures and measured current host audit only where executable. Subsequent B/C must prove two concurrent dispatchers never double-claim, no unbounded P0 hopping, old claims remain protected, original review findings never pass, dirty/unique/foreign work is preserved byte-for-byte, and repairs are verified at exact pinned main/receipt.

Before landing, run scoped tests, targeted authoring/category validator (once PR #101 lands), pairing/index checks, canonical `run_validation.py --changed --json` and independent review according to packet. Do not loosen the real validation gate to make the first run green. Compare active docs and CURRENT_STATE with live source; correct only relevant drift. No asset pipeline schema/files are required for this developer tooling.

**Publication complete (2026-10-30):** PR #101 merged; the slice-A implementation and review pair passed the automatic authoring handoff and became `ready/auto` at `main@4e3e88df4512f5bc8e4088d087b7bee3b974d3fe`. **Next action:** use the host-local dispatcher to verify an exact named claim for `agent-persistent-task-administrator-v1`, then implement in its claimed worktree and run genuine fresh post-land review. Never infer a running worker from publication. For an existing historical blocker, continue its original workstream and accepted recovery procedure rather than introducing a duplicate new claim.
