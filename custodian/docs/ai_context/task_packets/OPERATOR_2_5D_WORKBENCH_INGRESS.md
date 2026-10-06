# OPERATOR 2.5D WORKBENCH GUIDED INGRESS

> **PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> After WB25-1 and its review land, return their evidence to the authoring chat,
> reconcile this packet against current main and the landed generation APIs,
> then set Status to ready.

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-workbench-ingress`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-2-5d-workbench-cockpit-foundation`
- Locks: `operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-2-5d-workbench-ingress`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `f8ef4c84adf8f332713d4284a4c3aaa89ef51fb0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Visual review: `none`
- Goal: Let an artist select a missing 2.5D leaf and bring new art into the correct semantic/generation Workbench through one guided New/Import flow, including an eight-direction package intake, without manually chaining Source Session commands or bypassing provenance/normalization/publication safety.
- Completion boundary: Add identity-bound guided intake over the landed target tree. Native creation reuses reviewed New Animation. External/generated pixels reuse Source Art Service before creation. Add directional-package orchestration and truthful progress. No network image generation.
- Current measured state: pre-authored; exact WB25-1 API is intentionally unresolved. Existing New Animation creation and Source Art Service already own low-level operations.
- Evidence: refresh with landed WB25-1/review receipts plus current New Animation and Source Art Service files.
- Task-specific authority: landed WB25-1 target/generation model; reviewed New Animation publisher; Source Art Service for external/generated art; canonical profile for normalization.
- Work surface: target action UI; Source Art Service orchestration; creation-session handoff; package manifest/status; publication backend; focused UI/source-session tests.
- Change:
  1. A `MISSING` 2.5D leaf offers `NEW / IMPORT` with semantic/generation/profile/frame defaults pre-filled.
  2. Native blank/reference creation delegates to New Animation.
  3. Imported/generated art automatically starts an identity-bound Source Session with canonical target/profile/reference SHA.
  4. Orchestrate the existing start→analyze→plan→register→convert→review→handoff stages; keep receipts inspectable.
  5. Imported art cannot publish directly before canonical normalization/review/handoff.
  6. Add `Import Direction Set` for one action: one confirmed grid/sheet or eight direction files. Never guess ambiguous direction order.
  7. Package manifest records identity, generation, profile/reference SHA, required directions/layers, source hashes, session IDs and progress.
  8. Package completion requires all required cells; incremental per-direction work is allowed.
  9. Retry resumes verified sessions/receipts instead of repeating transformations.
  10. Canonical destinations come from generation-aware schema only.
  11. Keep guarded per-semantic publication unless refreshed live code proves a safe bounded batch publisher is clearly better.
  12. External 2.5D intake must never overwrite legacy paths.
- Preserve: legacy edit/publish, New Animation, Source Session CLI, profile hash checks, publish rollback/landing, recovery safety.
- Non-goals: automatic generation, runtime cutover, second normalizer, anatomy auto-split, hidden mirror completion.
- Acceptance: one missing leaf can import a generated strip and reach editable Workbench without manual paths/CLI; eight-direction package tracks all cells; wrong generation/profile/grid/collision fails before canonical mutation; interrupted work resumes; legacy files remain untouched.
- Validation: refresh exact scripts; minimum single import, ambiguous-grid refusal, wrong-generation refusal, collision, resume, mixed-state 8-dir package, rollback, legacy-path negative control.
- Task overrides: `none`
- Deferred: generation briefs, chain review, sandbox proof, throughput dashboard.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh instruction: `Bring WB25-1 implementation + review summaries and live main back to this chat. Re-derive generation-aware selection/creation APIs, Source Session handoff, paths, locks and focused tests before ready.`

## Handoff
- Next workstream: `review-operator-2-5d-workbench-ingress`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include exact Authoring chat URL
- Refresh reason: `none after this packet is refreshed`
- Next action: `paired review`
- Blockers or open questions: `packet must be refreshed before claim`
