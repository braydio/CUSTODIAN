# NON-PLAYER ACTOR RUNTIME ARCHITECTURE

**Status:** active architecture authority and implementation tracker  
**Reviewed baseline:** `main@02ca0025b8` (2026-10-01)  
**Program goal:** converge CUSTODIAN's autonomous non-player runtime around shared compositional actor contracts without creating a universal NPC base class or turning `enemy.gd` into the parent of unrelated actor families.

## Architecture Lock

CUSTODIAN supports **six non-player actor families**. The family describes behavior/lifecycle shape. It does **not** encode whether the actor currently likes the Operator.

1. **Standard combat agents** — conventional mobile combatants such as Grunt, Marine, Savage, Pursuit Frame, Fast/Heavy Drone, and other ordinary `Enemy` actors.
2. **Bespoke encounter / boss agents** — authored encounter actors whose phase/resolution logic is encounter-owned, such as the Forlorn Ritualant and future bosses/elites.
3. **Autonomous fauna / ambient creatures** — species-local autonomous creatures such as Baby Opossum and Common Vaultwing.
4. **Commanded allies / companions** — actors driven by follow/hold/recall/assist or bonded-command policy, such as Combat Drone, Allied Infantry Droid, and a commanded bonded Vaultwing.
5. **Neutral / social NPCs** — dialogue/schedule/interaction-first actors such as future Drifters, survivors, merchants, and non-hostile encounter characters.
6. **Static autonomous agents** — autonomous target-acquiring actors without CharacterBody locomotion requirements, such as Defense Turrets and future sentries/deployables.

### Not actor families

- `hostile`, `neutral`, and `operator_allied` are **allegiance states**, owned by the relationship/targetability foundation.
- melee/ranged/flying are **capabilities or movement/ability policies**.
- Grunt/Marine/Savage/Shrumb/Drone are **archetypes**, not architecture families.
- bonded is a **state/capability** of the same creature instance, not a replacement class.
- boss/elite is encounter/archetype policy. Do not create a universal `BossActor`.
- vehicles, ordinary props, doors, relays, storage, terminals, and passive world structures are adjacent systems, not part of this non-player actor refactor.

## Shared Substrate

The target is composition, not an inheritance pyramid.

Shared non-player actors may consume only the contracts they need:

- allegiance and relationship queries;
- targetability;
- health/damage/death contracts;
- combat target qualification;
- actor identity/diagnostic surfaces;
- perception and blackboard services where applicable; shared sensory evaluation routes through `design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md` once landed, while actor/species behavior remains local;
- locomotion/movement intent where applicable;
- actor-local ability execution;
- semantic presentation;
- interaction/dialogue;
- owner/command policy;
- loot/corpse policy.

No actor is required to implement every capability.

`ActorAllegianceComponent` and `ActorRelationshipResolver` remain the current relationship/targetability foundation. Species/archetype behavior remains local to the actor/controller. A future shared service must be introduced only after at least two real consumers demonstrate the same contract.

## Standard Combat Agent Boundary

`custodian/game/actors/enemies/enemy.gd` remains the standard mobile combat-agent coordinator and compatibility surface. It is **not** the universal NPC base.

At the reviewed baseline it is approximately **4,958 lines** and still owns or hosts:

- shared combat/locomotion integration;
- Marine Dash phase/timer/target/reset state;
- Savage pounce state;
- Savage two-hit chain state;
- generic melee execution;
- reaction/parry/critical state;
- corpse/loot lifecycle;
- legacy presentation fallbacks;
- behavior-state-machine integration and disabled-BSM fallback;
- shared combat observability/services.

Existing extracted authorities prove the intended shape:

- `EnemyBehaviorStateMachine` owns strategic state and movement goals;
- perception/objective/blackboard/profile components own their bounded concerns;
- `EnemyAnimationSet` + `EnemyPresentationController` own semantic presentation;
- `GruntFalconPunch` owns the complete Falcon phase/timer/cadence/contact/telemetry machine while `Enemy` supplies narrow shared services.

The next extractions should follow that same rule: move a complete stateful authority, keep a narrow actor integration seam, preserve behavior equivalence, then delete the old duplicate state/path.

## Family Matrix

| Family | Live proof/examples | Shared substrate expected | Family-local authority |
| --- | --- | --- | --- |
| Standard combat agent | `Enemy`, Grunt, Marine, Savage, Pursuit Frame, Fast/Heavy Drone | allegiance/targeting, health, locomotion, perception, combat, abilities, reactions, presentation, loot | archetype policy + actor-local abilities |
| Bespoke encounter / boss | Forlorn Ritualant | relationship/targetability, health/damage, presentation, optional shared combat services | encounter phases, dialogue/event resolution, bespoke win/loss state |
| Autonomous fauna / ambient | Vaultwing, Baby Opossum | relationship/targetability, health where relevant, semantic presentation, optional combat | species behavior/controller, altitude/perch/interest/bond state |
| Commanded allies / companions | Combat Drone, Allied Infantry Droid; bonded Vaultwing later | relationship/targeting, health, command target qualification, optional combat | follow/hold/recall/assist/owner policy |
| Neutral / social NPC | Forlorn pre-hostility as partial proof; future Drifters/survivors | relationship/targetability when needed, interaction, presentation, optional health | dialogue, schedule/local behavior, encounter transition policy |
| Static autonomous agent | Defense Turret | relationship/targeting, health, abilities/fire control | power/integrity, static acquisition/fire policy; no locomotion contract |

