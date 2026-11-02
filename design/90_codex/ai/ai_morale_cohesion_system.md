# AI Morale and Cohesion System

Status: candidate
Category: ai
Priority: P2
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

Enemy groups track morale, cohesion, suppression, isolation, losses, leadership, and confidence, then change behavior accordingly.

## Problem it solves

Enemies often fight to the death as individuals. That can make combat feel flat. A morale/cohesion layer makes groups feel like units reacting to battle conditions.

## Why it fits CUSTODIAN

CUSTODIAN has tactical survival combat, ranged pressure, melee threat, allied combat droids, patrols, and hostile groups. Combat should not only be health bars. It should involve pressure, fear, discipline, breakdown, and command.

Different factions can express morale differently:

- disciplined machines maintain cohesion until command relay fails
- scavengers panic after leadership dies
- ritual enemies become more aggressive when wounded
- drones lose coordination when signal is disrupted
- elite units press harder when player retreats

## Player-facing effect

Examples:

- Suppressed enemies stay behind cover.
- Killing a leader causes weaker units to scatter.
- Isolated enemies retreat toward allies.
- Shield units hold formation under fire.
- Damaged machines continue fighting but lose coordination.
- Enemies become reckless when cornered.
- A group with high cohesion performs flanking behavior.
- A group with low morale abandons a resource cache.

## Systems touched

- Enemy AI
- Combat Feel System
- Suppression
- Director Memory
- Faction Knowledge
- Sound Propagation
- Enemy Objective System
- Developer Observatory
- Animation
- Audio barks
- Encounter design

## Dependencies

Minimal version requires:

- enemy group IDs
- basic combat events
- damage/death notifications
- AI state hooks

Full version benefits from:

- Faction Knowledge System
- Director Memory
- Sound Propagation
- Line-of-Communication Graph
- Encounter Language

## Risks

Morale can make fights unpredictable. If enemies flee too often, combat may feel unsatisfying. If morale has no visible tells, players will not understand it.

Needs clear animation/audio signals:

- panic movement
- regroup call
- mechanical warning tone
- defensive posture
- retreat bark
- formation shift

## Minimal version

Each enemy group has:

- `morale`
- `cohesion`
- `suppression`
- `leader_alive`
- `recent_losses`
- `is_isolated`

Combat events modify values:

- taking damage lowers morale
- nearby ally death lowers morale
- leader death sharply lowers cohesion
- successful flank raises morale
- being near allies raises cohesion
- suppression fire raises suppression
- signal relay online raises machine cohesion

AI behavior uses thresholds:

- high morale: advance
- medium morale: hold/cover
- low morale: retreat/regroup
- broken cohesion: scatter or become disorganized

## Full version

Full version adds:

- faction-specific morale models
- squad roles
- leadership chains
- fear/resistance traits
- suppression decay
- morale recovery
- surrender/retreat/berserk states
- objective abandonment
- reinforcement calls
- morale transmitted through communication graph
- player reputation effects

## Faction examples

### Scavenger militia

High fear response, low discipline, strong loot motivation. Likely to flee after losses.

### Machine patrol

Low fear, high cohesion while signal exists. Becomes dumb and rigid if signal relay is destroyed.

### Ritualant followers

Morale may invert. Losses increase aggression or ritual frenzy.

### Elite Custodian-corrupted units

High discipline, recover morale quickly, punish retreating players.

## Developer Observatory view

Show over each group:

- morale value
- cohesion value
- suppression value
- current group behavior
- leader status
- recent morale events
- retreat/regroup target

## Acceptance criteria

Minimal implementation is acceptable when:

- Enemy groups respond to ally deaths.
- Suppression changes enemy behavior.
- Leader death or isolation affects group behavior.
- Observatory displays group morale/cohesion.
- At least one encounter visibly changes because of morale.

## Graduation criteria

Graduate when enemy groups need to feel tactical rather than acting as isolated individuals.

## Related cards

- Director Memory
- Enemy Behavior Director
- Combat Feel System
- Faction Knowledge System
- Sound Propagation
- Developer Observatory

## Notes / references

This is a combat feel multiplier. It makes ranged pressure, flanking, noise, and target priority matter.
