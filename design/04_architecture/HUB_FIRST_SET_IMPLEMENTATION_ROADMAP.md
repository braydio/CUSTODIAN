# HUB FIRST-SET IMPLEMENTATION ROADMAP

**Program ID:** `hub-first-set-first-campaign-loop`  
**Status:** active / H1 in progress  
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
  └─ HR1 review-hub-first-set-blockout-v1

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

| Slice | Workstream | Current state | Depends on | Refresh required before ready |
|---|---|---|---|---|
| H1 | `hub-first-set-blockout-v1-recovery-1` | in progress | none | sync current main + absorb H1 corrections |
| H2 | `hub-awakening-context-handoff` | blocked/manual | HR1 + Awakening handoff review | yes |
| H3 | `hub-forum-adjudication-contract-prewarm` | blocked/manual | HR2 | yes |
| H4 | `hub-crown-transfer-twin-solaria` | blocked/manual | HR2 | yes |
| H5 | `hub-muster-continuity-port-deployment` | blocked/manual | HR3 | yes |
| H6 | `hub-campaign-return` | blocked/manual | HR5 | yes, including current recovery/death-handoff state |
| H7 | `hub-first-set-integration-closeout` | blocked/manual | HR4 + HR6 | yes |

Refresh each downstream packet **in place** after its dependency review lands. Do not mint a `_v2` workstream because a predecessor chose different private helpers.

## H1 Corrections Locked Before Landing

- Sepulcher Gardens has two separated 4x8 Forum connectors: north `Rect2i(44,68,4,8)`, south `Rect2i(44,85,4,8)`.
- H1 must prove a real circulation loop, not enter/return through one neck.
- Mandatory routes need Operator-clearance proof derived from the live collision shape and boundary rails in addition to raw grid connectivity.
- `Spawn_CampaignReturn=(2592,-3008)` is the Continuity Port west return bay.
- H1 must sync current main and rerun focused + changed validation before human overview approval/landing.

## Program End

Complete only when default boot still enters Awakening; reviewed completion enters Hub at Spawn_SouthReach; explicit Dais acceptance starts exactly one accepted scenario/seed/bootstrap generation; optional Twin roundtrip preserves Hub state; Port deploys only READY and consumes the same prewarmed map/scenario; one CampaignOutcome mutates HubState once before campaign teardown; the Operator returns at Spawn_CampaignReturn; and H7 proves the entire loop with one active world authority.

## Adjacent Recovery Program

Persistent recovery/armament registration is adjacent, not a blanket dependency. H6 must re-inspect it. If death-handoff work has landed, H6 consumes the same `WorldSimulationRuntime.resolve_campaign()` / `campaign_resolved` authority rather than creating a duplicate failure path.

## Documentation Drift Rule

Do not restore Field Terminal as the embodied destination. Preserve Forum adjudication → Muster Court → ordinary Continuity Port. Terminal capability may remain as a witness/status interface. Do not describe later slices as live before their reviews land.

## Program Position

**Current:** H1 correction/sync before human topology review.  
**Next:** land/review H1 and the Awakening completion seam, then refresh H2.  
**Finish:** HR7 passes the complete first-campaign-loop proof.
