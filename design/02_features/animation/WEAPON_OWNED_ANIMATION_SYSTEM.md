# WEAPON_OWNED_ANIMATION_SYSTEM

Status: in progress
Owner: gameplay/animation
Runtime target: Godot 4 (`custodian/`)

## Purpose

Migrate the operator animation stack from hardcoded animation strings inside `operator.gd` to a data-driven, weapon-owned animation system.

This is the implementation plan for the live Godot runtime. It does not replace the broader asset-folder migration note in `design/ANIMATION_SYSTEM_MIGRATION.md`; it defines how runtime ownership should change in code.

## Migration Goal

Replace:

```
operator.gd
  -> decides attack kind
  -> decides exact animation string
  -> decides overlay behavior
  -> decides hit frame windows
```

With:

```
Operator
  -> input + orchestration

Animation State Machine
  -> state transitions and attack requests

Weapon Definition
  -> animation keys, hit windows, overlay/fx mapping

Animation Resolver
  -> direction suffix resolution + fallbacks
```

## Current Runtime Reality

The current runtime is functional, but animation ownership is still inverted.

### Working pieces

- melee and ranged combat both function
- melee hitbox windows already sync from animation frames
- `OperatorWeaponDefinition` already exists
- state machine scaffold exists under `custodian/entities/operator/animations/states/`
- separated fast melee body + weapon + FX overlays already exist

### Current architectural gaps

- locomotion body playback is still largely rendered by `operator.gd`
- the state machine is connected, but the full non-combat graph is not finished yet
- block is now live; reload/interact/repair states are still pending live integration
- authored melee locomotion is still partial; only stance + attack clips are currently body-authored
- ranged secondary is a held `ranged_ready` mode; primary fires only while that mode is active, so ranged upper-body,
  weapon, cape, and FX animation should layer over movement-owned lower-body idle/walk/run.

## Files In Scope

Primary runtime files:

- `custodian/entities/operator/operator.gd`
- `custodian/entities/operator/operator_weapon_definition.gd`
- `custodian/entities/operator/operator_runtime_frames.tres`
- `custodian/entities/operator/operator_melee_overlay_frames.tres`
- `custodian/entities/operator/carbine_rifle_mk1_definition.tres`
- `custodian/entities/operator/fallen_star_katana_definition.tres`

State machine files:

- `custodian/entities/operator/animations/animation_state_machine.gd`
- `custodian/entities/operator/animations/states/attack_fast_state.gd`
- `custodian/entities/operator/animations/states/attack_heavy_state.gd`

Related docs:

- `design/OPERATOR_ANIMATION_STATE_MACHINE.md`
- `design/ANIMATION_SYSTEM_MIGRATION.md`
- `design/20_features/in_progress/COMBAT_FEEL_SYSTEM.md`

## Current Problem Points In Code

### Legacy-name cleanup

The runtime has been migrated to semantic names such as:

- `melee_2h_fast_right`
- `melee_2h_heavy_right`
- `melee_2h_fast_weapon`
- `melee_2h_fast_fx`
- `ranged_2h_stance`
- `ranged_2h_fire`

### Remaining ownership issue

The overlay system is weapon-driven now, but authored body stance selection is still a small operator-side policy layer.

### Hardcoded hit windows

Melee hitbox windows currently live in `operator.gd`:

```gdscript
match _melee_attack_kind:
    "heavy":
        active_start = 3
        active_end = 4
    _:
        active_start = 4
        active_end = 4
```

This prevents per-weapon timing control.

### State machine disconnect

`attack_fast_state.gd` and `attack_heavy_state.gd` exist, but melee attack startup still happens from:

- `_try_melee_attack()`
- `_start_fast_attack()`
- `_start_heavy_attack()`

inside `operator.gd`.

## Target Architecture

### Ownership rules

- `operator.gd` owns input collection, movement, cooldown bookkeeping, and high-level orchestration
- animation states own transitions and attack requests
- `OperatorWeaponDefinition` owns animation mappings, hit windows, and overlay/fx keys
- `AnimationResolver` owns directional suffix lookup and fallback selection
- SpriteFrames resources remain the render source until the later asset-loading migration is complete

### Non-goals for this migration

- do not rewrite combat simulation
- do not replace SpriteFrames with JSON runtime loading in the same pass
- do not collapse melee and ranged into one monolithic animation table
- do not delete existing attack clips until mappings are stable

## Phase 1: Add Animation Contract

### Goal

Stop using raw animation strings in gameplay logic.

### New runtime file

Create:

```
custodian/entities/operator/animations/animation_resolver.gd
```

Responsibilities:

- resolve a base animation key to a concrete clip name
- append direction suffixes
- provide stable fallback order

### Resolver contract

Base animation keys should look like:

