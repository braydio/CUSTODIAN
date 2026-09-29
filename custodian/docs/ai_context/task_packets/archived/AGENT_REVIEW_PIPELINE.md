# AGENT REVIEW PIPELINE

- Workstream: `agent-review-pipeline`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-task-dispatch, agent-task-dispatch-review-corrections`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-review-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Make independent post-land review a first-class automatically scheduled stage of substantial CUSTODIAN implementation work, so confirmed defects become bounded correction work without requiring the user to remember to request review or relay findings between terminals.
- Current measured state: CUSTODIAN already has isolated workstreams, focused validation, safe main landing, required closing summaries, packet archival, Moment Forge evidence, and a findings-first runtime review prompt. The queued `agent-task-dispatch` bootstrap adds repository-native task claiming. The missing seam is durable review intent, paired independent review work, review receipts, and a finite correction/re-review loop.
- Task-specific authority: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, the live/archived `AGENT_TASK_DISPATCH.md`, `custodian/docs/ai_context/prompts/review_runtime_change.md`, `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, and the live dispatcher produced by `agent-task-dispatch`.
- Change: Add packet-level review metadata and a paired-review workflow built on ordinary dispatcher/workstream primitives. Auto-reviewed implementation packets have a paired review packet blocked on the implementation workstream. After implementation lands, a fresh reviewer audits live `main`, writes a durable receipt, and either passes or queues a narrow correction packet plus its own follow-up review.
- Preserve: Existing dispatcher safety, one-task-per-claim behavior, workstream/landing authority, validation-before-landing, design authority, no-force-push/reset/stash policy, and human ownership of subjective visual baseline acceptance.
- Non-goals: No mandatory pre-land review gate in V1; no GitHub PR review requirement; no permanent review daemon; no reviewer identity database; no requirement for a different model vendor; no auto-approval of subjective visual baselines; no reviewer fixes to reviewed implementation code; no infinite correction loop; no review requirement for every trivial edit.
- Acceptance: After landing, task authors can declare review intent and pair substantial implementation work with a review task. The dispatcher automatically makes the reviewer eligible after the implementation dependency completes. Reviewer findings are durable. Blocking defects queue corrections and another review. Non-blocking suggestions do not manufacture work. The loop terminates after the configured cap and escalates to a human decision instead of recurring forever.
- Task overrides: `none`
- Deferred: Exceptional pre-land review gates; distributed reviewer leases; continuous worker mode; dashboard UI; exact automatic multi-commit review-range metadata; subjective visual baseline approval.

## Ownership And Timing

- Owner: agent workflow / review orchestration
- Agent/session: Claude Sonnet 5, `agent/agent-review-pipeline`, picked up after a
  stale prior claim (0 unique commits, ~4h idle) was released
- Created: 2026-09-28
- Last updated: 2026-09-28

## Completion Notes

- Extended `dispatch.py`'s packet parser with the full review metadata
  contract (`Kind`, `Review`, `Review stage`, `Review modes`, `Paired review
  workstream`, `Review cycle`, `Max automatic review cycles`, `Review target
  workstream/packet`), all with the specified safe defaults so every existing
  historical packet (125 of 144 active packets predate the `Workstream:`
  header convention entirely) remains valid without edits.
- Added `validate_review_pairing(packets) -> dict[workstream, error]`: the one
  reusable validation authority, wired into `_decision` (so an invalid pairing
  fails closed at claim time exactly like invalid packet metadata) and exposed
  standalone via `custodian/tools/agent/validate_review_pairing.py`
  (registered as `review_pairing_contract`). Confirmed 0 false positives
  against the 5 real `Review: auto` packets already live on `main`.
- Added `review_cycle_exhausted(packet)` so a reviewer at the configured cap
  has a concrete check to decide `human_required` instead of another
  automatic correction, rather than relying purely on manual convention.
