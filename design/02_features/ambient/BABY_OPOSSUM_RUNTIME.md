# Baby Opossum Runtime

Implementation authority for the Baby Opossum ambient creature. Describes what is
live on `main`, not what is aspirational.

## Ownership

| Concern | Authority |
| --- | --- |
| Behavior and action sequencing | `custodian/game/actors/ambient/baby_opossum/baby_opossum.gd` (`State` / `STATE_TABLE`) |
| Spawn placement, home anchor, per-creature seed | `custodian/game/systems/core/systems/ambient_critter_manager.gd` |
| Semantic clip identity, per-layer SpriteFrames | `custodian/game/actors/ambient/ambient_creature_animation_set.gd` |
| Body + prop presentation | `custodian/game/actors/ambient/ambient_creature_presentation_controller.gd` |
| Passive attack rejection | `custodian/game/systems/combat/attack_rejection.gd` |
| Runtime art publication | Asset Pipeline V2 (`tools/assets/asset.py`) |
| Family contract | `custodian/content/metadata/assets/families/ambient_baby_opossum.asset.json` |

There is exactly one of each. Do not add a second behavior controller, animation
scanner, RNG source, or passive-target API.

## Behavior: explicit state machine

`STATE_TABLE` is the whole behavior contract. Each state names

- one semantic animation,
- a movement mode (`LOCKED`, `WANDER`, `FLEE`, `APPROACH`),
- a duration (explicit seconds, otherwise the authored clip length capped at
  `MAX_DERIVED_DURATION`, otherwise `DEFAULT_ACTION_SECONDS`),
- the state it hands off to.

Consequences that the runtime smoke enforces:

- No API call plays more than one animation in a tick. Treat, hide, play-dead,
  rejection, threat, and scavenging sequences run at their authored pace.
- `LOCKED` states zero `velocity`, so hide and play-dead structurally suspend
  ambient movement rather than relying on a flag the wander tick might ignore.
- `FLEE` always terminates — on `flee_safe_distance` or on its 2.4s timer — and
  hands back through `ALERT` to `IDLE`.

### Sequences

```
ambient          IDLE <-> WANDER, with one-shot look / sniff / groom / scratch beats

treat            TREAT_NOTICE -> TREAT_APPROACH -> TREAT_SNIFF -> TREAT_TAKE
                 -> TREAT_EAT -> (FRIEND_HAPPY when trust >= FED) -> IDLE

sensed threat    DANGER_SENSE -> HISS -> FLEE_START -> FLEE -> ALERT -> IDLE

near miss        STARTLE -> FLEE_START -> FLEE -> ALERT -> IDLE

struck           REJECT_HIT -> DISAPPROVE -> FLEE_START -> FLEE -> ALERT -> IDLE

hide             HIDE_ENTER -> HIDE_HOLD (held) -> HIDE_PEEK -> HIDE_HOLD
                 -> HIDE_EXIT -> IDLE

play dead        PLAY_DEAD_ENTER -> PLAY_DEAD_HOLD (held) -> PLAY_DEAD_PEEK
                 -> PLAY_DEAD_HOLD -> PLAY_DEAD_EXIT -> ALERT -> IDLE

scavenge         SEARCH -> DIG -> FIND_TARGET -> LOOK_BACK -> EXCITED_IDLE -> IDLE
                 RETRIEVE -> IDLE, GIFT_DROP -> IDLE
```

Only `_is_interruptible()` states (`IDLE`, `WANDER`) accept a new reaction, so an
ambient beat can never cut a treat or hide sequence short.

## Determinism

The actor holds one `RandomNumberGenerator`. Wander targets, wander cadence, idle
beat selection, and idle beat cadence all draw from it. It is seeded once — by
`AmbientCritterManager` via `set_ambient_seed()`, drawn from the manager's own
contract-seeded stream — and never reseeded per decision.

`Time.get_ticks_*`, `get_instance_id()`, `randf()`, and `randi()` are forbidden for
anything that affects simulation. The smoke replays two actors on one seed and
fails if their wander traces diverge, or if two different seeds agree.

