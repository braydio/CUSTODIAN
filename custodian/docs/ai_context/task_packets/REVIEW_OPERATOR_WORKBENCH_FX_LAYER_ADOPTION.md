# REVIEW: OPERATOR WORKBENCH FX LAYER ADOPTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-fx-layer-adoption`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-fx-layer-adoption`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-fx-layer-adoption`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_FX_LAYER_ADOPTION.md`
- Reviewed main: `0c2a646ccd`
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

- Next action: Auto-dispatch after `operator-workbench-fx-layer-adoption` completes and archives.
- Blockers or open questions: none.