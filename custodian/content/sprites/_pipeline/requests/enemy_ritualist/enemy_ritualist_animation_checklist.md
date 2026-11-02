# enemy_ritualist Animation Production Checklist

- Template: `humanoid_combat`
- Frame size: `96`
- Directions: `s,se,e,ne,n,nw,w,sw`
- Intended source/inbox path: `custodian/content/sprites/_pipeline/inbox/enemy_ritualist/`
- Intended runtime destination pattern: `custodian/content/sprites/enemy_ritualist/runtime/` after a deliberate import/build step
- Runtime playback still requires deliberate code/state registration; these files only plan art coverage.
- Do not place gameplay scenes against `_pipeline/` paths.

## Authoring Order

1. idle
2. walk/run
3. one readable attack
4. hit reaction
5. death
6. block/parry/defense if the character uses it
7. ranged/sidearm if needed

## Coverage

| Required | Layer | Loadout | Action | Frames | Notes |
|---|---|---|---|---|---|
| yes | `body` | `unarmed` | `idle_01` | `5` | baseline readability |
| yes | `body` | `unarmed` | `walk_01` | `5` | navigation readability |
| yes | `body` | `unarmed` | `run_01` | `5` | combat movement readability |
| yes | `body` | `unarmed` | `attack_01` | `4-6` | one readable melee attack |
| yes | `body` | `unarmed` | `hitreact_01` | `4` | damage response |
| yes | `body` | `unarmed` | `death_01` | `6-10` | combat resolution |
| optional | `body` | `unarmed` | `block_loop_01` | `5` | only if this character defends |
| optional | `body` | `unarmed` | `parry_01` | `5` | only if this character can parry |
| optional | `fx` | `unarmed` | `attack_01` | `4-6` | optional slash, flash, or impact overlay |
| optional | `weapon` | `ranged_2h` | `stance_01` | `5` | only if this character uses ranged two-hand weapons |
| optional | `weapon` | `ranged_2h` | `fire_01` | `4-8` | only if ranged playback is registered |

## Recommended Canonical Filenames

- `enemy_ritualist__body__unarmed__idle_01__s__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__se__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__e__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__ne__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__n__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__nw__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__w__5f__96.png`
- `enemy_ritualist__body__unarmed__idle_01__sw__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__s__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__se__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__e__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__ne__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__n__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__nw__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__w__5f__96.png`
- `enemy_ritualist__body__unarmed__walk_01__sw__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__s__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__se__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__e__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__ne__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__n__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__nw__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__w__5f__96.png`
- `enemy_ritualist__body__unarmed__run_01__sw__5f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__s__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__se__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__e__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__ne__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__n__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__nw__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__w__6f__96.png`
- `enemy_ritualist__body__unarmed__attack_01__sw__6f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__s__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__se__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__e__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__ne__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__n__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__nw__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__w__4f__96.png`
- `enemy_ritualist__body__unarmed__hitreact_01__sw__4f__96.png`
- `enemy_ritualist__body__unarmed__death_01__s__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__se__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__e__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__ne__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__n__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__nw__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__w__10f__96.png`
- `enemy_ritualist__body__unarmed__death_01__sw__10f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__s__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__se__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__e__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__ne__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__n__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__nw__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__w__5f__96.png`
- `enemy_ritualist__body__unarmed__block_loop_01__sw__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__s__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__se__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__e__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__ne__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__n__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__nw__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__w__5f__96.png`
- `enemy_ritualist__body__unarmed__parry_01__sw__5f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__s__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__se__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__e__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__ne__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__n__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__nw__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__w__6f__96.png`
- `enemy_ritualist__fx__unarmed__attack_01__sw__6f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__s__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__se__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__e__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__ne__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__n__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__nw__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__w__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__stance_01__sw__5f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__s__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__se__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__e__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__ne__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__n__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__nw__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__w__8f__96.png`
- `enemy_ritualist__weapon__ranged_2h__fire_01__sw__8f__96.png`
