# Sword-Cleaver

- **Status:** implementation — first fast-chain iteration
- **Owner:** gameplay/weapons + animation pipeline
- **Runtime target:** Godot 4 (`custodian/`)

## Role

The Sword-Cleaver is an optional one-handed heavy melee weapon specializing in
medium reach, broad pressure, and high stagger. It does not replace the default
Vigil dagger is the active melee baseline; Sword-Cleaver owns its separate heavy profile.

## Current Runtime

The current inbox supplies one east-facing 10-frame Chain 01 motion across
lower body, upper body, FX, Vigil weapon, and cleaver weapon layers. Ingest
mirrors west. The builder emits shared body/FX and weapon-owned strips under:

```text
operator/runtime/body/melee_1h/shared/
operator/runtime/fx/melee_1h/shared/
operator/runtime/weapon/melee_1h/sword_cleaver/
```

Fast 01/02/03 have distinct semantic actions, profiles, stamina, and 9/11/14 px
drive. They provisionally reuse the same Chain 01 pixels. Contact is
zero-based frame 5 and commit is frame 6.

## Runtime Resources

```text
custodian/game/actors/operator/
├── sword_cleaver_definition.tres
├── sword_cleaver_held_frames.tres          # held weapon only
└── attacks/sword_cleaver_fast_{01,02,03}.tres
```

C2b.1 deleted `sword_cleaver_{body,weapon_overlay,fx}_frames.tres`. They were
installed into the shared canonical `SpriteFrames` at equip time, which made the
runtime animation database mutable. Presentation now selects canonical
identities from the one generated database:

```text
body      melee_1h_heavy/attack/fast_0N/{e,w}/full_body
weapon    weapon/sword_cleaver/melee_1h_heavy/attack/fast_0N/{e,w}/weapon
FX        melee_1h_heavy/attack/fast_0N/{e,w}/fx
```

That changed what the chain draws, and it is worth stating plainly. The deleted
body and FX resources pointed at the generic `melee_1h` **fast_01** strip -- all
three links at the same one -- so the chain played a single borrowed swing three
times. The canonical `melee_1h_heavy` art is distinct per link, at the same ten
frames and 18 FPS, so hit windows, commits and contacts are unchanged.

`OperatorWeaponDefinition` owns profiles, hit windows, commits and stamina. It no
longer owns animation databases. No cleaver-specific playback exists in
`operator.gd`.

## Deferred

- Production held/locomotion art. The current held stance is intentionally
  transparent so the runtime never displays the wrong weapon.
- Dedicated Fast 02 and Fast 03 *source* sheets. The canonical
  `melee_1h_heavy/attack/fast_02..03` identities the runtime now selects are
  published and distinct, but the cleaver's own authored art for those links is
  still outstanding.
- Heavy profile/runtime enablement and its complete body/weapon/FX set.
- Inventory acquisition/reward registration.
- North/south presentation.

## Acceptance

- Explicit loadout override equips the cleaver; `operator.tscn` remains dagger.
- Every fast link selects its own profile.
- Body, weapon, and FX are ten frames at 18 FPS and remain synchronized.
- Drive is collision-safe, has no target tracking, and never snaps back.
- Katana resources remain independent.

## Next Agent Slice

Goal: add authored held directions and dedicated Fast 02/03 sheets.

Constraints: preserve semantic names/profiles; do not enable heavy until body,
weapon, and FX sheets all exist.

Acceptance: asset replacement requires no cleaver branch in `operator.gd` and
passes `operator_sword_cleaver_smoke.gd`.
