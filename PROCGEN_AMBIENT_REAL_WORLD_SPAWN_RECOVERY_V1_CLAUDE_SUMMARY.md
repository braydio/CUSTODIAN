# ProcGen Ambient Real-World Spawn Recovery V1

Workstream: `procgen-ambient-real-world-spawn-recovery-v1`

## Outcome

Implemented and validated the ambient real-world spawn recovery. The exact-seed smoke completes under its unchanged 180-second bound, exercises the production `NavigationSystem` contract, and spawns both required enemy families. The streaming worktree was not accessed or modified.

## Evidence

- Preserved baseline evidence: clean `origin/main@2b0fc9e2db367a9c2372ee54ba2b82e9de9398cf` timed out at 180.05s. The earlier controlled run recorded attempts 0–2 exhausting 65 candidates and attempt 3 accepting after about 229.7s total; this pre-correction evidence remains at commit `75f38a8b17b845c901b50660bbc4083c51707e0b`.
- Measured repeated resolver work and cached immutable edge candidates, tile predicates, corridor results, and authored-fallback rankings within one resolver instance. The exact-seed post-change attempt loop completed in 92.5s and final promotion in 33.5s. Attempt decision fingerprints match the pre-change values: `487025759`, `714827931`, and `2976889989` for attempts 0–2; attempt 3 accepted with semantic fingerprint `948758187` and world fingerprint `1640760788`.
- The exact seed `3348744079` completed under a 180-second external bound with `procgen_ambient_enemy_real_world_spawn_smoke: PASS`; output reported 8 encounters, 8 markers, 8 camps, 5 active enemies, including 1 `EnemyGrunt` and 1 `PursuitFrame`. The real NavigationSystem snapshot reported initialized=true, 9,951 authoritative floor cells, and 622 navigation points.
- Repaired only the smoke fixture: it now mounts the real production `NavigationSystem` and ContractWorldLoader at their configured paths before generation/activation. `ContractWorldLoader` remains unchanged/read-only.
- `python3 tools/validation/run_validation.py --changed --base origin/main --json`: PASS, 10/10 selected tests, full changed-file coverage. Focused cadence, ambient walkability, ingress clearance, playable-region validity, materializer parity, distant-chunk navigation rebuild, patrol navigation, and world-contract prewarm checks also passed. Known exit resource/ObjectDB warnings remain in existing ProcGen tests; no validation test failed.
- `git diff --check`: PASS. Three pre-existing/unrelated generated `.uid` files remain untracked and are excluded from the task.

## Ownership and Next Step

The live refreshed packet assigns `procgen-generation` and `ambient-spawn-activation` to this recovery; H5 does not own the latter. The implementation is ready to finish through the normal workstream lifecycle and then enter its fresh-context paired review. No paired review was performed in this implementation session.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first resolver cache reduced repeated sorting but left repeated candidate ranking expensive; an intermediate fallback ranking also differed from the original empty-level-data scan and was corrected before final acceptance.
- Root cause / contributing factors: Candidate fallback repeatedly scanned and rescored the full edge list, while the legacy path used an empty level-data source for fallback ordering.
- Prevention / pipeline improvement: Preserve unusual legacy inputs as part of deterministic contracts and fingerprint candidate decisions before/after optimization.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Exact attempt fingerprints and stage timers localized repeated work; changed-file coverage exercised the full integration path.

## Next Handoff
- Next workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Finish and land this implementation packet, then run its paired review in a fresh context.
- Blockers or open questions: none; reviewer should falsify exact attempt fingerprints, 180-second completion, and real navigation/actor-spawn evidence.
