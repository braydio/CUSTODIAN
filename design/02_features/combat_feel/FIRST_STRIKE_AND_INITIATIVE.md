# First Strike and Initiative

**Status:** complete-v1  
**Runtime:** Godot 4.x (`custodian/`)  
**Owner:** Operator combat / engagement tracking  
**Last updated:** 2026-07-29

## Purpose

Initiative should create a visible opening advantage without becoming a quiet,
engagement-long damage tax. The universal benefit therefore affects
stagger/breach pressure only. The optional Vanguard Seal turns a clean opening
into a short aggressive damage window that breaks as soon as the Operator takes
direct damage.

## Authoritative Rules

### Universal initiative

The first eligible direct Operator hit in an engagement deals:

- normal health damage;
- `+20%` stagger/breach damage.

This resolves initiative once for the active hostile engagement. Additional
enemies joining that engagement do not create new initiative checks. A hit on
one member of an ambush/hostile group claims initiative for that engagement,
not independently for every enemy.

### Vanguard Seal

When equipped in the single `relic` slot, claiming initiative activates:

- `+8%` eligible direct health damage;
- `+15%` stagger/breach damage;
- `8.0` seconds maximum duration;
- immediate removal when the Operator takes direct hostile damage.

The claiming hit receives the universal `+20%` stagger/breach modifier and
starts Vanguard Seal afterward. It does not retroactively receive Vanguard's
damage modifiers. The talisman cannot retrigger until the current engagement
has ended.

### Acquisition

**Sundered Keep — Gatehouse Core, East Command Cache**

The wall-mounted Custodian field cache is authored at tile `[62,46]` on the
eastern edge of the raised Gatehouse Core deck. It remains present but
unpowered while the gatehouse siege is dormant and is non-interactable while
the position is contested. When the siege reaches `secured`, the cache emits
one restrained amber activation pulse and becomes interactable.

The player must open the cache manually. It awards exactly one
`vanguard_seal`, never auto-equips it, and presents:

- `VANGUARD SEAL RECOVERED`
- `Equip through Inventory → Relics`

The opened state is part of Sundered Keep route-state persistence. Ownership
checks include both carried inventory and the equipped `relic` slot so loaded
or debug-spawned equipment cannot duplicate the reward.

> The gatehouse cache recognized the secured Custodian position and released
> the field seal assigned to its previous keeper.

### Eligibility

Eligible outgoing damage is direct melee, unarmed, sidearm, or primary ranged
damage owned by the Operator.

Excluded outgoing damage includes:

- turret and allied drone damage;
- traps;
- environmental hazards;
- damage-over-time ticks;
- friendly NPC damage.

The Operator wins initiative by landing eligible damage before taking direct
hostile damage. Parried, dodged, or fully negated hits do not lose initiative.
Guard chip from a direct hostile attack does lose initiative and ends Vanguard.
Damage-over-time, hazards, and environmental damage do not.

An engagement remains active while a living hostile targets, pursues,
attacks, or investigates the Operator. It ends after `4.0` consecutive seconds
without that intent. Runtime checks both the ordinary enemy `target` and the
behavior-state-machine `notice`, `investigate`, `engage_operator`, and `search`
states tied to the Operator.

## Runtime Ownership

- `game/systems/combat/engagement_tracker.gd` owns deterministic engagement,
  initiative, quiet-window, and Vanguard timers.
- `game/actors/operator/operator.gd` advances the tracker at the physics step,
  supplies melee/unarmed/critical direct-hit events, and reports applied direct
  hostile damage.
- `game/actors/projectiles/bullet.gd` supplies Operator-owned ranged direct-hit
  events.
- `game/actors/enemies/enemy.gd` accepts health damage separately from reaction
  damage so the universal rule never adds health damage.
- `game/ui/inventory/inventory_ui.gd` exposes one constrained relic slot beside
  the existing sidearm slot.
- `game/systems/core/systems/inventory_manager.gd` persists carried items and
  both equipment slots while retaining legacy flat carried-item load support.
- `content/items/relics/combat_relics.json` owns the Vanguard Seal content
  definition.
- `game/world/sundered_keep/sundered_keep_map.gd` owns the secured-cache
  activation, presentation, grant, duplicate guard, and route persistence.

Simulation authority remains in the tracker and damage receivers. The
six-frame brass-white seal VFX only presents confirmed Vanguard activation.

## Assets

- Inventory icon:
  `content/ui/inventory/runtime/icons/relics/vanguard_seal__icon__inventory__default__omni__1f__48.png`
  (`48×48`, one frame).
- Activation VFX:
  `content/sprites/effects/combat/status/combat_fx__initiative_claimed__6f__64.png`
  (`384×64`, six horizontal `64×64` frames).

The effect is a restrained seal closing around the Operator, not an explosion.
A matching small cache presentation uses the inventory icon on its internal
equipment hook; the runtime icon is derived from the authored
`content/sprites/incoming/source_talisman_vanguard_pixel_48x48.png`.
A separate HUD icon is not required in V1; `Operator.get_engagement_status()`
exposes read-only state for a future HUD consumer if playtesting shows that the
activation burst and break-on-hit rule are insufficient.

## Validation

Run from `custodian/`:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path . --import --quit
env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/initiative_vanguard_seal_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/inventory_ui_smoke.gd
env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_vanguard_seal_acquisition_smoke.gd
```

The focused smoke covers modifiers, no same-engagement retrigger, initiative
loss, the four-second quiet boundary, Vanguard activation/break behavior,
equipment persistence and legacy save compatibility, catalog data, and exact
asset/frame contracts. The acquisition smoke covers authored placement,
dormant/active locking, secured activation, single award, equipped-item
duplicate protection, route persistence, nearby traversal, and P-9 locker
independence.

## Next Agent Slice

Goal: perform a deterministic micro-playtest and tune only if the opening
advantage is visually unclear or the eight-second pressure window is too
generous.

Constraints:

- do not add engagement-long health damage;
- do not allow new enemies to retrigger initiative;
- keep timers fixed-step and presentation read-only;
- add a `24×24` HUD indicator only if playtesting demonstrates a readability
  gap.

Acceptance: a player can identify initiative activation, understands that a
direct hit broke Vanguard, and cannot farm the effect by tagging reinforcements.
