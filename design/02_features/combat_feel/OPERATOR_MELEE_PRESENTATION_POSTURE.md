# Operator Melee Presentation Posture

- **Status:** active — READY/RELAXED/draw runtime presentation implemented
- **Owner:** gameplay/combat + gameplay/animation
- **Runtime target:** Godot 4 (`custodian/`)
- **Active spec path:** `design/02_features/combat_feel/OPERATOR_MELEE_PRESENTATION_POSTURE.md`
- **Related specs:** `OPERATOR_MELEE_FAST_CHAIN.md`, `OPERATOR_MELEE_ATTACK_DRIVE.md`, `WEAPON_OWNED_ANIMATION_SYSTEM.md`, `SWORD_CLEAVER.md`

## Purpose

The Operator should read as three visually distinct levels of readiness while
wielding a melee weapon — hands free, sword drawn but relaxed, and sword at the
ready — without multiplying the gameplay state machine into a hydra of
`melee_ready_walk` / `melee_relaxed_dodge` style states.

This spec defines **melee presentation posture** as a separate presentation
axis from combat profile and gameplay action state, drives the READY ↔ RELAXED
decision from the existing `EngagementTracker` (which the game already tracks),
and lists the animation assets required for the first complete sword
implementation.

The repo already separates these concerns: unarmed/melee/ranged are *profiles*,
while `idle`, `walk`, `attack_fast`, `equip_weapon`, etc. are
*animation/gameplay states*. Posture slots in as a third, purely presentational
axis — the character physically communicates a gameplay state the simulation
already owns, rather than animation logic knowing things the simulation does
not.

## Design Decisions

1. **Posture is presentation, not gameplay.** Do not create heavyweight states
   like `melee_ready_idle` / `melee_relaxed_idle` alongside `attack_fast`,
   `block`, etc. Posture resolves presentation only and never gates or blocks
   gameplay input.
2. **READY ↔ RELAXED is driven by `EngagementTracker.engagement_active`.**
   No new proximity scanner. The tracker already begins engagement from live
   hostile intent and only ends it after `ENGAGEMENT_QUIET_SEC` (4.0 s) of no
   hostile intent. The Operator's posture becomes a physical readout of that
   existing state.
3. **`melee_draw` is the melee flavor of `equip_weapon`.** The existing
   `EquipWeaponState` is already a non-interruptible transitional state that
   plays its animation and returns to `idle`. No new gameplay state called
   `draw_sword` is invented.
4. **`melee_ready_up` is presentation polish, never a gameplay gate.** An
   attack input from RELAXED goes straight to `attack_fast`. Forcing
   `relaxed → ready_up → ready → attack` adds input latency and is rejected.
5. **The fast chain stays profile-owned under `attack_fast`.** Fast 01/02/03
   remain attack variants of the existing three-link chain, not individual
   gameplay states.
6. **No separate locomotion state families.** Movement stays movement-owned on
   the lower body; posture is loadout/upper-body owned. Visual difference
   between relaxed walking and combat walking is achieved through modular
   composition, consistent with the modular ownership rules already documented
   for the Operator.
7. **After drawing, stay READY briefly.** The existing 4-second engagement
   quiet period may already be sufficient; a 2–4 s grace target is the tuning
   floor so the draw never reads as a ceremonial lift followed by an immediate
   sword-drop.

## Axes

```text
COMBAT PROFILE                      GAMEPLAY / ACTION STATE
├── unarmed                         ├── idle
├── melee                           ├── walk
└── ranged                          ├── sprint
                                    ├── equip_weapon
                                    ├── attack_fast
                                    ├── attack_heavy
                                    ├── block / parry
                                    ├── dodge
                                    ├── hit_recoil
                                    ├── stagger
                                    └── death

MELEE PRESENTATION POSTURE
├── sheathed
├── drawing
├── ready
├── relaxed
└── sheathing
```

Posture is the only axis this spec adds. The first two already exist.

## Sword Flow

```text
UNARMED
   │
   │ select melee
   ▼
MELEE_DRAW
   │
   │ draw animation finishes
   ▼
MELEE_READY
   │
   ├── attack ─────► ATTACK
   │                  │
   │                  └────► MELEE_READY
   │
   ├── guard/parry ─► DEFENSE
   │                  │
   │                  └────► MELEE_READY
   │
   │ no hostile intent / quiet period
   ▼
MELEE_RELAXED
   │
   ├── hostile engagement ─► MELEE_READY
   ├── attack ─────────────► ATTACK
   └── switch away ────────► SHEATHE
```