- `melee_2h_fast`
- `melee_2h_heavy`
- `ranged_2h_fire`
- `ranged_2h_stance`

Resolver should map:

```gdscript
melee_2h_fast + right -> melee_2h_fast_right
melee_2h_fast + up    -> melee_2h_fast_up
melee_2h_fast + down  -> melee_2h_fast_down
```

Fallback order:

1. exact directional clip
2. `_right`
3. unsuffixed base

### Direction resolution rule

Use dominant axis:

- horizontal dominant -> `right`
- vertical dominant with `y < 0` -> `up`
- vertical dominant with `y > 0` -> `down`

Left-facing remains a sprite flip concern, not a unique animation suffix.

## Phase 2: Expand Weapon Definition Contract

### Goal

Move animation decisions into weapon data.

### File to update

`custodian/entities/operator/operator_weapon_definition.gd`

### New exported fields

Add:

```gdscript
@export var animation_map: Dictionary = {}
@export var hit_windows: Dictionary = {}
@export var fx_map: Dictionary = {}
```

Expected shape:

```gdscript
animation_map = {
    "melee_fast": "melee_2h_fast",
    "melee_heavy": "melee_2h_heavy",
    "ranged_ready": "ranged_2h_stance",
    "ranged_stance": "ranged_2h_stance",
    "ranged_fire": "ranged_2h_fire"
}

hit_windows = {
    "melee_fast": {"start": 4, "end": 4},
    "melee_heavy": {"start": 3, "end": 4}
}

fx_map = {
    "melee_fast": {
        "weapon_anim": "melee_2h_fast_weapon",
        "fx_anim": "melee_2h_fast_fx"
    }
}
```

### Notes

- keep socket and held-weapon transform data in the same resource for now
- provide defaults so existing weapons do not break during migration
- allow ranged weapons to omit melee keys and vice versa

## Phase 3: Replace Hardcoded Operator Playback

### Goal

Move from string literals to weapon-owned keys.

### Replace

Legacy:

```gdscript
_play_melee_anim("attack_right_fast")
_play_melee_anim("attack_right_heavy")
```

Target:

```gdscript
var anim_base: String = melee_weapon_definition.animation_map["melee_fast"]
_play_melee_anim_resolved(anim_base, _melee_forward)
```

### Operator responsibilities after this phase

`operator.gd` should still:

- decide current attack direction
- configure hitbox geometry
- start local cooldown timers
- sync overlay frame index to body frame

`operator.gd` should no longer:

- own the canonical animation string
- decide overlay behavior by literal clip name
- decide hit windows by local `match` on attack kind

### New helper

Replace `_play_melee_anim(anim_name: String)` with a resolver-based helper:

```gdscript
func _play_melee_anim_resolved(base: String, dir: Vector2) -> void:
    if animated_sprite == null:
        return

    var anim := AnimationResolver.resolve(base, dir, animated_sprite)
    animated_sprite.flip_h = _is_facing_left(dir)
    animated_sprite.play(anim)
    _play_melee_overlay_from_key(base)
    _sync_melee_hitbox_window_from_animation()
```

## Phase 4: Overlay System Migration

### Goal

Make melee overlay playback data-driven and weapon-owned.

### Current problem

Fast overlay playback is hardcoded to one animation string in `operator.gd`.

### Target

Replace string-specific branching with base-key lookup:

```gdscript
func _play_melee_overlay_from_key(base: String) -> void:
    var overlay_data = melee_weapon_definition.fx_map.get("melee_fast", {})
```

Initial behavior:

- if the current attack key has no overlay mapping, hide overlay sprites
- if mapping exists, play the configured weapon and FX animation clips

### Runtime contract

For the current fast attack, weapon definitions should be able to declare:

```gdscript
fx_map = {
    "melee_fast": {
        "weapon_anim": "melee_2h_fast_weapon",
        "fx_anim": "melee_2h_fast_fx"
    }
}
```

This preserves current separated-overlay behavior while keeping overlays keyed by weapon data instead of literal clip strings.

## Phase 5: Hit Window Data Migration

### Goal

Make attack active frames weapon-controlled.

### Current problem

`operator.gd` locally defines the active frames for fast and heavy attacks.

### Target

Resolve the hit window from weapon data:

```gdscript
var key := "melee_" + _melee_attack_kind
var window: Dictionary = melee_weapon_definition.hit_windows.get(key, {"start": 0, "end": -1})

if frame >= int(window.get("start", 0)) and frame <= int(window.get("end", -1)):
    enable_hitbox()
else:
    disable_hitbox()
```

### Benefit

- fast and heavy timing can vary per weapon
- weapon swaps can alter attack feel without code changes
- overlay timing and hit timing can remain aligned per weapon

## Phase 6: State Machine Integration

### Goal

Reconnect the existing animation state machine so attacks are state-driven instead of direct input-driven.

