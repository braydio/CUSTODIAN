# REVIEW MAPPER SOURCE WRITE SAFETY V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-mapper-source-write-safety-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `mapper-source-write-safety-v1`
- Locks: `authored-level`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `mapper-source-write-safety-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/MAPPER_SOURCE_WRITE_SAFETY_V1.md`
- Reviewed main: `0bcd4c2455ff1ba7993b6891b98e0101ea23aab8`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify the landed result of disambiguate draft save, finishing geometry, and explicit production source apply across mapper scenes.
- Reviewed implementation acceptance: `A1-A3` in archived `MAPPER_SOURCE_WRITE_SAFETY_V1.md`.
- Review evidence: Pinned landed commit, independent negative event/assertion tests, source-file integrity/hash/digest checks, runtime/fixture verification and any material gaps.
- Correction threshold: Missing acceptance proof, data loss, unintended source mutation, input ownership regressions or false validation PASS block; non-blocking presentation improvements defer.
- Focused validation: `custodian/tools/validation/level_collision_poi_mapper_smoke.gd`, `custodian/tools/validation/awakening_collision_mapper_bridge_smoke.gd`, `custodian/tools/validation/carrow_interior_layout_mapper_smoke.gd`, changed-file and pairing checks, `git diff --check`.
- Review focus: Generic LevelCollisionPoiMapper Enter/U applies draft geometry/marker changes directly to target script/scene; Awakening Enter/U finishes chain and Ctrl+S writes ignored draft; Carrow Save is ignored draft only. AuthoredLevelMapper dirty reports only an active chain.
- Acceptance: Fresh-context findings-first receipt with each R0-NN classified by domain, evidence, affected acceptance, disposition and rationale. On blocking defects publish bounded correction plus paired re-review; do not edit reviewed implementation.
- Non-goals: Subjective human authoring preference, art/gameplay changes, direct fixes to reviewed code.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Start fresh independent reviewer context; load pinned implementation/archived packet and exact original A-series contract.
2. Independently run focused assertions, negative controls, source/draft hash checks and changed-file validation; reuse objective evidence before asking for imagery.
3. Record passed/findings; route correction-worthy items to dedicated correction/re-review workstream, not a patch inside review.
4. Do not mark user aesthetic/ergonomic approval complete on test evidence alone.

## Next Handoff
- Next workstream: `none`
- Next packet state: `dependency-gated successors per design/04_architecture/AUTHORED_MAPPER_EDITOR_RELIABILITY_V1.md`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Next action: On pass, allow existing dispatcher to unblock successors named in the mapper reliability design.
- Blockers or open questions: Review cannot execute until implementation is archived and present on main.
