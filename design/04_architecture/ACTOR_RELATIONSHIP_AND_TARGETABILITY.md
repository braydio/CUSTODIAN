# Actor Relationship And Targetability Foundation V1

**Status:** active architecture authority
**Scope:** relationship/allegiance queries and combat target qualification

This foundation separates three concerns that legacy `enemy` groups had
collapsed together:

- groups remain useful for discovery, indexing, and migration compatibility;
- allegiance describes who an actor is hostile or allied toward;
- targetability describes whether a particular attacker may currently acquire
  that actor (for example, a hostile Vaultwing in HIGH flight is not targetable).

`ActorAllegianceComponent` is a small compositional owner for dynamic semantic
disposition: `neutral`, `hostile`, or `operator_allied`. It synchronizes the
legacy `enemy`/`ally` groups as a compatibility adapter. The groups are not the
long-term pairwise relationship authority.

`ActorRelationshipResolver` is the shared query surface. It prefers explicit
relationship and targetability APIs, then falls back to existing team/group
contracts so conventional actors retain current behavior during migration.

This is not a universal NPC base class, behavior machine, perception service,
faction roster, diplomacy system, persistence identity, or save-game identity.
Species/archetype behavior remains local to its actor/controller. Stable
creature identity is deliberately deferred until a real Slice B save/load
consumer exists.

## Current proof

Common Vaultwing owns the component with a wild `hostile` default. Its physical
instance, health, behavior controller, seed, and presentation remain intact
when allegiance changes to `operator_allied` and back. Its targetability API
continues to report HIGH as hostile-but-untargetable and ATTACK/GROUND/PERCHED
as targetable when hostile.

Live player/defense projectile qualification, turret acquisition, drone command
target qualification, and EngagementTracker hostile qualification use the
resolver. Legacy actors continue through group/team fallback.

Future bonding may change allegiance on the same Vaultwing instance without
replacing the creature. Bond progression, persistence, commands, and companion
behavior remain separate feature slices.
