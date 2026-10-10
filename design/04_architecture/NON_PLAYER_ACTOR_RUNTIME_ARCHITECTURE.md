# NON-PLAYER ACTOR RUNTIME ARCHITECTURE

**Status:** active architecture authority and implementation tracker  
**Reviewed baseline:** `main@0c80f6a5a1` (2026-10-09)  
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

## Actor Facet Model

A non-player actor is **not** one giant behavior object. Treat each actor as an
instance composed from independent facets with separate ownership. This is a
conceptual architecture map, not a requirement to create one universal
`ActorTraits`, `ActorBrain`, or base class. A family may implement a facet with
an existing local controller/resource, a shared compositional component, or not
at all.

| Facet | Owns / answers | Current proof / example | Architecture rule |
| --- | --- | --- | --- |
| **Identity + provenance** | What persistent/runtime instance is this, what family/archetype/species does it belong to, and where did it come from? | Vaultwing stable creature ID + spawn provenance; Enemy archetype/profile IDs | Stable identity is introduced only when a real persistence/diagnostic consumer needs it; family and archetype are not allegiance. |
| **Traits / profile** | Relatively stable behavioral tendencies, sensory tuning, movement tendencies, species/archetype parameters | `EnemyBehaviorProfile` aggression/curiosity/self-preservation/perception/movement tuning; `VaultwingBehaviorProfile` flight/combat/awareness tuning | Profiles own tuning, not live phase state. Do not collapse every species into one universal trait schema before repeated consumers prove common fields. |
| **Relationship / allegiance** | Who is this actor allied, neutral, or hostile toward, and is it a valid target right now? | `ActorAllegianceComponent`, `ActorRelationshipResolver`, Vaultwing wild -> bonded mutation | Relationship is orthogonal runtime state. Bonding or faction change must not replace the actor instance/class. |
| **Perception / observations** | What did this receiver legitimately sense, through which channel, with what salience/certainty? | Enemy perception plus the planned shared `PerceptionObservation`; Vaultwing is the second acoustic consumer | Shared sensing may produce observations; it never decides species behavior or hostility. Hearing is a stealth/perception concern, not a Vaultwing mechanic. |
| **Working memory** | What transient facts does this actor remember about targets, objectives, recent stimuli, and local context? | `EnemyBlackboard`; Vaultwing target/interest/bond transient state in local controllers | Memory is local to the actor/family until at least two consumers justify a reusable contract. Do not put behavior policy into the memory container. |
| **Decision / behavior policy** | Given traits, relationships, observations, memory, and world state, what should this actor attempt next? | `EnemyBehaviorStateMachine`; `VaultwingBehaviorController`; future social schedules/encounter policy | Behavior remains family/species/encounter local. Shared perception or combat services must not become a universal AI brain. |
| **Capabilities** | What kinds of actions can this actor perform at all: locomotion, flight, dialogue, interaction, command reception, bonding, combat, etc.? | Vaultwing flight/bonding; turret static fire control; social NPC interaction; companion command policy | Capabilities are opt-in axes, not inheritance families. No actor is required to implement the complete capability set. |
| **Abilities** | Bounded stateful action lifecycles such as Dash, Pounce, Dive, special attacks, heals, or authored interactions | `MarineDash`, `SavagePounce`, `SavageChain`, `GruntFalconPunch` | One ability, one mutable authority. Actor hosts/shared services may be requested through narrow APIs but must not retain parallel phase state. |
| **Physical state** | Health, damage/death status, posture/reaction state, current locomotion application where relevant | Enemy/Vaultwing health; CharacterBody movement; future extracted reaction/death owners | Shared contracts may exist, but lifecycle-heavy state should have a focused owner rather than accumulating in the facade. |
| **Presentation** | Which semantic body/FX/audio presentation represents current actor intent/state | `EnemyPresentationController`, Vaultwing ambient presentation controller | Presentation observes semantic state and requests; it never owns hit timing, target policy, behavior transitions, or persistence. |
| **Lifecycle / persistence** | Spawn/despawn provenance, save identity, unload/reification state, corpse/loot policy, durable bond/relationship state | Vaultwing bond save data; Enemy corpse/loot; living-world work | Persistence owns durable facts, not active behavior. Restore/reification must reconcile runtime facets without replaying one-time transition side effects. |
| **Command / interaction policy** | Who may issue commands/interact, what requests are valid, and how local policy interprets them | bonded Vaultwing future commands, Combat Drone, future social NPC dialogue/interaction | Command/interaction is optional. It must not imply Enemy inheritance or grant a global behavior controller. |

