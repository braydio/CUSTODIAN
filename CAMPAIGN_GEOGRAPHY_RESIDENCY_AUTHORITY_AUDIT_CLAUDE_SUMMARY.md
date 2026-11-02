# F15-A Campaign Geography and Residency Authority Audit

## Result

Created [`design/04_architecture/codebase_systems_audit/F15_GEOGRAPHY_RESIDENCY_AUTHORITY_EVIDENCE.md`](design/04_architecture/codebase_systems_audit/F15_GEOGRAPHY_RESIDENCY_AUTHORITY_EVIDENCE.md). The source snapshot was `6d66c1696596e2a8646a56e7de986dc70bbac02e`, proof date 2026-10-10 UTC.

The report establishes that CUSTODIAN has no durable production `DomainId + LocationId` mapping. Route and level residency is whole-scene staging, activation, caching and rollback; M6 unloads only presentation chunks; F14 reification still needs explicit real locality anchors. It traces the unmanaged ambient-spawn interleaving that could conflict with an abstract returning actor and proposes a population-slot reservation seam without implementing it.

Two fixed-seed contract generations were measured:

- Seed `12345`: `islands`, planet seed `17539747`, accepted attempt 3/4, map seed `3348751998`, size `224×192`, `8,900` reachable cells, 35/35 rooms, 3/3 ingress.
- Seed `54321`: `terran_wet`, planet seed `222523091`, accepted attempt 0/12, map seed `3249619757`, size `208×192`, `9,344` reachable cells, 36/36 rooms, 3/3 ingress.

A real Operator scene moved `439.33 px` in 180 physics ticks (3 nominal seconds) under a controlled unobstructed input frame: `146.44 px/s` simulation time. Map-wide axis travel estimates in the report are labeled projections, not traversed paths. Scout profile/class validation passed, but vehicle route traversal, a continuous two-locality route, landmark visibility across a seam, and physical-distance interpretation remain unproved.

Route lifecycle, procgen region frame, M6 distant-chunk eviction, F14 actor handoff, and Scout class focused smokes passed. The real ambient spawn smoke failed: after candidate generation, required Ritualant underground ingress resolution rejected the world; no camps or enemies activated. The report records this separately from F15 evidence completion. Three temporary probes and generated `.import` sidecars were removed after capturing their metrics.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: Ambient real-world spawn smoke failed on required authored ingress; generation measurements required multi-minute runs.
- Root cause / contributing factors: Generated-world ingress contract rejection plus smoke hierarchy assumptions and expensive candidate evaluation.
- Prevention / pipeline improvement: Add a focused metrics mode before activation and assign ingress correction to the existing procgen/level owner.
- Tooling / docs drift discovered: Existing ambient smoke does not emit accepted-world metrics and currently fails the required-ingress integration path.
- Follow-up: manual-follow-up
- What worked: Fixed seeds and a small controlled Operator probe provided reproducible map and movement evidence.

## Next Handoff

- Next workstream: `review-campaign-geography-residency-authority-audit`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Land/archive F15-A, then claim its paired post-land review from a fresh reviewer context.
- Blockers or open questions: D1–D7 architecture decisions are enumerated in the report; required-ingress generation needs its own owner follow-up.