## Migration Rules

1. **One mechanic, one authority.** A migrated mechanic cannot retain parallel mutable state in the old actor.
2. **Coordinator, not god file.** `enemy.gd` may orchestrate and provide shared services; large state machines leave it.
3. **No universal NPC base.** Shared contracts are compositional and opt-in.
4. **Allegiance is orthogonal.** Never model enemy/ally/neutral as separate inheritance families.
5. **Behavior equivalence first.** Extractions preserve current gameplay/tuning unless a separate packet explicitly changes design.
6. **Typed tuning where practical.** Stateful abilities should move tunable values into focused config/resources rather than leaving archetype-specific exports on `Enemy`.
7. **Delete the old path.** Compatibility bridges are temporary and must have an exit condition.
8. **Validation ownership follows code ownership.** When a subsystem leaves `enemy.gd`, update focused validation ownership so future edits do not select giant unrelated suites.
9. **Do not force cross-family convergence early.** A shared abstraction is justified only after real repeated contracts exist.
10. **Architecture closure is measured.** Track extracted authorities, remaining `enemy.gd` responsibilities, direct private callers, legacy group/relationship fallbacks, and focused test ownership.

## Program Roadmap

Expected program size: **11 implementation packets**. The exact later packet boundary may tighten after each predecessor lands; do not freeze speculative private APIs now.

| Slice | Workstream | Scope | Status |
| --- | --- | --- | --- |
| NPA-1 | `enemy-marine-dash-ability-extraction` | Extract complete Marine Dash authority + typed tuning from `enemy.gd` | **packet authored / ready** |
| NPA-2 | `enemy-savage-pounce-ability-extraction` | Extract Savage pounce authority using the landed ability seam | **packet authored / dependency-gated** |
| NPA-3 | `enemy-savage-chain-ability-extraction` | Extract Savage two-hit chain authority | **packet authored / dependency-gated** |
| NPA-4 | TBD after NPA-3 | Extract ordinary standard-enemy melee execution/cadence authority | planned |
| NPA-5 | TBD | Extract shared enemy reaction/posture/parry-critical authority where a coherent boundary exists | planned |
| NPA-6 | TBD | Extract enemy death/corpse/loot lifecycle from combat coordinator | planned |
| NPA-7 | TBD | Converge commanded allies/companions on shared relationship/targeting/identity contracts without inheriting `Enemy` | planned |
| NPA-8 | TBD | Converge ambient/fauna and bonded-command seams, consuming the shared stealth-perception observation contract if landed, without moving species behavior into enemy AI | planned |
| NPA-9 | TBD | Define encounter/social NPC shared capability seams using Forlorn Ritualant as proof; preserve encounter-local phase authority | planned |
| NPA-10 | TBD | Converge static autonomous agents (Defense Turret/sentries) on shared non-locomotion combat/relationship contracts | planned |
| NPA-11 | TBD | Remove proven compatibility residue, audit legacy group fallbacks/private callers, close architecture docs/validation | planned |

Only NPA-1 through NPA-3 are authored now because their current authority and behavior are already concrete.\n\nCross-program dependency note: the stealth-perception foundation is not an NPA slice. It is a cross-cutting sensory substrate. NPA-8 must reuse it if available rather than inventing Vaultwing-only hearing or importing Enemy behavior policy. Author NPA-4+ against landed live main so the program learns from the actual extracted seams rather than inventing a generic actor framework up front.

## Measured Baseline

Reviewed `main@02ca0025b8`:

- `enemy.gd`: ~4,958 lines.
- `combat_drone.gd`: ~656 lines and independent `CharacterBody2D` ally runtime.
- `vaultwing.gd`: ~252 lines with species-local behavior controller, presentation, allegiance, and bond state.
- `forlorn_ritualant_npc.gd`: ~385 lines with encounter-local phases and combat.
- `turret.gd`: ~441 lines, extends `Damageable`, uses `ActorRelationshipResolver`, and has no locomotion requirement.
- Marine/Savage phase machines still live in `enemy.gd`.
- Falcon Punch is already extracted and is the reference actor-local ability seam.
- The active relationship architecture explicitly says it is **not** a universal NPC base class.

## Closure Criteria

This program is complete only when:

- the six-family taxonomy remains explicit and no universal non-player superclass has become a new god object;
- `enemy.gd` is a standard combat-agent coordinator with archetype-special phase machines removed;
- generic combat/reaction/loot authorities have coherent owners rather than parallel state;
- allies, fauna, encounter/social actors, and static autonomous agents use shared relationship/targetability/core contracts where appropriate without inheriting unrelated behavior;
- legacy `enemy`/`ally` groups remain only compatibility/indexing where still intentionally required, with relationship queries using the shared resolver;
- direct external calls into actor-private ability phase methods are eliminated;
- validation ownership follows the extracted modules;
- active architecture/current-state/index docs describe the landed runtime truth.

## Documentation Drift Noted At Program Start

- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md` correctly describes current Enemy ownership but does not yet name the six-family target; this tracker becomes the durable target authority.
- Legacy completed Marine packets `ENEMY_MARINE_TACTICAL_DASH_V2.md` and `ENEMY_MARINE_DASH_TUNING.md` still sit in the active task-packet directory even though they are historical/complete. Do not use them as current migration authority; archive cleanup is deferred unless a packet lifecycle pass proves it safe.
- `ACTOR_RELATIONSHIP_AND_TARGETABILITY.md` already rejects a universal NPC base and remains authoritative for allegiance/targetability semantics.