- `dispatch.py status` now labels review/correction packets (`(review of
  <target>)`, `(correction)`) per the acceptance's "make review jobs legible"
  requirement, without adding a second eligibility mechanism — review and
  correction packets are ordinary `Dispatch`/`Depends on`/`Locks` packets.
- Did not touch `REVIEW_AGENT_REVIEW_PIPELINE.md` (left active/ready, per
  Self-Bootstrap) or `workstream.py finish` (review remains a follow-on
  workstream, never a finish blocker, per Architectural Lock).
- 15/15 packet-required focused proofs added to `test_dispatch.py` (53/53
  passing total: 38 pre-existing + 15 new); `test_workstream.py` 9/9 passing
  (untouched by this task); `agent_workflow_smoke.py` and the changed-file
  closeout sweep green. See
  `AGENT_REVIEW_PIPELINE_CLAUDE_SUMMARY.md` for the full validation/test
  mapping and one awkward note.

## Architectural Lock

### Post-land by default

V1 independent review happens after validated implementation lands on `main`.

Do not make review a mandatory hold inside `workstream.py finish` in this task. The implementation worktree should close normally. Review is a separate workstream operating against one canonical live state.

### Independent means fresh workstream/context

Independent review requires:

- a separate review workstream ID;
- a separate dispatcher claim;
- a fresh agent context;
- no implementation fixes inside the review workstream.

Do not try to prove that another vendor, machine, or human identity performed the review.

### Use the existing queue

Paired review packets are ordinary dispatcher jobs using `Dispatch`, `Depends on`, `Locks`, and `workstream.py`. Do not build a second scheduler.

## Review Metadata Contract

Extend task packet conventions/template with:

```text
- Kind: `implementation` | `review` | `correction`
- Review: `auto` | `manual` | `none`
- Review stage: `post-land`
- Review modes: comma-separated modes or `none`
- Paired review workstream: `<id>` or `none`
- Review cycle: integer
- Max automatic review cycles: integer
```

Safe defaults:

- missing `Kind` = `implementation`;
- missing `Review` = `none` for historical packets;
- missing review stage = `post-land` when review is auto;
- review packets use `Review: none` so reviews do not recursively generate reviews.

Supported V1 modes:

- `code`: behavior, edge cases, determinism, error handling, grounded performance risks, unsafe side effects;
- `architecture`: ownership leaks, duplicate authority, wrong lifecycle seams, parallel systems, god-file growth;
- `runtime`: current runtime behavior and deterministic/runtime evidence;
- `visual`: Moment Forge/screenshots/readability/composition, without auto-approving baselines;
- `asset-pipeline`: Asset V2 provenance, dimensions, alpha/state identity, integrity, consumer binding, generated ownership;
- `workflow`: dispatch/worktree/branch/landing/automation safety.

## Packet Authoring Rule

For substantial implementation work, review intent is decided when the implementation packet is created.

When `Review: auto` is selected, the task author also creates a paired review packet on `main`.

Naming convention:

```text
TWIN_SOLARIA_RUNTIME_V1.md
workstream: twin-solaria-runtime-v1

REVIEW_TWIN_SOLARIA_RUNTIME_V1.md
workstream: review-twin-solaria-runtime-v1
```

The review packet declares:

```text
Kind: review
Status: ready
Dispatch: auto
Depends on: twin-solaria-runtime-v1
Review: none
Review target workstream: twin-solaria-runtime-v1
Review target packet: custodian/docs/ai_context/task_packets/archived/TWIN_SOLARIA_RUNTIME_V1.md
```

Add a compact reusable review packet template at `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`.

## Review Execution Contract

A reviewer must:

1. Work from current fetched `origin/main` in its own workstream.
2. Read the paired review packet, archived implementation packet, implementation closing summary, active design authority, relevant review prompt, and live implementation files.
3. Review the landed implementation against the original acceptance contract, not just style.
4. Report findings first with file/line references where possible.
5. Prioritize correctness, determinism, ownership, duplicated authority, unsafe lifecycle assumptions, missing proof, stale docs, and mode-specific runtime/asset/visual defects.
6. Distinguish confirmed defects, evidence gaps/questions, and optional improvements.
7. Do not modify reviewed implementation/runtime code in the review workstream.
8. Record a durable review receipt.
9. If blocking findings exist, create a narrow correction packet and its paired review packet before landing the review workstream.