Which collapses to a clean state language:

```text
            DRAW
             │
             ▼
      ┌── READY ──┐
      │     │      │
    attack guard  dodge
      │     │      │
      └─────┴──────┘
             │
       combat quiet
             │
             ▼
          RELAXED
             │
       threat appears
             │
             ▼
           READY
```

## Postures

### sheathed

The weapon is holstered; posture has no opinion. Unarmed or unequipped
presentation owns this region.

### drawing — `melee_draw`

The melee version of the existing `equip_weapon` transitional state. It is a
non-interruptible transition that plays the draw and returns to `idle` when the
animation finishes; posture resolves to READY on completion.

```text
Fists
 ↓
equip_weapon
 [melee_draw]
 ↓
idle
 [presentation resolves melee_ready]
```

The four-frame sword draw sheet already produced lives at:

```text
custodian/content/sprites/operator/new_operator/modular/melee_1h/
  operator__modular_lower_body__melee_1h__draw_weapon_01__e__4f__96x128.png
```

It should be promoted through the operator ingest pipeline into the runtime
body/upper-body stack as the `melee_draw` animation key.

### ready — `melee_idle_ready`

The **sword-up combat neutral**: sword held in front of the Operator, weight
slightly lowered, clearly prepared to attack. This is the non-attack melee
baseline and eventually replaces/extends the current single-frame melee stance
placeholder (`melee_2h_stance` in `operator_runtime_frames.tres`, the
`melee_1h_stance_01` modular one-frame stance, and the `melee_stance`
placeholder cropped from Fast 01 frame zero).

Use READY:

- immediately after drawing;
- while enemies are engaged;
- immediately following an attack;
- after dodging during combat;
- after guard/parry;
- during combo-reset windows;
- briefly after taking damage;
- whenever combat input was recently given.

### relaxed — `melee_idle_relaxed`

The **sword-down exploration neutral**: upright stance, sword in one hand, arm
down, blade pointing toward the ground. This is *not* a replacement for the
ready pose; it is the "sword is still drawn but we are not currently fighting"
pose.

```text
UNARMED         hands available / no sword
MELEE RELAXED   sword drawn / exploring
MELEE READY     sword drawn / danger
```

Walking an empty corridor reads naturally:

```text
        sword lowered
             │
             │ enemy notices Operator
             ▼
      sword comes up
             │
         combat
             │
             │ room goes quiet
             ▼
       sword lowers
```

### ready_up — `melee_ready_up`

A tiny transitional animation, the only asset currently missing from the
generated pair:

```text
RELAXED                          READY
sword ↓        frame 1            sword ↗
               sword starts lifting
               frame 2
               body lowers / hand rotates
               frame 3
               sword reaches guard
```

- 2–3 frames, roughly **0.12–0.18 s** total.
- Presentation polish only. If the player hits the primary from RELAXED, the
  attack animation gets priority; `ready_up` is skipped, never queued ahead of
  an attack.

### relax — `melee_relax`

The inverse transition, also tiny (~3 frames), **0.25–0.40 s**.

The asymmetry is intentional:

```text
ready_up:  0.12–0.18 sec
relax:     0.25–0.40 sec
```

Danger arrives quickly; calm returns gradually.

### sheathing — `melee_sheathe`

Not required for the first slice, but eventually the reverse of the draw:

```text
melee → unarmed
SHEATHE
```

The repo already treats `equip_weapon` as an unsafe selection transition
alongside attacks/block/stagger/death and queues weapon changes until safe
movement states (`idle`, `walk`, `sprint`) via
`queue_weapon_selection()` / `can_apply_weapon_selection_now()`. That machinery
is the natural home for sheathing; the draw frames can initially be reversed or
adapted. Posture returns to `sheathed` on completion.

## Engagement Trigger

Use `EngagementTracker.engagement_active` directly. The tracker is
player-owned, fixed-step, lives on the Operator
(`custodian/game/systems/combat/engagement_tracker.gd`), and:

- starts engagement from live hostile intent (`_has_live_hostile_intent()`:
  enemy targeting the Operator, or behavior states `notice` /
  `investigate` / `engage_operator` / `search`);