The intended flow is therefore:

```text
identity + traits/profile + relationship
        + observations + working memory
        -> family/species decision policy
        -> capability / ability requests
        -> physical actor integration
        -> semantic presentation

durable lifecycle/persistence reconciles the same facets across spawn/save/unload;
it does not replace them with a second actor model.
```

Examples:

- A **Defense Turret** may need identity, relationship/targetability, perception,
  health, fire-control abilities, presentation, and lifecycle, but no locomotion,
  dialogue, or social schedule.
- A **merchant/social NPC** may need identity, traits, relationship, working
  memory, schedule/dialogue behavior, interaction, presentation, and persistence,
  with no combat ability at all.
- A **Vaultwing** may need identity/provenance, species traits, relationship,
  shared observations, species-local memory/behavior, flight/combat capabilities,
  bounded abilities, bond state, presentation, and persistence.
- A **standard Enemy** may compose behavior profile, blackboard, perception,
  locomotion/combat host services, actor-local abilities, reactions, presentation,
  and loot/death policy without becoming the base class for any of the examples
  above.

This facet model is an **anti-godfile rule**. New work should move a coherent
facet or mechanic behind one owner when repeated state/logic becomes substantial;
it should not create a universal component merely to make the diagram literal.

## Standard Combat Agent Boundary

`custodian/game/actors/enemies/enemy.gd` remains the standard mobile combat-agent coordinator and compatibility surface. It is **not** the universal NPC base.

At the reviewed baseline it is approximately **4,958 lines** and still owns or hosts:

- shared combat/locomotion integration;
- Marine Dash phase/timer/target/reset state;
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
| NPA-1 | `enemy-marine-dash-ability-extraction-recovery-1` | Extract complete Marine Dash authority + typed tuning from `enemy.gd` | **complete / paired review passed** |
| NPA-2 | `enemy-savage-pounce-ability-extraction` | Extract Savage pounce authority using the reviewed ability seam | **implementation and paired review complete / landed** |
| NPA-3 | `enemy-savage-chain-ability-extraction` | Extract Savage two-hit chain authority | **complete / paired fresh-context review passed with 0 findings** |
| NPA-4 | `npa-4-standard-enemy-melee-extraction` | Extract ordinary standard-enemy melee transaction/state into one focused authority while preserving shared hit/reaction/special seams | **complete / paired fresh-context review passed with 0 findings** |
| NPA-5 | `npa-5-enemy-reaction-posture-extraction` | Extract ordinary reaction/posture plus Grunt parry-critical victim state into two focused actor-local authorities | **complete / paired fresh-context review passed with 0 findings at `f5dc6da50`** |
| NPA-6 | `npa-6-enemy-death-corpse-loot-extraction` | Extract Enemy health/death/corpse lifecycle into one focused owner after remeasurement against reviewed NPA-5 APIs | **implementation complete; fresh paired review next** |
| NPA-7 | TBD | Converge commanded allies/companions on shared relationship/targeting/identity contracts without inheriting `Enemy` | planned |
| NPA-8 | `non-player-fauna-bonded-command-convergence` (planned identity; packet intentionally not authored yet) | Converge ambient/fauna and bonded-command seams, consuming the reviewed shared stealth-perception observation contract and reviewed Vaultwing runtime-hardening seam without moving species behavior into enemy AI | planned / author only after earlier NPA predecessor reviews permit |
| NPA-9 | TBD | Define encounter/social NPC shared capability seams using Forlorn Ritualant as proof; preserve encounter-local phase authority | planned |
| NPA-10 | TBD | Converge static autonomous agents (Defense Turret/sentries) on shared non-locomotion combat/relationship contracts | planned |
| NPA-11 | TBD | Remove proven compatibility residue, audit legacy group fallbacks/private callers, close architecture docs/validation | planned |

NPA-1 through NPA-6 are authored against landed live main. NPA-6 was remeasured after NPA-5's paired review and is now implemented; its paired review follows landing.

