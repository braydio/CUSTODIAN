# Actor Relationship Foundation V1

- Status: `in_progress`
- Authority: `design/04_architecture/ACTOR_RELATIONSHIP_AND_TARGETABILITY.md`
- Scope: shared allegiance/targetability seam for Vaultwing pre-bond integration.
- Non-goals: bonding, persistence identity, NPC refactor, faction diplomacy, or asset work.

## Acceptance

- explicit allegiance and targetability APIs exist;
- legacy group/team fallback remains behavior-compatible;
- wild Vaultwing is hostile by default;
- HIGH is hostile but untargetable;
- ATTACK/GROUND/PERCHED are targetable while hostile;
- same-instance allegiance mutation to operator-allied removes hostile targeting;
- active projectile, turret, drone, and engagement qualification use the resolver;
- focused relationship and Vaultwing validation pass.

## Handoff

After this foundation is green, the next feature is Vaultwing Slice B bonding.
Stable persistence identity is intentionally introduced only when bonding save/load
needs it. Production Vaultwing SFX remains a presentation follow-up.