- resets its quiet timer on any hostile intent or confirmed direct damage;
- ends engagement after `ENGAGEMENT_QUIET_SEC = 4.0` seconds with no hostile
  intent.

Posture resolves presentation-only:

```gdscript
if engagement_tracker.engagement_active:
    melee_posture = READY
else:
    melee_posture = RELAXED
```

### Draw grace

After drawing, stay READY briefly. Without this, the draw reads as:

```text
DRAW! ⚔️
...
immediately lower sword
```

The existing four-second engagement quiet period may already be sufficient;
the target is a 2–4 s READY hold after draw completion before RELAXED is
eligible. This is a presentation timer, not a gameplay timer.

### Input priority from RELAXED

```text
relaxed
   │
   └── attack input ──► attack_fast
```

Never:

```text
relaxed → ready_up → ready → attack
```

`ready_up` is allowed to run only when no gameplay input is consuming the
frame budget.

## Timing Summary

| Transition | Direction | Target duration | Notes |
|---|---|---|---|
| `melee_draw` | sheathed → ready | authored 4 frames | promotes existing 4-frame draw sheet |
| `melee_ready_up` | relaxed → ready | 0.12–0.18 s | 2–3 frames; polish only |
| `melee_relax` | ready → relaxed | 0.25–0.40 s | ~3 frames; slower than ready-up |
| `melee_sheathe` | ready/relaxed → sheathed | later | reverse/adapt draw frames |

## Animation Asset Package

For the first complete sword implementation:

| Animation | Need now? | Purpose |
| --------- | :-------: | ------- |
| `melee_draw` | ✅ | unarmed → sword (4-frame sheet exists, needs pipeline promotion) |
| `melee_idle_ready` | ✅ | combat neutral (the crouched, sword-raised pose) |
| `melee_idle_relaxed` | ✅ | exploration neutral (the upright, sword-down pose) |
| `melee_ready_up` | 🟡 | relaxed → combat; optional authored transition pending |
| `melee_relax` | 🟡 | combat → relaxed; optional authored transition pending |
| `melee_sheathe` | 🟡 | sword → unarmed |
| `melee_fast_01` | ✅ | combo |
| `melee_fast_02` | ✅ | combo |
| `melee_fast_03` | ✅ | combo |
| `melee_heavy_01` | ✅ eventually | secondary attack |
| `melee_guard` | ✅ | shared defense |
| `melee_parry` | ✅ | shared defense |
| `melee_hit` / recoil | shared | reaction |
| `melee_dodge` | shared | movement/reaction |

Fast 01/02/03 remain attack variants under `attack_fast` — the three-link chain
is already profile-owned in the current combat design and must not become
individual gameplay states.

### Source naming

The generated sheets map to the semantic keys:

```text
operator__body__melee_1h__draw_01           → transition animation (draw)
operator__body__melee_1h__idle_relaxed_01   → looping relaxed idle
operator__body__melee_1h__idle_ready_01     → looping combat neutral
```

(The earlier crouched-sword-raised image becomes `idle_ready_01`; the upright
sword-down sheet becomes `idle_relaxed_01`.)

## Movement Composition

Do **not** create simulation states like:

```text
melee_ready_walk
melee_relaxed_walk
melee_ready_sprint
melee_relaxed_sprint
```

Visually there should eventually be a difference:

- **Relaxed walking** — sword in one hand, low; natural exploration posture.
- **Combat walking** — sword raised, torso guarded.

Because CUSTODIAN already has modular presentation architecture, these compose
instead of multiplying:

```text
lower body: walk
upper body: melee_relaxed
```

versus

```text
lower body: walk
upper body: melee_ready
```

This matches the modular ownership rules already documented for the Operator
(the ranged ready mode already uses exactly this lower-body/loadout split).

## Runtime Ownership

- `EngagementTracker` — untouched. Posture is a read-only consumer of
  `engagement_active` / `get_status()`.
- New posture resolver/controller — presentation-only; resolves
  `READY` / `RELAXED` and plays `melee_ready_up` / `melee_relax` when nothing
  gameplay-owned is playing. Never gates, blocks, or queues gameplay input.
- `operator.gd` — orchestration only; owns the draw-grace presentation timer
  and the posture transition requests at safe boundaries (idle/locomotion
  windows, after attack recovery, after dodge, after guard/parry).