`_ready()` runs before the manager places the actor, so `home_position` is anchored
by `set_passive_home_position()` after placement; `_home_initialized` re-anchors on
the first physics tick for editor-placed instances.

## Damage and attack rejection

The Baby Opossum is invulnerable and passive. `take_damage()` always reports zero
applied damage with `blocked`, `deflected`, `invulnerable`, and `passive` set.

Weapons do not special-case it. The actor joins the `attack_rejector` group and
implements `reject_attack(context)`; `AttackRejection.is_rejector()` /
`AttackRejection.reject()` is the single path used by the operator melee sweep,
`bullet.gd`, `energy_shot.gd`, and `missile.gd`. A rejected attack resolves as a
harmless block and drives the `REJECT_HIT` reaction. Any future harmless actor opts
in by joining the same group — no new weapon branches.

## Presentation layers

Clip identity is `(layer, action, direction)`, parsed from the canonical Asset V2
filename `<owner>__<layer>__<action_group>__<variant>__<direction>__<N>f__<WxH>.png`.
Each layer builds its own `SpriteFrames`, cached on the shared animation-set
resource, with duplicate-name protection — a `body` and a `barrel_prop` clip that
share a semantic action can never collide.

The scene carries two layers:

```
BabyOpossum
├── Body      AnimatedSprite2D   layer "body"
└── HideProp  AnimatedSprite2D   layer "barrel_prop"
```

A prop layer never participates in the semantic fallback chain. It plays only a
clip authored for the body's *resolved* action, on the same action clock, and hides
otherwise. Body and prop clips for one action must share a duration; the asset
contract smoke fails the pair if they do not.

Missing dedicated clips fail soft through the fallback chain in
`ambient_creature_presentation_controller.gd`. This is intentional: the family is
all-optional and the actor must never crash or stall on absent art.

## Runtime art baseline

96×96 RGBA cells, real alpha, one pose per cell, published only through
`asset.py ingest` into
`custodian/content/sprites/ambient_creatures/baby_opossum/runtime/`.

Published today (22 strips, body layer): `idle_south` s/n/e/w, `waddle` n/e/w,
`scurry` n/e/w, `sniff`, `groom`, `scratch`, `alert`, `danger_sense`, `hide_enter`,
`hide_hold`, `hide_peek`, `play_dead_enter`, `play_dead_hold`, `notice_treat`,
`approach_wary`. `w` variants come from the family's `auto_mirror`.

Not published, tracked in `REQUIRED_ASSETS.md`: `waddle`/`scurry` south, `look`,
`hiss`, `startle`, `disapprove`, `eat`, `friend_happy`, `hide_exit`, and the whole
`barrel_prop` layer. Their approved source renders sit on a non-uniform pose grid
(or, for the barrel, disagree on canvas framing between hide states), so slicing
them onto the 96px grid cuts poses in half. They need an artist re-export, not a
pipeline change.

`asset_drop/unresolved/ambient_baby_opossum/` holds the staged strips that failed
this audit, so the bad art is preserved for re-export rather than deleted.

## Validation

| Command | Covers |
| --- | --- |
| `godot --headless --path . --script res://tools/validation/baby_opossum_runtime_smoke.gd` | home anchoring, determinism, sequence timing, movement locks, flee termination, live bullet rejection, layer separation, clip/contract agreement |
| `OPOSSUM_REQUIRE_ART=1 …` (same script) | additionally requires the published production baseline, clip by clip |
| `python tools/validation/baby_opossum_asset_contract_smoke.py` | 96px geometry, real alpha, frame-count token, sliced-pose detection, body/prop pairing |
| `python tools/assets/stage_baby_opossum_source_work.py` | audits inbox staging and quarantines mis-sliced strips (dry run by default) |

Both smokes are registered in `custodian/tools/validation/validation_manifest.json`
and route on changes to the actor, the shared ambient presentation layer, the
critter manager, `attack_rejection.gd`, `bullet.gd`, the family contract, or the
published sprites.