Use `custodian/docs/ai_context/prompts/review_runtime_change.md` as the default findings-first review stance.

## Review Scope

V1 does not need a new database of commit ranges. Review uses the durable implementation record:

- archived implementation packet;
- required closing summary;
- active design authority;
- current live `main` implementation;
- relevant Git history when useful.

If the implementation record is too vague to identify what was actually changed or proven, record that as an evidence/process finding.

## Durable Review Receipt

Append or refresh this bounded section in the archived implementation packet:

```md
## Independent Review

- Status: `pending | passed | findings | human_required`
- Review workstream: `review-...`
- Reviewed on main: `<short SHA/current target>`
- Review modes: `...`
- Blocking findings: `N`
- Non-blocking findings: `N`
- Detailed review summary: `<reviewer closing-summary path>`
- Follow-up workstream: `none | <correction-id>`
```

The implementation packet remains `Status: complete`. Implementation completion and independent review are separate truths.

## Finding Classes

### Blocking

Queue correction for confirmed:

- incorrect behavior or broken acceptance;
- determinism/state corruption;
- data-loss or unsafe workflow behavior;
- architecture violations that create competing truth;
- missing required proof that prevents confidence in the claimed feature;
- materially false active documentation.

### Non-blocking

Record without automatically forcing correction:

- optional cleanup;
- naming/style;
- speculative optimization;
- low-value refactor;
- enhancement outside original acceptance.

Do not manufacture work from taste.

## Automatic Correction Contract

When blocking findings exist, the reviewer creates a correction packet and paired review packet before landing.

Naming:

```text
twin-solaria-runtime-v1-review-corrections-1
review-twin-solaria-runtime-v1-review-corrections-1
```

Correction packet:

```text
Kind: correction
Status: ready
Dispatch: auto
Priority: P0 for blocking correctness/workflow defects, otherwise P1
Depends on: review-<original>
Review: auto
Review stage: post-land
Paired review workstream: review-<correction>
```

It contains only concrete findings, affected acceptance, required behavior, preservation/non-goals, relevant work surface, and focused validation. Do not restate the original packet.

Create the correction's paired review packet in the same review workstream so the correction is automatically re-reviewed.

## Finite Review Loop

Use:

```text
Review cycle: 0
Max automatic review cycles: 2
```

Original implementation review is cycle 0. First correction review is cycle 1. Second correction review is cycle 2.

If blocking findings remain after cycle 2:

- do not generate another automatic correction;
- set review receipt status to `human_required`;
- create a concise `Dispatch: manual` decision/follow-up surface if useful;
- state the unresolved conflict and evidence precisely.

## Human Decision Gate

Do not auto-approve genuinely subjective choices such as visual baselines, art direction, game-feel tradeoffs not locked by design, or unresolved canon/design interpretation.

For these, finish technical review, set `human_required`, identify the exact decision/evidence, and do not guess the user's preference.

Objective technical defects in the same task still become corrections automatically.

## Visual And Asset Review

For `visual` review, inspect available Moment Forge/capture evidence and distinguish objective defects from preference. Never approve/replace a baseline automatically.

For `asset-pipeline` review, inspect Asset V2 contract/provenance, native dimensions/frame counts, alpha/state identity, runtime consumer binding, expected source/runtime integrity, stale source/inbox/generated artifacts, and docs drift. Do not regenerate art just to review it.

## Dispatcher Integration

Rely on the dependency semantics introduced by `agent-task-dispatch`.

Example:

```text
implementation: twin-solaria-runtime-v1 -> complete/archived
review: review-twin-solaria-runtime-v1 -> ready/auto/depends on implementation
```

