# PERSISTENT RECOVERY IMPLEMENTATION ROADMAP

**Project:** CUSTODIAN  
**Program ID:** `persistent-recovery-armament-registration`  
**Status:** planned / first packet ready  
**Priority:** P1  
**Reviewed main:** `22539b8d602cfbccb5399277ad302dd756824710`  
**Last Updated:** 2026-10-01  
**Design authority:** `design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`

## Purpose

Implement the persistent recovery and armament-registration design as a bounded
series of independently landable runtime slices.

This roadmap is the implementation tracker. The design authority above owns the
player-facing and lore contract; packets own one executable slice at a time.

## Expected Packet Count

**Expected implementation task packets: 8.**

That count is intentional. It separates the four live authority boundaries
already present in the repository:

- Operator death handling;
- campaign/session outcome and reintegration;
- InventoryManager/equipment persistence;
- fabrication/infrastructure recovery services.

Do not inflate the series with one-file packets, and do not collapse unrelated
owners into a mega-packet merely to reduce the count. Correction/review packets
created by actual findings are not part of the expected 8 implementation
packets.

## Program Beginning — Live State Before R1

At program entry:

- `custodian/game/actors/operator/operator.gd::_handle_death()` directly calls
  `/root/GameState.lose_life(...)`.
- `GameState.total_lives = 1`; `lose_life()` therefore routes ordinary
  Custodian death directly into the global game-over modal.
- `WorldSimulationRuntime` already owns the active `CampaignSession` and
  exposes `resolve_campaign(...)`; `CampaignSession.resolve_once(...)`
  already guarantees exactly-once outcome production, but Operator death is not
  connected to that campaign outcome seam.
- `InventoryManager` persists flat carried items and the current sidearm/relic
  equipment slots. It does not yet represent field-acquired vs recovered vs
  registered armament state, recovered-armory caps, or designation assignment
  caps.
- Physical fabrication, Ready Builds, `InfrastructureRegistry`, and the Field
  Fabricator exist, but recovery Crèches/Moorings are not runtime services.
- No runtime Campaign Flow / World Transition implementation currently closes
  the full Campaign -> outcome -> return/reintegration loop described by the
  architecture docs.

This is the start line. Do not describe later slices as already implemented
merely because their design is locked.

## Program End — Required State After R8

The program is complete only when all of the following are true:

1. Ordinary Custodian body death is no longer a one-life global Game Over.
2. Without valid local recovery, death resolves the campaign truthfully and
   returns the designation through Post recovery/reintegration.
3. With valid local recovery, the active campaign continues from the local
   recovery point without rewinding completed/failed world state.
4. Weapons can exist as **field-acquired**, **recovered**, and **registered**
   equipment with explicit lifetime semantics.
5. Registered equipment is restored/provisioned to the recovered Custodian;
   any persisted previous registered field instance is non-operational rather
   than a usable duplicate.
6. Unregistered equipment is not re-provisioned and can remain a physical
   retrieval target when the campaign persists.
7. Recovered Armory capacity, deployment capacity, and designation registration
   capacity remain separate limits.
8. Existing local Crèches can provide recovery; fabricated Field Recovery
   Crèches and the lighter Designation Mooring use the real fabrication /
   infrastructure authorities rather than a parallel checkpoint system.
9. Registration/capacity progression comes from recovered institutional
   capability, not character levels.
10. Legacy `lives_remaining` / `total_lives` is no longer the authority for
    ordinary Custodian death, while true macro terminal failures still use the
    game-over path.
11. Focused and end-to-end validation proves the complete loop, and runtime /
    design / AI-context docs agree on the landed behavior.

That is the finish line.

## Packet Series

| Code | Workstream | Slice | Status | Depends on |
| --- | --- | --- | --- | --- |
| R1 | `custodian-death-handoff-foundation-recovery-1` | Operator death -> campaign outcome handoff, with current Game Over retained only as a compatibility fallback | **complete** | none |
| R2 | `custodian-post-recovery-reintegration` | Replace the R1 compatibility fallback with Post recovery and return/reintegration after campaign-ending death | planned | R1 |
| R3 | `armament-persistence-registration-core` | Field-acquired / recovered / registered armament data, Recovered Armory ownership, registration records, and three-capacity contract | planned | R2 |
| R4 | `armament-death-site-recovery-semantics` | Registered re-provisioning, persisted inoperable prior instances, and unregistered death-site retrieval semantics | planned | R3 |
| R5 | `local-creche-recovery` | Existing/restored local Crèche recovery path that continues the same campaign without rewind | planned | R2 + R4 |
| R6 | `field-recovery-infrastructure` | Fabricated Field Recovery Crèche plus Designation Mooring through live fabrication, placement, power, and InfrastructureRegistry contracts | planned | R5 |
| R7 | `designation-armament-capacity-progression` | Registration/storage/deployment limits, institutional capacity unlocks, registration workflow, and player-facing Armory/Equipment integration | planned | R3 + R6 |
| R8 | `persistent-recovery-convergence-hardening` | End-to-end convergence, legacy lives-path retirement for Custodian death, full regression evidence, and final roadmap/docs closeout | planned | R4 + R5 + R6 + R7 |

## Dependency Shape

```text
R1 death handoff
 └─ R2 Post recovery/reintegration
     ├─ R3 armament persistence/registration
     │   └─ R4 death-site equipment semantics
     │       └──────────────┐
     └──────────────────┐   │
                        ▼   ▼
                    R5 local Crèche
                        │
                        ▼
                    R6 field Crèche + Mooring
                        │
              R3 ───────┤
                        ▼
                    R7 capacity/progression/UI
                        │
          R4 + R5 + R6 ─┤
                        ▼
                    R8 convergence/hardening
```

