# CUSTODIAN · Agent Pipeline · Feedback-Driven Hardening V1

**Program identity:** `agent-pipeline-feedback-improvements-v1`  
**Status:** Packet-series publication; no implementation or independent review claimed complete.  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1  
**Baseline examined:** `braydio/CUSTODIAN` at `6ff9c52b3315c9f3afc2a7ce42576b564df26673`, refreshed for publication at `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`.

## 1. Existing authorities and uncovered gap

Root `AGENTS.md` requires `custodian.task_feedback.v1` in each closing summary's `## Process Feedback` with `Outcome`, `Friction severity`, `What went wrong`, `Root cause / contributing factors`, `Prevention / pipeline improvement`, `Tooling / docs drift discovered`, `Follow-up`, and optional `What worked`. The V2 task packet mirrors that information as `## Execution Feedback`; the separate `## Next Handoff` governs continuation.

`custodian/tools/agent/check_ai_context.py` validates active complete V2 receipt schema but intentionally does not recertify archived history. It does not build a historical feedback inventory, deduplicate mirrors, or trace whether an `unowned` follow-up was fixed. The audited main did not expose a source-linked central process-feedback ledger. This is the primary new function: convert collected observations to accountable, reproducible, prioritizable information.

Already implemented and authoritative: `task_packet_contract.py`, `dispatch.py`, `workstream.py`, `task_packet_index.py`, `check_ai_context.py`, `validate_review_pairing.py`, `paired_review_runner.py`, `godot_import_preflight.py`, `run_validation.py`, `known_headless_warnings.json`, Godot writer locking, and two-speed CI. Never add parallel versions of these systems.

## 2. Feedback-based evidence and scope

This is a targeted qualitative sample of roughly 30 historical and recent root closing summaries plus the preserved Stealth Perception and H5 recovery evidence, **not a frequency census**. PF1 must supply exact counts and denominators.

| Issue family | Supporting examples | Cost | Boundary |
| --- | --- | --- | --- |
| Unrelated baseline failures in changed sweeps | Stealth: 56 passed, 3 baseline-red Operator checks, 16 skipped. H5: 38 passed, 2 failed, 1 timeout, 1 skipped. OPERATOR_ACTION_ARBITRATION also hit unrelated packet metadata drift. | Implemented features remain unlanded; repeated expensive sweeps | Fail closed; attribution is never a waiver |
| Godot import and false-green smokes | VAULTWING_IMPORT_METADATA_REPAIR fixed 15 tracked `.png.import` entries with `valid=false`. A BRIDGED_FALLS review saw PASS alongside resource/parser errors. | Misleading proof, costly import reruns, source-sidecar churn | Existing preflight/runner/Asset V2; narrow test-owned expected errors |
| Lifecycle and queue/index drift | H5/Stealth, index conflicts, NPA review receipt correction, stale validation IDs | Late finish failure, worktree recovery friction | Existing packet parser, bounded README index and finish remain authoritative |
| Restricted reviewer shared-Git writes | NPA-7 review had `.git/FETCH_HEAD`/trace access failures; H4 review observed LFS temp restrictions | Independent review can gather evidence but not close its lifecycle | Coordinator-only authorized writes; reviewer remains restricted |
| Long validation runtime | Game scene startup check is 360-second manifest budget with prior successful runs about 164–237 seconds; H5 timed out. Tier-gated skipped tests obscure downstream status. | Costly redundant sweeps and difficult attribution | Instrument existing runner/CI rather than fork tests |
| Feedback follow-through | `manual-follow-up`, `fixed-in-scope`, workstream-name follow-ups throughout summaries | Recurring work rediscovered, uncertain fix status | Read-only source-linked ledger before prioritization |

## 3. Execution plan and canonical packet paths

Each implementation has a corresponding fresh-context paired review, normal `workstream.py finish` and completion/feedback receipts. A review is ineligible until its implementation is complete and archived.