NPA-1 implementation + paired-review evidence: `MarineDash` + typed `MarineDashConfig` are the sole Marine lifecycle/tuning authority; `request_marine_dash` is the public request seam; all 26 defaults and 26 Marine scene values match; current-main Marine, spatial telemetry, Sundered Keep ambush, and Falcon reversal gates pass. NPA-2 extracts pounce to `SavagePounce` + typed config and its paired review passed. NPA-3 extracts the two-hit chain to `SavageChain` + typed config; its independent fresh Codex review passed with zero findings. NPA-4 moves ordinary baseline melee commitment/windup/contact/hit-or-whiff/recovery state into `StandardEnemyMelee` + typed config; its fresh paired review passed at `8817908b1` with 0 defects, 0 material gaps, 0 other findings and nine focused runtime checks green. Live `enemy.gd` is now ~4,202 lines. NPA-5 is therefore derived from the remaining incoming-reaction cluster: `EnemyReactionController` owns posture/flinch/stagger/ordinary-critical reaction, while `EnemyParryCritical` owns Grunt critical-open opportunity and paired-execution victim reservation. Shared hit classification (`stagger_damage_threshold`), health/death, presentation, special abilities and Operator choreography remain outside those authorities.

Cross-program dependency note: the stealth-perception foundation is not an NPA slice. It is a cross-cutting sensory substrate. The approved pre-NPA-8 Vaultwing chain is `stealth-perception-foundation` -> its paired review -> `vaultwing-runtime-hardening` -> its paired review. That chain establishes shared acoustic observations first, then fixes Vaultwing-local fixed-step/bond/relationship residue. It deliberately stops before NPA-8. NPA-8 must then be authored against both those reviewed seams **and** the landed/reviewed earlier NPA program state rather than inventing Vaultwing-only hearing, importing Enemy behavior policy, or freezing a speculative universal actor API.

NPA-5 implementation extracts posture accumulation/recovery, flinch policy, recoil, stagger, ordinary critical reaction/recovery and semantic interruption into `EnemyReactionController` + typed config. `EnemyParryCritical` + typed config owns ENTER/HOLD/RECOVER/EXECUTING, capture eligibility, attacker reservation/token, execution root/direction/kind, once-only damage consumption and standalone-root preservation. `Enemy` retains the stable Operator/Falcon façade and host-owned health/death, hit classification, movement, BSM and damage result; execution sprite restoration remains presentation-owned. Grunt/Marine/Savage tuning is explicit and unchanged. Fifteen focused combat/runtime checks passed, as did the 31-test source-change sweep before packet lifecycle closeout. The final changed sweep selected `review_pairing_contract` and exposed the unrelated known F14-C1 `living-world-entity-reification-handoff` pair mismatch, so later tiers were skipped. The brittle production startup gate was reproduced on clean `main@2dffdff` and corrected to inspect the instantiated scene's effective property; no production scene or spawn behavior changed. The fresh-context NPA-5 review passed with zero findings at `f5dc6da50`; F14 was left untouched.

NPA-6 moves health/death state, damage arithmetic/results, one-time payload assembly, corpse transitions, and empty-corpse cleanup clocks into `EnemyLifecycle` + typed `EnemyLifecycleConfig`. Enemy retains orchestration and stable health/death/reification façades; `EnemyCorpseLoot` continues to own collection/rewards and `EnemyLootCarrier` the captured-resource store. Authored scene tuning is migrated without changing health, drops, marker geometry, or expiry values. Focused lifecycle, loot, reification, and NPA-5 combat controls are required before landing; the fresh paired review is the next program gate.

Author NPA-4+ against landed live main so the program learns from the actual extracted seams rather than inventing a generic actor framework up front.

**Planning / refresh chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

NPA-4 and NPA-5 are complete and independently reviewed. NPA-6 planning was refreshed against `EnemyLifecycle` consumers after the NPA-5 review. Its implementation keeps the existing corpse collector and loot carrier boundaries intact while Enemy lifecycle state moves to one focused owner.

## Program-Start Measured Baseline

Historical migration baseline reviewed at `main@02ca0025b8`:

- `enemy.gd`: ~4,958 lines.
- `combat_drone.gd`: ~656 lines and independent `CharacterBody2D` ally runtime.
- `vaultwing.gd`: ~252 lines with species-local behavior controller, presentation, allegiance, and bond state.
- `forlorn_ritualant_npc.gd`: ~385 lines with encounter-local phases and combat.
- `turret.gd`: ~441 lines, extends `Damageable`, uses `ActorRelationshipResolver`, and has no locomotion requirement.
- Marine Dash is extracted and reviewed under `abilities/marine_dash.gd` + typed `MarineDashConfig`; `enemy.gd` retains only the enable/config binding, fixed-step integration, public request/diagnostic seam, and shared actor/combat services.
- Savage pounce and two-hit chain are extracted to `SavagePounce` / `SavageChain` with typed tuning; ordinary baseline melee remains the NPA-4 target.
- Falcon Punch and reviewed Marine Dash are the concrete actor-local ability seams; neither justifies a generic universal ability base.
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