The graph is intentionally mostly serial because later equipment and local
recovery behavior depends on a truthful death/reintegration spine. R3 can begin
after R2 without waiting for local Crèche fabrication.

## Slice Contracts

### R1 — Custodian Death Handoff Foundation

**Goal:** remove macro death consequence ownership from the Operator actor and
connect one lethal Operator event to the already-live exactly-once
`CampaignSession -> CampaignOutcome` seam.

**Important transitional behavior:** R1 does **not** implement recovery yet.
After the campaign outcome is emitted, the existing game-over UX remains as a
temporary compatibility fallback so the player is never left in a dead,
unrecoverable runtime state.

**Exit:** Operator no longer calls `GameState.lose_life()`; one lethal event
emits one death handoff, resolves the active campaign once, then reaches the
temporary compatibility fallback. Facility/siege terminal-failure behavior is
unchanged.

**R1 completion evidence (2026-10-04):** `operator_death_campaign_handoff_smoke.gd`
passes structured context, one outcome, reentrant suppression, outcome-before-fallback
ordering, unchanged legacy-life count, no-session and resolved/unstarted-session
fallbacks, and no-revive behavior. `game_over_flow_smoke.gd` and
`campaign_outcome_exactly_once_smoke.gd` both pass. The changed-file closeout
summary records final selected/passed/skipped counts. The recovery workstream
lands this evidence through `workstream.py finish` to `origin/main`.

Packet:
`custodian/docs/ai_context/task_packets/CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md`

### R2 — Post Recovery / Reintegration

Replace R1's temporary global-game-over fallback for ordinary Custodian death.

This slice owns the minimum truthful Campaign failure -> outcome application ->
return/reintegration path required by the active architecture. Re-derive the
live transition seam at packet-authoring time; do not invent a second persistent
world-transition authority if the Campaign Flow / World Transition migration
has advanced on main.

**Exit:** campaign-ending Custodian death returns through the Post recovery
surface and ordinary control resumes without using the global Game Over modal.

### R3 — Armament Persistence + Registration Core

Extend the live inventory/equipment authority with the minimum durable model
for:

- field-acquired armament;
- recovered armament;
- registered designation assignments;
- Recovered Armory storage;
- deployment capacity;
- registration capacity.

Preserve current P-9 equip/unequip and carried-item compatibility while
migrating ownership deliberately.

**Exit:** runtime state and save/restore boundaries can distinguish all three
persistence states and three capacity types without implementing death-site
replacement behavior yet.

### R4 — Death-Site Equipment Semantics

Apply the registration model to death/recovery:

- registered loadout is available to the recovered Custodian;
- any persisted previous registered field instance is rendered unusable and
  cannot create an operational duplicate;
- unregistered carried weapons are not provisioned by recovery and may remain
  retrievable when the campaign world persists.

Keep player-facing inspection restrained. Do not expose continuity internals.

**Exit:** repeated local recovery cannot duplicate an operational registered
weapon, while unregistered retrieval remains physically meaningful.

### R5 — Existing Local Crèche Recovery

Introduce the first campaign-preserving local recovery source using existing or
repairable Crèche infrastructure.

This is not a save-point rewind. Mission/world state remains authoritative.

**Exit:** when a valid local Crèche exists, one Custodian death can recover
locally and continue the same unresolved campaign; without one, R2 Post
recovery remains authoritative.

### R6 — Field Recovery Infrastructure

Integrate:

- fabricated Field Recovery Crèche;
- Designation Mooring.

Use live `FabPipeline`, `BuildInventory`, placement, power/service, and
`InfrastructureRegistry` boundaries. Do not create a parallel build economy.

**Exit:** recovery infrastructure can be deliberately established at runtime,
has physical/service constraints, and participates in capture/restore at the
same persistence boundary as other infrastructure.

### R7 — Capacity Progression + Player Workflow

Implement the long-term armament loop:

- Recovered Armory caps;
- designation assignment caps by category;
- deployment loadout limits;
- institutional unlock items/capabilities that expand those limits;
- Post registration/assignment interaction;
- restrained Equipment/Ledger presentation.

Do not use character levels or one universal backpack number.

**Exit:** a player can recover more equipment than can be registered, choose
what the designation guarantees, unlock new institutional capacity, and deploy
within the intended starting/expanded loadout contract.

### R8 — Convergence + Hardening

Final integration packet.

Own only closure work proven necessary after R1-R7:

- retire ordinary Custodian dependency on `total_lives` /
  `lives_remaining`;
- preserve true facility/archive/terminal Game Over triggers;
- run cross-system recovery, equipment, infrastructure, save/restore, and
  campaign outcome regression checks;
- resolve docs/context drift;
- update this roadmap with final evidence.

**Exit:** every item in **Program End** is proven against live runtime.

## Roadmap Maintenance Contract

Every implementation packet in this program must update this roadmap in the same
landed change that completes its slice.

At closeout:

1. change its row to the truthful state;
2. record landed main SHA and high-signal validation evidence below the slice;
3. update **Current Program Position**;
4. re-derive the next planned packet against current main before promoting it
   to `ready`;
5. preserve the expected eight-packet boundary unless live evidence proves a
   slice must split or merge; if that happens, record the reason here rather
   than silently changing the count;
6. do not mark the program complete until R8 proves the **Program End** list.

## Current Program Position

**Current slice:** R2 Post Recovery / Reintegration
**State:** R1 is implemented and its focused acceptance checks pass. Operator death now resolves the live CampaignSession exactly once before the transitional Game Over fallback; local and Post recovery remain unimplemented.
**Next gate:** architecture-sensitive refresh of R2 against the landed R1 binding, current Campaign/Hub outcome application, and current return lifecycle; do not promote a packet to ready until that live surface is re-derived.
**Expected remaining implementation packets after R1:** 7.
