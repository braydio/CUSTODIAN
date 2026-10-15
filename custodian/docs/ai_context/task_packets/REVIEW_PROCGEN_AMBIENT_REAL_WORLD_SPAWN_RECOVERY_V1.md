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
