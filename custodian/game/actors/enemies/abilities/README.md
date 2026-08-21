# Enemy Abilities

- Belongs here: reusable enemy ability modules such as phased dash, melee attack runners, parry receivers, and future special attacks.
- Does not belong here: base enemy health/movement contracts, procgen spawning, loot table data, HUD rendering.
- Current migration status: `grunt_falcon_punch.gd` owns the full Falcon phase machine, deterministic cadence, captured target, dynamic committed reach, target/ally/soft-world/hard-world collision classification, authored collision vulnerability/stand-up, reversal interruption, and telemetry; its typed tuning lives in `grunt_falcon_punch_config.gd` plus `configs/grunt_falcon_punch_default.tres`. Marine Dash and Savage attacks still live in `enemy.gd` and should move only through behavior-equivalence-tested slices.
- Current source of truth: `Enemy` supplies shared hit, engagement-token, presentation, camera/hitstop, separation, and observability services; extracted ability state lives in this directory.