| Slice | Workstream | Active implementation packet basename | Queue status |
| --- | --- | --- | --- |
| PF1: Process Feedback Ledger | `agent-process-feedback-ledger-v1` | `AGENT_PROCESS_FEEDBACK_LEDGER_V1.md` | `ready/auto`, P0 |
| PF2: Failure Attribution | `agent-validation-failure-attribution-v1` | `AGENT_VALIDATION_FAILURE_ATTRIBUTION_V1.md` | `ready/auto`, P1 |
| PF3: Godot Truth Gate | `agent-godot-validation-truth-gate-v1` | `AGENT_GODOT_VALIDATION_TRUTH_GATE_V1.md` | `ready/auto`, P1 |
| PF4: Closeout Preflight | `agent-workstream-closeout-preflight-v1` | `AGENT_WORKSTREAM_CLOSEOUT_PREFLIGHT_V1.md` | `ready/auto`, P1 |
| PF5: Review Coordinator Boundary | `agent-paired-review-coordinator-boundary-v1` | `AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1.md` | `ready/auto`, P0 (2026-10-11 execution-hardening refresh) |

All implementation packets live at `custodian/docs/ai_context/task_packets/`. Each paired reviewer has the same basename with `REVIEW_` prefixed and the exact `review-<workstream-id>` identity. All ten packet headers include the exact authoring chat above. The managed Ready/Auto index originally included PF1–PF4; after the 2026-10-11 execution-hardening refresh it also includes the promoted PF5 pair.

PF1–PF4 have since been implemented and archived with their independent review/correction lifecycles. The 2026-10-11 audit established the current runner's deterministic double-prefixed Git summary lookup defect. User authorization released PF5 for targeted implementation; the shared-Git-denial fixture remains a fail-closed acceptance requirement, not a permission to widen reviewer access.

### PF1: Feedback ledger

Create `custodian/tools/agent/process_feedback.py` plus targeted tests. Read only committed root `*_CLAUDE_SUMMARY.md` and active/archived V2 packet receipts. Parse actual Markdown headings (not fenced examples) and backticked field values; keep original source path and exact workstream identity. Deduplicate a mirrored summary/packet receipt only with positive identity evidence, not fuzzy names. Unknown/legacy/missing values remain explicitly unknown. `fixed-in-scope` is author-reported, not independently verified. Report follow-up ownership and unresolved medium/high friction in stable JSON/Markdown. Run against the real corpus and produce the true denominator.

### PF2: Failure attribution

Create `custodian/tools/validation/validation_failure_triage.py` consuming canonical runner JSON and `validation_manifest.json`. Report every fail/timeout/infrastructure error/skip with ID, owner, skip blocker, duration/timeout, fatal diagnostics, explicit baseline status and exact immutable baseline SHA. `baseline-red` does **not** mean waived or unrelated, `baseline-unavailable` stays unknown, candidate-only-red remains suspect. Optional baseline recheck must use a disposable, imported and writer-locked checkout. No new validation-runner authority.

### PF3: Godot import/resource truth

Extend `godot_import_preflight.py`, `run_validation.py` and narrowly scoped warning rules only where needed. Pre-import detect LFS pointers and referenced invalid tracked `.png.import` metadata; after import prove representative runtime resource/scene loads through registered checks. Fatal type/parser/resource diagnostics must reject a printed PASS. Expected rollback errors are exact and test-owned, proved by near-miss negatives. No network fetch, bulk sidecar auto-repair, or asset authority replacement.

### PF4: Read-only finish preview

Extend `custodian/tools/agent/workstream.py` with a read-only `preflight` that shares existing final gates for archived status, literal Completion Truth, summary backlinks, managed index, untracked files, review receipt and validation reports. Report SHA/branch drift and unknown post-sync predicates, but never mutate files, refs, traces or worktree identity. The preview does not replace or weaken `workstream.py finish`.

### PF5: Reviewer/coordinator completion truth (refreshed 2026-10-11)

PF5 is promoted to `ready/auto` in the execution-hardening addendum. First reproduce and repair the verified `origin/main:origin/main:<summary>` double-prefix bug and the broad-summary false-completion risk. Also reproduce shared-Git `FETCH_HEAD`/trace denial on the latest runner before any sandbox/authorization mutation; coordinator alone performs verified writes. Reviewer remains fresh and restricted. See `AGENT_CODEX_EXECUTION_PIPELINE_HARDENING_V1.md` and the refreshed PF5 packet for current scope.

