# Operator Integrity Reclaim

**Status:** complete-v1  
**Owner:** Operator combat health / combat-result integration / HUD presentation  
**Runtime target:** Godot 4.x (`custodian/`)  
**Last updated:** 2026-07-26

## Purpose

Integrity Reclaim rewards decisive retaliation after the Operator takes
unblocked damage. A temporary portion of lost health becomes recoverable, and
confirmed direct damage against living hostiles converts that pool back into
actual Operator health.

This is not passive regeneration. Field Patches remain the finite,
interruptible committed heal, fatal damage remains fatal, and the Operator
remains the sole health authority.

## V1 Tuning

| Parameter | Value |
|---|---:|
| Incoming damage converted to reclaim | 55% |
| Maximum active pool | 30% maximum health |
| Light-hit lifetime | 2.1 seconds |
| Heavy-hit lifetime | 3.0 seconds |
| Full-value hold | 0.6 seconds |
| Melee/unarmed efficiency | 45% |
| Critical/riposte efficiency | 55% |
| Ranged efficiency | 20% |
| Existing pool forfeited on another hit | 25% |

After the full-value hold, each packet decays until its independent lifetime
ends. Recovery and forfeiture consume the packet nearest expiration first.
New damage never refreshes older packets.

## Authority

`operator_integrity_reclaim.gd` is an Operator-owned deterministic
`RefCounted`. It owns only packet amount, ceiling, hold, decay, expiry, and
conversion math. It never mutates health, creates damage, decides target
validity from presentation, or runs outside the Operator fixed step.

The Operator:

- records eligible nonfatal incoming damage after actual health loss;
- advances reclaim from `_physics_process`;
- applies the helper's returned restore through normal health authority;
- clamps the pool after Field Patch or other healing;
- clears the pool on death;
- exposes read-only status to HUD/debug consumers;
- emits Developer Observatory events and gauges.

## Incoming Rules

Eligible incoming damage must be actually applied, unblocked, nonfatal, and
explicitly marked reclaimable by the authoritative enemy-hit boundary.

No pool is created by:

- dodge or parry;
- full blocks;
- guard-chip damage;
- environmental/direct `take_damage` calls without eligible hit context;
- debug infinite-health rejection;
- fatal damage.

The packet stores the Operator health value from immediately before its
corresponding hit. Recovery from that packet can never raise health above that
ceiling.

## Confirmed Damage Rules

Eligible outgoing damage is the amount actually removed from a living hostile:

- direct melee and unarmed;
- direct player-owned Carbine/sidearm projectiles;
- paired critical execution and future explicit riposte.

Rejected sources include allied drones, turrets, damage over time,
environmental damage, structures, passive enemies, dead/invulnerable/deflecting
targets, and overkill. `Enemy.take_damage()` returns a synchronous structured
result whose `applied_damage` is clamped to target health before the hit.

All recovery reaches the Operator through:

```gdscript
report_confirmed_damage_dealt(
	applied_damage: float,
	damage_context: Dictionary
) -> float
```

No animation state or attempted-damage value can grant health.

## Presentation

The Black Reliquary HUD layers a pale steel/cyan reclaim bar behind the solid
red health fill. Its endpoint is:

```text
actual health + active recoverable integrity
```

Packet decay contracts the trailing segment. Restores of at least one health
show a short `RECLAIM +N` message near the health display. No permanent second
resource meter or production animation asset is required.

## Observability

Events:

```text
player_reclaim_pool_added
player_reclaim_restored
player_reclaim_expired
player_reclaim_forfeited
player_reclaim_rejected
```

Gauges:

```text
player_reclaim_active
player_reclaim_packet_count
player_reclaim_window_remaining
```

Observability is read-only and never influences packet or health results.

## Validation

Run:

```bash
cd custodian
godot --headless --path . \
  --script res://tools/validation/operator_integrity_reclaim_smoke.gd
godot --headless --path . \
  --script res://tools/validation/field_patch_smoke.gd
godot --headless --path . \
  --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
godot --headless --path . \
  --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
```

The focused smoke covers exact V1 math, independent expiry, second-hit
forfeiture, source rejection, overkill, health ceilings, death, healing clamp,
HUD structure, and repeated fixed-step determinism.

## Next Agent Slice

Goal: manual combat-feel review of decay readability and reclaim timing across
fast melee, heavy knockdown recovery, Carbine, sidearm, and critical execution.

Files: this spec, reclaim helper, Operator result gateways, and Black Reliquary
HUD.

Constraints: retain fixed-step packet authority, finite Field Patches,
authoritative applied-damage results, and the no-passive-regeneration rule.

Acceptance: aggression feels valuable without making repeated hits safe;
ranged reclaim remains noticeably weaker; the trailing health segment is
readable without becoming a second resource meter.
