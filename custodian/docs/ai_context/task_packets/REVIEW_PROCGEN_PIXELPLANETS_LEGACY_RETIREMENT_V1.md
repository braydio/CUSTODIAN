# REVIEW PROCGEN PIXELPLANETS LEGACY RETIREMENT V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-procgen-pixelplanets-legacy-retirement-v1
- Category: world-procgen
- Kind: review
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: auto
- Priority: P1
- Depends on: procgen-pixelplanets-legacy-retirement-v1
- Locks: procgen-planet-contract
- Review: none
- Review target workstream: procgen-pixelplanets-legacy-retirement-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/PROCGEN_PIXELPLANETS_LEGACY_RETIREMENT_V1.md
- Reviewed main: 0d41ea40266faa0f3a5ccb8faf251fd65cc883e4
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, runtime
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify the PixelPlanets migration removes only the obsolete scene dependency while preserving contract/world-profile determinism and its terminal presentation.
- Reviewed implementation acceptance: No tracked custodian/Planets symlink or live res://Planets resource path; fixed-seed profile, planet key/seed, and map-seed parity with original baseline; all six planet profile values preserved; both contract creation modes and seeded 3D globe work with the legacy directory absent.
- Review evidence: Archived implementation packet and closing summary, exact landed source diff, before/after fixed-seed baseline and targeted Godot test reports, changed-file validation with complete coverage, symlink removal evidence, and preserved original review branch/worktree/run hashes where relevant.
- Correction threshold: Any regression in deterministic planet key/seed, weather/biome/world-profile semantics, runtime loading or planet contract consumers, hidden stale scene reference, deletion outside the exact symlink boundary, invented success evidence, or material validation gap blocks PASS.
- Focused validation: Independently reconstruct initial six sorted keys and planet profiles from reviewed baseline; repeat representative fixed seeds against landed implementation, validate both contract generation paths, run the focused no-Planets-resource and terminal globe/contract smoke tests, verify tracked symlink removal, relevant static reference scans, git diff --check and canonical changed-file validation.
- Review focus: Exact resource/symlink deletion boundary; no traversal of symlinks or external repository; seeded RNG parity; world-profile and map generation preservation; scene-tree and consumer migration; terminal preview continuity; current documentation truth; untouched protected declared-documentation review claim and artifacts.
- Acceptance: Findings-first independent reviewer outcome. PASS requires zero blocking defects, zero material evidence gaps and genuine objective validation; otherwise record stable cycle-scoped R0-NN findings and use the bounded correction/re-review lifecycle. A review PASS is separate from mere implementation landing.
- Non-goals: Implementing new source behavior, editing the reviewed implementation in the review context, adding new planet visuals, touching Asset V2, changing locks, parking claims, or cleaning old review worktrees.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

1. Start a genuine fresh reviewer context only after the implementation is archived complete and exact dispatcher eligibility is established.
2. Inspect the original reviewed-main code and landed implementation diff before trusting new test results.
3. Verify all six planet keys and exact world-profile semantics, including sorted seed selection, RNG progression and terminal globe seed use.
4. Run focused regression and smoke checks without PixelPlanets installed; reject null/fake scene substitutes and unowned resource paths.
5. Inspect actual removal of the symlink only, no other checkout/asset deletion, and confirm protected review evidence was not altered.
6. Emit the canonical findings-first review outcome and receipt or concrete findings; finish through the ordinary paired-review lifecycle.

## Next Handoff

- Next workstream: none
- Next packet state: n/a
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2
- Refresh reason: none
- Next action: On genuine accepted PASS, mark this retirement complete; do not resume the unrelated held declared-documentation review as an implied side effect.
- Blockers or open questions: Original protected review remains independent and is not required for this migration.
