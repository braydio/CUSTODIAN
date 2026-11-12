# REVIEW ES-2: PROCGEN REFUSED PASSAGE PHYSICAL EVIDENCE PILOT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-environmental-evidence-refused-passage-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-environmental-evidence-refused-passage-v1`
- Locks: `procgen-runtime`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `procgen-environmental-evidence-refused-passage-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ENVIRONMENTAL_EVIDENCE_REFUSED_PASSAGE_V1.md`
- Reviewed main: `eb4de63498ef13eacc86022613bfa35f825d8b7f`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Falsify the ES-2 physical story site's geometry, route/collision safety, deterministic plan/provenance, native Operator interactions, streaming lifecycle and separation from Asset V2/Operator/F15 authorities.
- Reviewed implementation acceptance: `A1–A6` from archived `PROCGEN_ENVIRONMENTAL_EVIDENCE_REFUSED_PASSAGE_V1.md` and complete linked `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES2_REFUSED_PASSAGE.md`.
- Review evidence: Exact landed commit and archived packet, new pure plan/presenter, source ES-1 site/accepted-region record, physical site instance/scene, route/collision/nav/interaction fixtures, site plan fingerprint, accepted-world parity, changed-file report and minimal ROI evidence.
- Correction threshold: Zero physically composed sites in positive control; global RNG or competing site owner; wrong rect/node; impassable required route; false-open gate or false-closed bypass; new permanent state/unsafe road; duplicate props/prompts/blockers; unreachable/through-wall interactables; variant visual evidence omitted; unsupported production-art approval; unverifiable changed-source/provenance. Subjective future art polish alone does not constitute a runtime defect.
- Focused validation: Independent positive ES-2 fixture plus at least six adversarial negatives: mismatched rect, protected ingress, blocked 3-cell lane, clipped footprint, prompt ambiguity/behind-gate interaction, stale stream teardown/duplicate reveal. Confirm the real Operator can use both 72px default readouts under 84px cap, keep no quest side effects. Run new focused ES-2 smoke, existing story/intent/accepted-export, road/protection, runtime blocker and M5/M6 sweeps justified by changed coverage, then manifest/AI-context/review pairing and `git diff --check`. Reuse implementation objective ROI unless untrustworthy.
- Review focus: Confirm placement driven solely by ES-1 site records, not fabricated road from STORY_APPROACH. Check exact 16×12 (or 12×16) native 32px footprint, four causal evidence layers and readable distinction between closed checkpoint versus traversable bypass. Verify no code-driven art promoted as Asset V2 source.
- Acceptance: Findings-first fresh-context independent receipt with zero blocking defects and zero material validation gaps. If material, create a bounded correction/re-review through normal workflow; do not edit reviewed implementation from this reviewer. Subjective artwork remains ES-4 or a single separate owner visual decision, never silently accepted via a technical PASS.
- Non-goals: Rewrite implementation, issue new art family approvals, create canonical polity/site history, mark prior ES-1 review passed, delete unrelated worktrees or perform global queue cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Fresh independent context. Pin exact implementation landing, archived packet, its included ES-2 design doc and immutable evidence.
2. Independently inspect geometry/collision/site-parent identity and generate adversarial safe-skip, player-reachability and idempotent chunk/reveal cases.
3. Verify two repeatable readouts with no fake persistent state. Inspect only minimum ROI if objective checks cannot establish the visual evidence distinction.
4. Record truthful findings, PASS or corrections. Do not claim ES-3 or modify earlier ES-1 review receipt.

## Next Handoff

- Next workstream: `none`
- Next packet state: `ES-3 design/authoring after accepted review`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Next action: On independent technical acceptance, author ES-3 Borrowed Hearth + False Seam reuse of this exact planner/presenter seam.
- Blockers or open questions: ES-2 implementation must land and archive with actual test evidence.