## 4. Quantitative outcomes and validation economy

PF1 must baseline: total/parseable source receipts, absent/malformed receipts, outcome/friction breakdown, unowned medium/high follow-ups, repeated failure families, skipped test counts, slow startup tests, PASS-with-fatal diagnostics, metadata-blocked finishes and review recoveries. Do not invent a report count before running the census.

Program targets: 100% parseability for **new** compliant V2 receipts, zero falsely-green fatal resource/parser diagnostics, each medium/high follow-up either linked to a named active owner or explicitly reported unowned, and exact test/baseline provenance in recorded failure triage. Do not demand a green baseline by silencing tests.

Run focused Python negative controls before broad sweeps; use repository-wide packet authoring and pairing/AI context validation, bounded index regeneration, manifest coverage and the canonical `run_validation.py --changed --base origin/main --json` gate. Respect Git LFS locality, Godot writer lock, and dirty persistent checkout preservation. Paired reviews remain independent post-land fresh contexts.

## 5. Documentation drift to reconcile in PF1

`custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` still describes bounded index initialization as deferred even though `task_packets/README.md` has live managed markers. It proposes `check_task_packets.py`, `check_prompts.py`, `validate_docs.py`, and `check_git_safety.py` as separate paths not found in inspected main, while adjacent check functionality already exists. Do not introduce redundant validators or mark proposals complete without inspecting real live owner behavior.

## 6. Process and provenance

This program does **not** modify H5, Stealth, NPA or other feature workstreams. Packet publication does not constitute implementation, review, claim, or runtime rollout. The immediate next step after main publication is PF1 claim under the normal dispatcher, not any review claim.

- Planning source: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Root authoring authority: `AGENTS.md`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `AGENT_REVIEW_PACKET_TEMPLATE.md`.
- Validation and workflow authority: `custodian/tools/agent/workstream.py`, `dispatch.py`, `task_packet_index.py`, `check_ai_context.py`, `custodian/tools/validation/run_validation.py`.
- Representative evidence: `TASK_PACKET_PIPELINE_EXECUTION_HARDENING_V1_CLAUDE_SUMMARY.md`, `VAULTWING_IMPORT_METADATA_REPAIR_CLAUDE_SUMMARY.md`, `REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_CLAUDE_SUMMARY.md`, `NPA_7_REVIEW_CLOSEOUT_CORRECTION_CLAUDE_SUMMARY.md`, `OPERATOR_DODGE_DOMAIN_EXTRACTION_CLAUDE_SUMMARY.md`.

## 2026-10-11 PF5 post-closeout correction and successor hold

The original PF5 independent review archived a `passed` receipt on `origin/main@fdc4c22`, but a subsequent confirmed R0-01 reproduction found the reviewer cannot both preserve the exact original target bytes (`paired_review_runner.py`) and append the target's mandatory `## Independent Review` receipt (`workstream.py`). The original review PASS is **historical, not currently accepted**. The original report and local coordinator run evidence (`.git/custodian-review-runs/review-agent-paired-review-coordinator-boundary-v1/20261011T090553Z-d41e261b7386`) must be preserved.

The bounded cycle-1 correction is `custodian/docs/ai_context/task_packets/AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md` (paired re-review `REVIEW_AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md`). Only a verified append/fill of that target's review-receipt section may change the archived implementation packet; all other original implementation bytes, provenance and required finish gates stay immutable. The downstream `agent-next-execution-boundary-v1` implementation now depends on acceptance of the **cycle-1 re-review**, not the disputed original PASS. This is not a reimplementation of PF5's other accepted work.

Related PF4 `R0-01` on incomplete validation coverage is **already fixed and independently reviewed**, with correction `agent-workstream-closeout-preflight-review-corrections-1`, implementation commit `71cc480ad` and completed re-review. Do not issue a duplicate PF4 correction.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
