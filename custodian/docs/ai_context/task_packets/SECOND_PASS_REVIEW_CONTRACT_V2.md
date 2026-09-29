# SECOND PASS REVIEW CONTRACT V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `second-pass-review-contract-v2`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-agent-review-pipeline-review-corrections-1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Reviewed main: `e426995d8`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-second-pass-review-contract-v2`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Make CUSTODIAN's implementation second pass acceptance-driven, findings-first, and bounded: reviewers identify stable evidence-backed findings, distinguish real corrections from improvements, route pipeline/process failures separately, and create narrow correction deltas instead of re-planning the entire feature.
- Completion boundary: Upgrade the live review/correction authoring contract, review prompt/lifecycle guidance, correction-packet template, durable review receipt, and available structural validation so both automatic paired review and the user's manual "review this implementation and roll fixes into the next slice" workflow use one consistent disposition model.
- Current measured state: Task packets now use `custodian.task_packet.v2` and `custodian.task_feedback.v1`, but `AGENT_REVIEW_PACKET_TEMPLATE.md` still uses the older compact review shape. It classifies findings but does not give them stable IDs, does not record reviewed implementation acceptance/evidence as first-class fields, does not define a correction threshold for evidence gaps/non-blocking improvements, and correction packets are created ad hoc without a dedicated delta template. The paired-review pipeline's first consistency correction and re-review are now complete/passed.
- Evidence: `AGENT_TASK_PACKET_TEMPLATE.md` defines V2 evidence/scope/feedback fields; `AGENT_REVIEW_PACKET_TEMPLATE.md` remains legacy-shaped; `task_packets/README.md` currently routes blocking findings into correction work but only counts blocking/non-blocking findings in the durable receipt; archived `AGENT_REVIEW_PIPELINE.md` defines the independent post-land finite-loop architecture; archived `REVIEW_AGENT_REVIEW_PIPELINE_REVIEW_CORRECTIONS_1.md` records a passed review on main `04aa9ee06`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`, `AGENT_REVIEW_PACKET_TEMPLATE.md`, `task_packets/README.md`, `prompts/review_runtime_change.md`, `AGENT_WORKSTREAM_LIFECYCLE.md`, live `dispatch.py` / `validate_review_pairing.py`, and the V2 AI-context validator implementation or queued `AI_CONTEXT_TASK_PACKET_VALIDATOR.md` contract, whichever is current when this workstream runs.
- Work surface: Primary ownership is review/correction packet authoring and lifecycle documentation. Expected files include `AGENT_REVIEW_PACKET_TEMPLATE.md`, a new `AGENT_CORRECTION_PACKET_TEMPLATE.md`, `task_packets/README.md`, `review_runtime_change.md`, and focused agent validation/tests. Touch dispatcher eligibility only when a new structural field must be enforced there; do not move semantic review-quality scoring into dispatch.
- Change: Upgrade review/correction authoring to V2, add stable finding identity and explicit class/domain/disposition fields, define correction thresholds, add a correction delta template referencing finding IDs, extend the durable independent-review receipt with class counts/disposition, distinguish implementation findings from pipeline/process findings, and ensure V2 structural validation covers the new packet shapes without invalidating legacy packets.
- Preserve: Fresh independent review workstreams; post-land-by-default architecture; no reviewer edits to reviewed implementation/runtime code; ordinary dispatcher dependency/lock scheduling; canonical archived target-packet binding; finite review-cycle cap; historical packet compatibility; human ownership of subjective visual/game-feel/canon decisions; patch-first behavior for ordinary non-independent maintenance outside the paired-review workstream.
- Non-goals: No pre-land mandatory review gate; no reviewer score/tier/quality grade; no second scheduler; no automatic subjective approval; no infinite correction loop; no broad historical packet migration; no requirement to create work for optional cleanup; no dashboard/analytics system for feedback in this slice.
- Acceptance: New review packets use V2 fields and explicitly bind reviewed main/target, original acceptance, review evidence, correction threshold, and focused validation. Findings receive stable cycle-scoped IDs and class/domain/disposition data. Only confirmed acceptance/correctness defects and material proof gaps automatically become correction work; non-blocking issues and optional improvements route to next-slice/deferred unless separately justified. Correction packets use one dedicated V2 delta template and reference exact finding IDs instead of restating the original feature packet. Durable review receipts expose counts and disposition. Pipeline/process findings use the task-feedback contract and produce a small fix or named follow-up rather than being mixed into product-code corrections. Legacy review packets remain valid.
- Validation: Run focused review-pairing/dispatcher tests, V2 packet validation when available, prompt-contract validation for changed reusable prompts/templates, and changed-file validation. Add fixture coverage for finding-ID/disposition/correction-template structure without attempting subjective prose scoring.
- Task overrides: `none`
- Deferred: Aggregate feedback analytics/dashboarding; review-quality scoring; automatic clustering of recurring feedback; exceptional pre-land review gates; commit-range database beyond durable packet/summary/main evidence.

## Review Finding Contract

Each review finding gets a stable ID unique within the review lineage:

```text
R<review-cycle>-<NN>
```

Examples: `R0-01`, `R0-02`, `R1-01`.

A finding record must include:

```text
ID:
Class: blocking_defect | evidence_gap | non_blocking_issue | optional_improvement
Domain: implementation | pipeline
Acceptance affected:
Evidence:
Disposition: correction | next_slice | deferred | human_required | no_action
Rationale:
```

A correction packet references the full IDs it addresses. Re-review preserves those IDs when reporting `fixed`, `unresolved`, or `regressed`; genuinely new findings use the current review cycle's next ID.

## Correction Threshold

| Finding class | Default disposition |
| --- | --- |
| confirmed `blocking_defect` | correction |
| `evidence_gap` that prevents confidence in required acceptance/proof | correction |
| evidence gap that does not invalidate claimed acceptance | record / next slice |
| `non_blocking_issue` | next slice or deferred |
| `optional_improvement` | deferred or no action |
| unresolved subjective design/art/game-feel/canon decision | human_required |

Architecture violations that create competing authority, unsafe lifecycle behavior, state/data corruption, materially false active docs, and required validation/proof failures count as blocking when confirmed.

Do not manufacture correction work from taste, speculative optimization, cleanup, or a new feature idea discovered during review.

## Review Result Summary

Extend the durable `## Independent Review` receipt with:

```text
Status: passed | findings | human_required
Review workstream:
Reviewed on main:
Review modes:
Blocking defects:
Material evidence gaps:
Non-blocking issues:
Optional improvements:
Correction finding IDs:
Next-slice finding IDs:
Human-decision finding IDs:
Detailed review summary:
Follow-up workstream:
```

Keep the archived implementation packet's `Status: complete`; implementation completion and review outcome remain separate truths.

## Delta Correction Template

Add `custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md` using `custodian.task_packet.v2`.

Require at minimum:

```text
Parent implementation:
Parent review:
Findings addressed:
Affected acceptance:
Current defect/evidence:
Required correction:
Work surface:
Preserve:
Non-goals:
Acceptance:
Validation:
Deferred:
```

Correction packets remain ordinary `Kind: correction`, `Review: auto` packets with their paired re-review. They must not restate the original feature design unless a finding proves the original authority itself is wrong.

## Manual Second-Pass Alignment

Document that the user's conversational/manual second-pass request follows the same finding classes and disposition model.

For ordinary ad hoc maintenance outside the formal independent reviewer, repository patch-first rules still apply: a truly small, safe, obvious correction may be patched directly. Inside a paired independent review workstream, preserve independence and never patch the reviewed implementation; create the narrow correction workstream instead.

Useful non-blocking improvements should preferentially roll into the next real feature slice or deferred work rather than extending a correction loop.

## Pipeline Feedback Separation

Implementation findings describe what is wrong with the product/code/contract being reviewed.

Pipeline findings describe why the agent/task/review process allowed the problem, created friction, or nearly failed. Record the latter through `custodian.task_feedback.v1`.

For repeatable medium/high-severity pipeline findings, fix the small safe workflow/docs/tooling issue in an authorized scope or create/name the follow-up workstream. Do not hide it only in prose.

## Structural Validation

Do not create a second packet parser.

When this workstream runs:

- if the V2 AI-context validator is already implemented, extend its shared structural checks/tests for V2 review/correction packet requirements;
- if it is still queued, update `AI_CONTEXT_TASK_PACKET_VALIDATOR.md` so its eventual implementation covers these review/correction fields and feedback receipts;
- keep semantic judgment such as "is this truly blocking?" outside automated validation;
- preserve legacy packet compatibility.

At minimum fixtures should prove:

1. legacy review packet remains valid;
2. V2 review packet requires reviewed-main/target/acceptance/evidence/correction-threshold fields;
3. stable finding ID format accepts valid IDs and rejects malformed IDs where structurally validated;
4. correction delta packet requires parent review/implementation and non-empty findings addressed;
5. a correction cannot silently omit all finding IDs;
6. durable review receipt can represent all four finding classes and dispositions;
7. paired-review consistency tests remain green;
8. historical review/correction packets are not bulk-migrated.

## Handoff

- Next action: Claim with `python3 custodian/tools/agent/dispatch.py claim second-pass-review-contract-v2 --agent codex`.
- Best starting files: `AGENT_REVIEW_PACKET_TEMPLATE.md`, `task_packets/README.md`, `review_runtime_change.md`, current V2 packet validator authority, and archived `AGENT_REVIEW_PIPELINE.md`.
- Blockers or open questions: None. The prerequisite review-pipeline correction re-review is already complete/passed.