### Current reality

`attack_fast_state.gd` and `attack_heavy_state.gd` exist, but they currently:

- play hardcoded animation names
- are not the main source of truth for attack startup

### Target flow

```
input
  -> state machine request
  -> attack state enter
  -> operator start_attack(key, weapon_definition)
  -> resolver playback + hitbox setup
```

### Required changes

`attack_fast_state.gd`

- stop hardcoding `attack_fast` / `attack_right_fast`
- call a weapon-aware operator entry point

Example:

```gdscript
func enter() -> void:
    owner.start_attack("melee_fast")
```

`attack_heavy_state.gd`

- same pattern using `melee_heavy`

### New operator entry point

Add a unified method:

```gdscript
func start_attack(key: String) -> void:
    var weapon := _get_equipped_primary_weapon_definition()
    if weapon == null:
        return

    var anim_base: String = str(weapon.animation_map.get(key, ""))
    if anim_base.is_empty():
        return

    _start_attack_runtime_from_key(key, weapon, anim_base)
```

This keeps attack mechanics in operator code while moving animation and timing ownership into weapon data.

## Phase 7: Input Pipeline Cleanup

### Goal

Stop letting raw input directly trigger melee startup logic.

### Current

`operator.gd` currently uses:

- `_try_melee_attack()`
- `_start_attack_by_kind()`

### Target

Raw input should request a state transition:

```gdscript
state_machine.request("attack_fast")
```

or equivalent project-specific API.

### Expected division

- input layer chooses requested intent
- state machine validates transition
- state enter calls operator execution

This prevents animation, combat, and transition logic from diverging.

## Phase 8: Animation Naming Cleanup

### Goal

Rename runtime clips to match the new contract.

### Current names

- `attack_right_fast`
- `attack_right_heavy`
- `attack_right_fast_weapon`
- `attack_right_fast_fx`

### Target names

- `melee_2h_fast_right`
- `melee_2h_heavy_right`
- `melee_2h_fast_weapon`
- `melee_2h_fast_fx`

Ranged examples:

- `ranged_2h_stance_right`
- `ranged_2h_fire_right`

### Migration note

Do not rename clips first. Add resolver and weapon mappings before renaming SpriteFrames entries so gameplay does not break mid-migration.

## Phase 9: Validation Matrix

Manual validation after each phase:

| Test | Expected |
|------|----------|
| Fast melee attack | correct animation, overlay, and hit confirm |
| Heavy melee attack | stamina consumed and heavy hit window respected |
| Direction change | resolver chooses suffix and left-facing uses sprite flip |
| Weapon swap | carbine and katana resolve different animation maps |
| Overlay FX | only mapped attacks spawn overlay playback |
| State machine attack | input requests state, state starts attack, operator executes |

## Risk Areas

### 1. Animation name mismatch

Mitigation:

- resolver fallback to `_right`
- final fallback to unsuffixed base
- leave legacy clips in place until all resources are renamed

### 2. Incomplete weapon definitions

Mitigation:

- defaults in `OperatorWeaponDefinition`
- guard for missing animation keys
- keep old paths/resources live during migration

### 3. Split ownership during transition

Mitigation:

- only one system should start attacks at a time
- once state machine attack entry is live, remove direct `_try_melee_attack()` startup path

### 4. Overlay desync

Mitigation:

- body animation remains the frame authority
- overlay nodes continue mirroring body frame index until dedicated event timing exists

## Implementation Order

1. Add `animation_resolver.gd`
2. Expand `operator_weapon_definition.gd` with animation, hit-window, and fx maps
3. Populate `fallen_star_katana_definition.tres` and `carbine_rifle_mk1_definition.tres`
4. Replace hardcoded playback in `operator.gd`
5. Replace hardcoded hit windows in `operator.gd`
6. Replace brittle overlay string checks with weapon-driven lookup
7. Move attack start requests into the state machine
8. Rename SpriteFrames clips to the new convention
9. Remove legacy string dependencies

## Asset Naming Alignment

This code migration should align with the weapon-centric asset naming in `design/ANIMATION_SYSTEM_MIGRATION.md`.

Recommended runtime key mapping:

- `melee_fast` -> `melee_2h_fast`
- `melee_heavy` -> `melee_2h_heavy`
- `ranged_ready` -> `ranged_2h_stance`
- `ranged_stance` -> `ranged_2h_stance`
- `ranged_fire` -> `ranged_2h_fire`

This keeps gameplay keys short while keeping animation clip names semantically explicit.

## Final Result

After this migration:

- weapons become plug-and-play animation owners
- operator logic stays focused on gameplay orchestration
- the state machine becomes the source of truth for attack execution
- overlays become reusable across weapons
- animation expansion no longer requires editing hardcoded strings throughout `operator.gd`