When the implementation dependency is complete on `origin/main`, the review becomes eligible.

`dispatch.py status` should make review jobs legible, preferably displaying `Kind: review` and the target workstream. Keep eligibility generic.

## Consistency Guard

Add fail-fast validation for new auto-reviewed packets.

For an active packet with `Review: auto`, require a matching active review packet with:

- the declared paired review workstream;
- `Kind: review`;
- `Review: none`;
- dependency on the implementation workstream;
- matching target workstream/packet.

Put this in one reusable validation authority consumed by tooling/tests. Do not make historical packets fail for omitted review metadata.

## Focused Tests

Use temporary repositories/worktrees. Prove at least:

1. historical packet without review metadata remains valid;
2. `Review: none` requires no pair;
3. `Review: manual` does not imply auto review;
4. `Review: auto` requires a paired review declaration;
5. paired review must be `Kind: review` and `Review: none`;
6. paired review dependency/target identity must match implementation;
7. review remains blocked until implementation dependency is complete;
8. review becomes eligible when implementation is archived complete;
9. a `passed` receipt is durable without generating correction;
10. blocking findings scaffold a narrow correction packet;
11. correction scaffolding also creates its paired review;
12. review cycle increments correctly;
13. max cycle escalates to `human_required` rather than creating another auto correction;
14. reviewer workflow does not grant authority to edit implementation code;
15. existing dispatcher and workstream tests remain green.

Register focused validation ownership when appropriate, then run the normal changed-file closeout sweep.

## Documentation And Drift Remediation

Update only owned truth:

1. `AGENT_TASK_PACKET_TEMPLATE.md`: review metadata and safe defaults.
2. Add `AGENT_REVIEW_PACKET_TEMPLATE.md`.
3. `task_packets/README.md`: paired review + correction lifecycle.
4. `AGENT_WORKSTREAM_LIFECYCLE.md`: post-land review is a follow-on workstream, not a finish blocker.
5. `AGENT_AUTOMATION_BACKLOG.md`: mark review pipeline implemented; preserve deferred pre-land/distributed/continuous work.
6. `VALIDATION_RECIPES.md`: focused review-pipeline validation.
7. `FILE_INDEX.md`: review tooling/template.
8. `CURRENT_STATE.md`: only if current workflow truth becomes stale.
9. `prompts/README.md` / `review_runtime_change.md`: only if discoverability or mode contract requires it.
10. `AGENTS.md` / `custodian/AGENTS.md`: compact routing only, no duplicated workflow essay.

Existing drift to fix: the repo already exposes Review as an agent work mode and has `review_runtime_change.md`, but the lifecycle has no durable independent-review stage. Connect those existing concepts rather than inventing a parallel philosophy.

## Self-Bootstrap

This implementation packet itself declares `Review: auto` with paired workstream `review-agent-review-pipeline`.

A paired packet must exist on `main` at `custodian/docs/ai_context/task_packets/REVIEW_AGENT_REVIEW_PIPELINE.md`.

After this implementation lands and archives this packet, the paired review must become eligible and serve as the first end-to-end production proof.

Do not special-case this workstream to skip its own independent review.

## Completion

Before normal `workstream.py finish`:

- mark this packet `complete` and archive it;
- leave `REVIEW_AGENT_REVIEW_PIPELINE.md` active/ready;
- update packet README/index truthfully;
- commit required closing summary;
- provide green focused validation JSON;
- land normally.

Do not mark the paired review complete in this implementation workstream.

## Handoff

- Next action: After `agent-task-dispatch` lands, `dispatch.py claim-next --agent codex` should select this P0 task when no higher eligible lock conflict exists.
- Best starting files: live `dispatch.py`, `workstream.py`, `AGENT_TASK_PACKET_TEMPLATE.md`, and `review_runtime_change.md`.
- Blockers or open questions: `agent-task-dispatch` must land first. No other known blocker.