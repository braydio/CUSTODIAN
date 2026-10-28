# REVIEW PROCGEN ENVIRONMENTAL EVIDENCE V1: ES-1 SITE IDENTITY FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-environmental-evidence-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-environmental-evidence-v1`
- Locks: `procgen-runtime`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `procgen-environmental-evidence-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ENVIRONMENTAL_EVIDENCE_V1.md`
- Reviewed main: `a358584555f91e396f7da3ac4e883aff27c143f3`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Goal: Independently verify that ES-1 binds story metadata and story geometry to one existing F02 intent node/rectangle and produces stable optional, safe site identity without new state authorities.
- Reviewed implementation acceptance: `A1–A5` from the archived `PROCGEN_ENVIRONMENTAL_EVIDENCE_V1.md`.
- Review evidence: Archived implementation packet and closing summary, exact landed commit, live F02 placer/stamper/intent source, exported `story_room_sites` and `worldgen_reserved_regions`, current relevant tests, independent negative controls, data/route/cell fingerprints and any material gaps.
- Correction threshold: Divergent metadata and floor rectangles; duplicate authoritative anchor; unstable/ambiguous site IDs; invalid footprint changes accepted terrain or blocks a required route; false F15 persistence; B2/D2 scope violation; unverified or falsely green tests. Cosmetic follow-ups alone are non-blocking.
- Focused validation: Independently reconstruct a reserved story node and the resulting metadata/geometry join, verify absent/invalid candidate skip, shuffled-input stability and two-node collision isolation. Run `faction_story_sites_smoke.gd`, `procgen_intent_graph_smoke.gd`, `procgen_worldgen_shape_smoke.gd`, `procgen_ascent_style_smoke.gd`, `campaign_geography_semantic_site_smoke.gd`, any new ES-1 targeted test, changed-file validation, review pairing and `git diff --check`.
- Review focus: Confirm one physical site source, no parallel metadata authority, no new F15 locations, no claim-registry or `operator.gd` rebloat, and unmodified accepted route/geometry semantics. Check that optional 0-site result is legitimate and not disguised as placement success.
- Acceptance: Findings-first independent report covering A1–A5 and original failure negative controls; zero blocking defects or material gaps required for a PASS. Genuine blockers get a narrow correction/re-review via supported review workflow. Do not modify the landed implementation in reviewer context.
- Non-goals: Implement ES-2–ES-4, inspect uncommissioned pixel art, rework D2 authored claims, waive genuine dispatcher invariants, or alter the reviewed implementation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Begin from a fresh reviewer context after verified implementation landing; read the archived packet and exact source diff.
2. Reconstruct the actual selection/geometry/export path, independently falsify each A-series guarantee and examine safe no-op outcomes.
3. Record objective findings/receipts, use focused tests before broad sweeps, and route material defects through the existing bounded correction protocol, not a competing implementation.
4. If PASS, close the review and hand off ES-2 as the next **design/packet authoring** slice, without inventing visual approval.

## Next Handoff

- Next workstream: `none`
- Next packet state: `not authored; ES-2 to be scoped after ES-1 review`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Next action: On independent PASS, refine and separately authorize ES-2 physical Refused Passage plus two native WorldReadout interactions, then ES-3/ES-4.
- Blockers or open questions: Implementation must land and archive with valid evidence first.
