# REVIEW: PROCGEN AMBIENT REAL-WORLD SPAWN RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-ambient-real-world-spawn-recovery-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-ambient-real-world-spawn-recovery-v1`
- Locks: `procgen-generation, ambient-spawn-activation`
- Review: `none`
- Review target workstream: `procgen-ambient-real-world-spawn-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_AMBIENT_REAL_WORLD_SPAWN_RECOVERY_V1.md`
- Reviewed main: `41b33622c9b82bb39e86d71efd704b76d91a4bf5`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten or replace it.
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the exact ambient-spawn timeout was localized with stage evidence, corrected at its proven owner, and that a real generated world activates both required enemy families.
- Reviewed implementation acceptance: Reuse every acceptance claim from the archived implementation packet.
- Review evidence: Archived packet and summary; preserved pre-correction evidence at `75f38a8b17b845c901b50660bbc4083c51707e0b`; seed-specific attempt/stage report; before/after candidate+ingress decision fingerprints; generated-world markers/camps and actual actor population; NavigationSystem fixture contract proof; focused and complete changed-file reports.
- Correction threshold: Missing phase evidence; root-cause inference unsupported by timings; changed candidate ordering/RNG/rejection reasons/accepted-world fingerprint; weakened Ritualant ingress semantics; increased timeout; absent real actor population; fake/no-op navigation fixture; `ContractWorldLoader` implementation edits; or unrelated H5 edits require a bounded correction or planning handoff.
- Focused validation: Re-run exact seed `3348744079` under the unchanged 180-second timeout; inspect attempt-0..3 candidate/ingress fingerprints and prove accepted-world identity parity; verify the smoke uses the production NavigationSystem contract or a truthful equivalent; run the real-world ambient smoke, affected ProcGen/ingress/navigation/loader regressions, complete changed validation, and `git diff --check`.
- Review focus: Stage attribution; deterministic candidate/rejection/accepted-world parity; required-ingress semantics; measured speedup rather than policy relaxation; real NavigationSystem/walkability and spawn activation; `ContractWorldLoader` read-only discipline. H5 is not an ambient-spawn-activation prerequisite.
- Acceptance: Fresh-context findings-first review records a clean pass or bounded correction/re-review pair. Reviewer does not edit the implementation.
- Non-goals: No H5 implementation changes; no `ContractWorldLoader` implementation changes; no timeout increase; no unrelated Vaultwing changes; no general ProcGen refactor.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `hub-muster-continuity-port-deployment`
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: H5 must refresh against latest main after both independent spawn owner lanes land and pass review.
- Next action: Resume H5, synchronize current main, and require a complete green changed-file report before finish; then launch its independent review in fresh context.
- Blockers or open questions: none from H5 ownership. If the landed implementation changes loader/bootstrap behavior or candidate/ingress decisions rather than only measured evaluation cost + the smoke fixture, treat that as a blocking scope violation.


## Protected Post-Exit Recovery Authority

- Recovery trigger: The fresh reviewer already reran exact seed `3348744079` successfully on the landed implementation and observed both required enemy families, but the remaining packet-required validation could not start because the restricted Codex sandbox could not write the shared machine-wide Godot cache/lock namespace. The paired runner preserved the exact claimed branch, worktree and run as `post_exit_recovery`; this is infrastructure failure, not a review finding and not permission to mark the review passed.
- Existing run identity: `20261015T224943Z-5a721f81880e`
- Existing review worktree: `/home/braydenchaffee/Projects/.custodian-worktrees/review-procgen-ambient-real-world-spawn-recovery-v1-20261015T224946Z-9fd03b95314f`
- Existing evidence root: `.git/custodian-review-runs/review-procgen-ambient-real-world-spawn-recovery-v1/20261015T224943Z-5a721f81880e/`
- Recovery rule: Do not reclaim, recreate, or launch a second reviewer. Preserve the existing reviewer-authored findings/summary/receipt edits exactly. From the writable coordination context, execute only the missing environment-sensitive validation **against the preserved review worktree** using the ordinary shared Godot job budget/lock; do not use `--no-godot-lock`, do not modify reviewed implementation/runtime files, and do not substitute a different checkout.
- Required coordinator recovery tests: `procgen_encounter_cadence`, `ambient_actor_spawn_walkability`, `contract_world_ingress_spawn_clearance`, `contract_world_playable_region_spawn_validity`, `world_contract_prewarm`, plus the packet-required navigation/loader regression selected by the current manifest. The exact-seed `procgen_ambient_enemy_real_world_spawn` reviewer PASS remains required evidence and may be rerun coordinator-side if needed to produce one canonical green report; its manifest timeout stays 180 seconds.
- Closeout rule: Save a real green `custodian.validation.result.v1` report in the existing run evidence directory. Then use coordinator-owned bounded review closeout to verify the existing fresh reviewer receipt, archived target identity, exact implementation SHA `075025f41a6a7f6bafb6df13a816d54a23dc87af`, closing summary, and authorized review-only file delta before landing. Do not fabricate a receipt or accept a findings-only/incomplete reviewer state.
- Persistent project checkout: Leave the user's dirty/ahead/behind persistent checkout untouched. It is not the recovery execution surface.
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
