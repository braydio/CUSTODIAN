# HUB FIRST-SET IMPLEMENTATION ROADMAP

**Program ID:** `hub-first-set-first-campaign-loop`  
**Status:** active / autonomous dependency queue  
**Priority:** P1  
**Reviewed main:** `5bb137655670`  
**Last Updated:** 2026-10-03  
**Design authority:** `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`

## Purpose

Track the seven implementation slices that turn the post-Awakening first-set geometry into the first complete campaign loop:

```text
Awakening
→ persistent Hub / South Reach
→ Forum adjudication + Contract prewarm
→ optional Twin Solaria branch
→ Muster / Continuity Port
→ procgen CampaignRegion
→ CampaignOutcome
→ persistent Hub return
```

## Expected Packet Count

**7 implementation packets**, H1-H7. Each substantial runtime slice has one paired post-land review. Review/correction packets are not counted in the seven.

## Dependency Graph

```text
H1 hub-first-set-blockout-v1-recovery-1
  └─ HR1 review-hub-first-set-blockout-v1 (complete)

awakening-handoff-readiness-art-convergence-v1-r1
  └─ review-awakening-handoff-readiness-art-convergence-v1

HR1 + Awakening handoff review
  └─ H2 hub-awakening-context-handoff
      └─ HR2
          ├─ H3 hub-forum-adjudication-contract-prewarm
          │   └─ HR3
          │       └─ H5 hub-muster-continuity-port-deployment
          │           └─ HR5
          │               └─ H6 hub-campaign-return
          │                   └─ HR6
          └─ H4 hub-crown-transfer-twin-solaria
              └─ HR4

HR4 + HR6
  └─ H7 hub-first-set-integration-closeout
      └─ HR7
```

H3 and H4 intentionally run in parallel after HR2. H5 does not wait for Twin because ordinary Continuity Port deployment is independent of the optional Crown branch.

## Packet Series

| Slice | Workstream | Packet state | Depends on | Claim-time refresh |
|---|---|---|---|---|
| H1 | `hub-first-set-blockout-v1-recovery-1` | complete/landed; human overview approved; paired review complete | none | H1 and HR1 archived; donor archive remains reachable |
| H2 | `hub-awakening-context-handoff` | implementation and paired review complete/landed | HR1 + Awakening handoff review (complete) | execution-agent |
| H3 | `hub-forum-adjudication-contract-prewarm` | implementation and HR3 complete/landed | HR2 | execution-agent |
| H4 | `hub-crown-transfer-twin-solaria` | implementation and HR4 complete/landed | HR2 | execution-agent |
| H5 | `hub-muster-continuity-port-deployment` | implementation complete/landing; HR5 follows landing | HR3 | execution-agent |
| H6 | `hub-campaign-return` | ready/auto, dependency-gated | HR5 | execution-agent, including current recovery/death-handoff state |
| H7 | `hub-first-set-integration-closeout` | ready/auto, dependency-gated | HR4 + HR6 | execution-agent |

Downstream packets stay `ready/auto` from authoring onward. The dispatcher keeps them non-claimable while dependencies are incomplete, then automatically exposes them when those dependencies archive `complete`. At claim time, the execution agent reconstructs current public seams from live `main` plus predecessor implementation/review evidence and reconciles private-helper drift inside the existing packet. Do not mint a `_v2` workstream merely because a predecessor chose different private helpers.

## H1 Corrections Completed Before Landing

- Sepulcher Gardens has two separated 4x8 Forum connectors: north `Rect2i(44,68,4,8)`, south `Rect2i(44,85,4,8)`.
- H1 proves a real circulation loop, not enter/return through one neck.
- Mandatory routes pass Operator-clearance proof derived from the live collision shape and boundary rails in addition to raw grid connectivity.
- `Spawn_CampaignReturn=(2592,-3008)` is the Continuity Port west return bay.
- H1 recovery started from current main without merging the retired donor branch, passed focused + changed validation, received human overview approval, and retired the old-H1 branch/worktree/diagnostic residue. The donor commit remains available through its archive tag.

H1 evidence: 13,142 walkable cells; 52 merged boundary rails; 14 markers; 12,160 cells after 25px live-Operator/boundary-rail clearance; connector-restricted loop passed in raw and clearance occupancy. Human overview: `reports/hub_first_set_blockout/overview.png`, approved 2026-10-05.

## Program End

Complete only when default boot still enters Awakening; reviewed completion enters Hub at Spawn_SouthReach; explicit Dais acceptance starts exactly one accepted scenario/seed/bootstrap generation; optional Twin roundtrip preserves Hub state; Port deploys only READY and consumes the same prewarmed map/scenario; one CampaignOutcome mutates HubState once before campaign teardown; the Operator returns at Spawn_CampaignReturn; and H7 proves the entire loop with one active world authority.

## Adjacent Recovery Program

Persistent recovery/armament registration is adjacent, not a blanket dependency. H6 must re-inspect it. If death-handoff work has landed, H6 consumes the same `WorldSimulationRuntime.resolve_campaign()` / `campaign_resolved` authority rather than creating a duplicate failure path.

## Documentation Drift Rule

Do not restore Field Terminal as the embodied destination. Preserve Forum adjudication → Muster Court → ordinary Continuity Port. Terminal capability may remain as a witness/status interface. Do not describe later slices as live before their reviews land.

## Program Position

**Current:** H1/HR1 through H4/HR4 are complete. H5 implements the ordinary Port deployment path; HR5 is its paired fresh-context review. H6 waits on HR5; H7 waits on HR4 and HR6.
**Next:** Fresh-context review of `hub-muster-continuity-port-deployment`.
**Finish:** HR7 passes the complete first-campaign-loop proof.