- `OperatorWeaponDefinition` — owns posture animation keys per weapon via the
  existing `animation_map` shape (the `melee_stance` key already exists in
  every definition: `vigil_dagger_stance`, `sword_cleaver_stance`,
  `melee_stance` for the Katana, `unarmed_idle` for fists).
- Sprite pipeline — promotes the 4-frame draw sheet and the new idle/transition
  sheets into runtime strips under the `melee_1h` namespace.

## Edge Cases

| Case | Handling |
|------|----------|
| Draw finishes into an immediately hostile room | Posture resolves READY; draw grace makes RELAXED ineligible for 2–4 s |
| Primary pressed from RELAXED | `attack_fast` directly; `melee_ready_up` skipped, no latency added |
| `melee_ready_up` playing and attack input arrives | Attack preempts the transition; polish never queues ahead of gameplay |
| Posture change during death / stagger / block | Gameplay states own those frames; posture freezes until a safe window |
| Posture change during a runtime/portal action lock | Same rule as combat input locks; posture waits for the safe window |
| Weapon selection queued while RELAXED | Existing `queue_weapon_selection()` path applies at `idle`/`walk`/`sprint`, then plays `melee_sheathe` and resolves `sheathed` |
| RELAXED with an enemy about to attack | EngagementTracker is already `engagement_active` during `engage_operator`; posture lifts without a proximity scan |
| Missing posture art for a direction | Directional fallback per existing resolver rules (exact → `_right` → unsuffixed base); posture degrades to the stance placeholder, never breaks gameplay |

## Validation

- Focused smoke: pure posture-resolver test asserting READY/RELAXED resolution
  against injected `EngagementTracker.get_status()` fixtures, draw-grace
  timing, and input-priority (attack from RELAXED bypasses `melee_ready_up`),
  in the style of `operator_melee_soft_targeting_smoke.gd` /
  `operator_melee_fast_chain_smoke.gd`.
- Runtime wiring smoke: verify draw → ready → relaxed → ready transition
  sequence on the Operator, and that no gameplay state is added to the
  state machine.
- Moment Forge: a `combat_playground`-style scenario capturing the
  relaxed → ready lift and the quiet-period relax; `--capture-mode full` once
  the assets land, since acceptance depends on pose timing and readability.
  `Moment Forge: not run — docs-only change` applies to this spec itself.

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| `EngagementTracker.engagement_active` | ✅ Ready | Live; 4 s quiet period |
| `EquipWeaponState` | ✅ Ready | Non-interruptible transition to pattern `melee_draw` on |
| Weapon-change queuing | ✅ Ready | `queue_weapon_selection()` gates to idle/walk/sprint |
| 4-frame draw sheet | ✅ Ready | Generated catalog/runtime lower-body presentation |
| `idle_ready_01` sheet | ✅ Ready | Generated E/W lower- and upper-body stack |
| `idle_relaxed_01` sheet | ✅ Ready | Generated E/W lower- and upper-body stack |
| `melee_ready_up` / `melee_relax` sheets | ❌ Missing | 2–3 frame transitions |
| `melee_sheathe` | ❌ Deferred | Later slice; reverse/adapt draw frames |

## Next Agent Slice

Goal: implement the posture axis as presentation-only and wire the first
draw/ready/relaxed assets.

Files:

- new `game/actors/operator/melee_posture_resolver.gd` (or equivalent
  presentation helper) plus a focused smoke;
- `operator.gd` — draw-grace timer, posture requests at safe windows;
- sprite pipeline promotion of `draw_weapon_01__e__4f__96x128.png` to the
  runtime `melee_1h` namespace as `melee_draw`;
- weapon definitions gain `melee_draw` / `melee_idle_ready` /
  `melee_idle_relaxed` keys in `animation_map`.

Constraints:

- no new gameplay/action states; no changes to `EngagementTracker`;
- attacks from RELAXED bypass `ready_up`;
- posture never gates, blocks, or queues gameplay input;
- gameplay direction, hitboxes, and drive remain unchanged;
- `melee_ready_up` / `melee_relax` / `melee_sheathe` may be authored assets
  added later without runtime contract changes.

Acceptance:

- `operator_melee_posture_smoke.gd` passes (resolution, draw grace, input
  priority, no-state-multiplication assertions);
- existing melee smokes remain green;
- runtime shows draw → ready → relaxed after quiet → ready on engagement
  with no gameplay behavior change.
