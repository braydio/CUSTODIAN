# Enemy Abilities

- Belongs here: reusable enemy ability modules such as phased dash, melee attack runners, parry receivers, and future special attacks.
- Does not belong here: base enemy health/movement contracts, procgen spawning, loot table data, HUD rendering.
- Current migration status: `grunt_falcon_punch.gd` owns Falcon Punch launch eligibility and ally-lane validation. Phase execution, Marine Dash, and Savage attacks still live in `enemy.gd` and should move only through behavior-equivalence-tested slices.
- Current source of truth: shared combat hosting remains `game/actors/enemies/enemy.gd`; extracted ability seams live in this directory.
