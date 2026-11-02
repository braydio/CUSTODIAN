# REVIEW: OPERATOR WORKBENCH FX LAYER ADOPTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-fx-layer-adoption`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-fx-layer-adoption`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-fx-layer-adoption`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `1e62ce7e2ff5dec8e1c76cff1850715f5a1e89dd`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed Workbench FX-adoption slice safely turns an explicit saved Aseprite `vfx`/`fx` layer into canonical Operator `fx` source/runtime content without bypassing publication authority, overwriting concurrent source changes, auto-adopting scratch layers, or weakening rollback/mirror safety.
- Reviewed implementation acceptance: The archived implementation packet's acceptance for saved-layer discovery, explicit `vfx→fx` adoption, pre-publish preview, CREATE/REPLACE transactions and rollback, target/source conflict refusal, mirror opt-in/default-off semantics, binding-set drift detection, and preservation of existing Operator runtime/guard behavior.
- Review evidence: Reuse the implementation's focused fixture hashes/transaction journals, UI projection evidence, CREATE/REPLACE/mirror rollback fixtures, changed-file validation output, and generated runtime/catalog checks. Gather fresh evidence only where those artifacts do not establish an acceptance criterion.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. Route non-blocking issues and optional improvements to next-slice/deferred unless separately justified. Escalate unresolved subjective decisions as `human_required`.
- Focused validation: Inspect the landed manifest/adoption contract and saved-layer inspection path; rerun the focused Workbench model/UI/mirror fixtures, import-preflight/runtime-resource checks, and the narrow modular-defense regression. Verify one CREATE and one REPLACE rollback journal. Confirm CLI counterpart publication is default-off. Finish with the smallest changed-file validation necessary to verify review findings.
- Review focus: Publication authority and allowlist confinement; absent-source state handling; stale/collision concurrency guards; exact RGBA export from the saved named Aseprite layer; manifest normalization after publish; rollback deletion/restoration; explicit mirror semantics; no automatic adoption; no accidental claim that Art Agent creation mode is generally live.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects and material acceptance-proof gaps create `operator-workbench-fx-layer-adoption-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not redesign Workbench, add non-FX layer adoption, modify Operator art/gameplay, create new visual baselines, or fix reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation dependency is complete and archived on `origin/main`.
2. Read the archived implementation packet and closing summary, current Workbench design/Art-Agent roadmap, and live implementation files before evaluating the diff.
3. Review against the implementation packet's acceptance contract, with source/publication/rollback safety taking precedence over stylistic preference.
4. Use implementation-produced hashes and transaction artifacts first; recapture nothing visual unless exact pixel evidence is missing or contradictory.
5. Record the independent review receipt and follow the standard correction lifecycle if a blocking defect/evidence gap is confirmed.

## Handoff

- Next action: Claim the bounded correction after this review is archived, then run its paired fresh-context review.
- Blockers or open questions: Correction `R0-01` is required before the source-conflict acceptance is closed.

## Independent Review

- Status: `findings`
- Review workstream: `review-operator-workbench-fx-layer-adoption`
- Reviewed on main: `1e62ce7e2ff5dec8e1c76cff1850715f5a1e89dd`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Blocking defects: `1`
- Material evidence gaps: `0`
- Non-blocking issues: `1`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `R0-02`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_WORKBENCH_FX_LAYER_ADOPTION_CLAUDE_SUMMARY.md`
- Follow-up workstream: `operator-workbench-fx-layer-adoption-review-corrections-1`

### Findings

#### R0-01 — REPLACE source can change after freshness validation and still be overwritten

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: The archived implementation packet requires publication to refuse when the canonical FX source changes after adoption and requires rollback to preserve pre-transaction canonical bytes.
- Evidence: `custodian/tools/operator/animation_workbench.py` checks `source_contract_freshness(data)` at lines 449–455, then later backs up the current `old` bytes and replaces the target at lines 519–557 without comparing those bytes to the adopted `file_sha256` immediately at the source-swap boundary. CREATE has an atomic `os.link` no-overwrite guard; REPLACE uses `os.replace`, which overwrites a path changed after the earlier check. A concurrent edit in this interval is therefore accepted and can also become the rollback preimage.
- Disposition: `correction`
- Rationale: This violates the explicit changed-source refusal and can discard another writer's canonical edit. Add an interleaving regression that changes the REPLACE target after initial freshness validation and proves publish refuses without changing the external bytes; ensure rollback cannot restore over a concurrent replacement.

#### R0-02 — Modular-defense smoke emits broad pre-existing project/resource errors

- Class: `non_blocking_issue`
- Domain: `pipeline`
- Affected acceptance: Existing focused Operator guard smokes remain green.
- Evidence: The focused `operator_modular_defense_ranged_smoke.gd` process exited 0 and printed its PASS marker, but emitted project-wide missing-class/imported-resource diagnostics and `Invalid call. Nonexistent function '_exit_ranged_ready (via call)'` while executing a test helper. The implementation summary already records the missing-resource/animation diagnostics; this fresh rerun saw the helper-call error too.
- Disposition: `deferred`
- Rationale: This Workbench/tooling change does not alter gameplay code, and the dedicated Workbench/UI/mirror tests plus import-preflight passed. Keep the caveat attached to the smoke evidence; a focused smoke reliability repair can be handled separately.
