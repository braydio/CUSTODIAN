# MELEE ATTACK PROFILE CONSOLIDATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: codex
- Created: 2026-05-28
- Last updated: 2026-05-28

## Task

Consolidate melee combat physics data — damage, range, arc, knockback, hit-stop, camera shake, cooldown, cancel timing, and movement profile — from scattered `operator.gd` exports into a reusable `MeleeAttackProfile` Resource. `OperatorWeaponDefinition` should reference attack profiles for light/fast/heavy instead of `operator.gd` holding 25+ flat exported vars with string-based attack-kind branching.

## Review Verdict

The Repomix pack confirms the consolidation plan is valid: current melee authority is still split between `operator.gd`, `OperatorWeaponDefinition`, animation timing, movement profiles, and string-based attack-kind branching.

**Target architecture:**

```
OperatorWeaponDefinition
  owns/refers to attack profiles

MeleeAttackProfile
  owns the actual fast/heavy/light attack behavior
```

Do **not** put every melee stat directly into `OperatorWeaponDefinition` as flat fields. That would turn it into a god-object. Instead, `OperatorWeaponDefinition` should hold references to reusable `MeleeAttackProfile` resources.

## Evidence from Repomix

- `operator.gd` still has a hardcoded `ATTACK_MOVE_PROFILES` table for `unarmed_fast`, `melee_fast`, `melee_heavy`, `unarmed_heavy`, and `ranged_fire`. Movement timing is already profile-shaped but not externalized.
- `operator.gd` still exports a big pile of melee stats directly: `melee_damage`, `melee_range`, `melee_arc_degrees`, `melee_cooldown`, light/fast/heavy damage, cancel timings, hit-stop values, camera shake, and knockback.
- `OperatorWeaponDefinition` has the right *kind* of responsibility (loadout identity, animation maps, hit windows, FX maps, sockets, weapon metadata) but is not a complete attack-physics source of truth.
- Fast attack calls `_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)` — directly from exported vars.
- Heavy attack calls `_configure_melee_hitbox(melee_heavy_hit_damage, melee_heavy_range, melee_heavy_arc_degrees)` — same pattern.
- Hit-stop branches on `_melee_attack_kind` and selects light/fast/heavy values manually instead of resolving from an active profile.
- The previous moving-attack task packet explicitly deferred the deeper animation/profile refactor, so this consolidation is the correct next slice.

## Outcome

- `operator.gd` no longer directly chooses melee damage/range/arc from `melee_fast_hit_damage`, `melee_heavy_hit_damage`, etc. when a profile exists.
- `_configure_melee_hitbox` receives values from `MeleeAttackProfile`.
- Hit-stop and camera shake resolve from `MeleeAttackProfile`.
- Attack movement profile resolves from `MeleeAttackProfile`, not the hardcoded `ATTACK_MOVE_PROFILES` constant.
- Fast/heavy/light string branching is reduced to profile selection only.
- Unarmed and melee weapons use the same `MeleeAttackProfile` schema.
- Existing attack inputs still work: unarmed primary, unarmed secondary, melee primary, melee secondary.
- Existing animation maps and hit windows still work.

## Authority

- Root routing: `custodian/AGENTS.md`
- Local routing: `custodian/docs/ai_context/CURRENT_STATE.md`
- Active design/spec docs: `python-sim/design/MASTER_DESIGN_DOCTRINE.md` (combat model §V)
- Active runtime/docs files:
  - `custodian/game/actors/operator/operator.gd`
  - `custodian/game/actors/operator/operator_weapon_definition.gd`
  - `custodian/game/actors/operator/unarmed_definition.tres`
  - `custodian/game/actors/operator/animations/states/attack_fast_state.gd`
  - `custodian/game/actors/operator/animations/states/attack_heavy_state.gd`
  - `custodian/game/actors/operator/animations/states/attack_light_state.gd`
- Container for new resources: `custodian/game/systems/combat/`
- Historical reference only: `python-sim/`

## Work Surface

### Files to change

| File | What changes |
|------|-------------|
| **New:** `custodian/game/systems/combat/melee_attack_profile.gd` | New `MeleeAttackProfile` Resource class |
| **New:** `custodian/game/actors/operator/attacks/unarmed_fast_attack.tres` | Default unarmed fast profile |
| **New:** `custodian/game/actors/operator/attacks/unarmed_heavy_attack.tres` | Default unarmed heavy profile |
| **New:** `custodian/game/actors/operator/attacks/melee_2h_fast_attack.tres` | Default melee 2h fast profile |
| **New:** `custodian/game/actors/operator/attacks/melee_2h_heavy_attack.tres` | Default melee 2h heavy profile |
| **New:** `custodian/game/actors/operator/attacks/melee_light_attack.tres` | Default melee light profile |
| `custodian/game/actors/operator/operator_weapon_definition.gd` | Add `@export` references for light/fast/heavy attack profiles |
| `custodian/game/actors/operator/unarmed_definition.tres` | Wire new attack profiles into the unarmed definition |
| `custodian/game/actors/operator/operator.gd` | Migrate 25+ exported vars to resolve from active `MeleeAttackProfile`; add resolver helpers; keep old exports as legacy fallback |
| `custodian/game/actors/operator/operator.tscn` | Remove stale melee stat overrides after Phase 4 |
| `custodian/game/actors/operator/animations/states/attack_fast_state.gd` | Optionally read timing from profile |
| `custodian/game/actors/operator/animations/states/attack_heavy_state.gd` | Optionally read timing from profile |
| `custodian/game/actors/operator/animations/states/attack_light_state.gd` | Optionally read timing from profile |

### Files to read but not change

- Existing `.tres` weapon definitions for animation map / hit window / FX reference
- `custodian/docs/ai_context/CURRENT_STATE.md` (update after)
- `custodian/docs/ai_context/FILE_INDEX.md` (update after)

### Out of scope

- Enemy melee integration (Phase 5 future work — only the profile shape should be reusable by enemies)
- New art or animation sheet creation
- Ranged weapon profiling beyond what's needed for melee-adjacent `ATTACK_MOVE_PROFILES`
- Full `ui.gd` extraction or terminal polish
- Save/load for profile state

## Recommended Architecture

### 1. `MeleeAttackProfile` Resource

Path: `custodian/game/systems/combat/melee_attack_profile.gd`

```gdscript
extends Resource
class_name MeleeAttackProfile

@export var attack_id: StringName = &"melee_fast"
@export_enum("light", "fast", "heavy") var attack_kind: String = "fast"

@export_category("Hitbox")
@export var damage: float = 10.0
@export var range_px: float = 72.0
@export var arc_degrees: float = 80.0
@export var knockback_force: float = 56.0

@export_category("Timing")
@export var windup_sec: float = 0.08
@export var active_sec: float = 0.12
@export var recovery_sec: float = 0.22
@export var cooldown_sec: float = 0.45
@export var cancel_start_sec: float = 0.22

@export_category("Movement")
@export_enum("mobile", "slowed", "rooted") var movement_profile: String = "mobile"
@export var startup_move_mult: float = 0.80
@export var active_move_mult: float = 0.65
@export var recovery_move_mult: float = 0.85
@export var turn_locked: bool = false

@export_category("Feel")
@export var hit_stop_scale: float = 0.88
@export var hit_stop_duration: float = 0.028
@export var camera_shake_power: float = 1.4

@export_category("Animation")
@export var animation_key: StringName = &"melee_2h_fast"
@export var fallback_animation: StringName = &"melee_2h_fast"
@export var weapon_overlay_animation: StringName = &""
@export var hit_window_frames: PackedInt32Array = []
@export var wound_up_before_hit: bool = false
```

### 2. Extend `OperatorWeaponDefinition`

Path: `custodian/game/actors/operator/operator_weapon_definition.gd`

Add to the existing file:

```gdscript
@export_category("Melee Attacks")
@export var light_attack_profile: MeleeAttackProfile
@export var fast_attack_profile: MeleeAttackProfile
@export var heavy_attack_profile: MeleeAttackProfile
```

This avoids turning `OperatorWeaponDefinition` into a god-object. Each weapon definition simply points to the attack profiles it uses.

### 3. Profile `.tres` Files

Suggested paths (all under `custodian/game/actors/operator/attacks/`):

| File | Attack | Key values |
|------|--------|------------|
| `unarmed_fast_attack.tres` | Fists fast | damage=10.0, range=64.0, arc=72.0, movement=mobile |
| `unarmed_heavy_attack.tres` | Fists heavy | damage=28.0, range=80.0, arc=58.0, movement=slowed |
| `melee_2h_fast_attack.tres` | Melee weapon fast | damage=14.0, range=72.0, arc=80.0, movement=mobile |
| `melee_2h_heavy_attack.tres` | Melee weapon heavy | damage=34.0, range=84.0, arc=58.0, movement=rooted |
| `melee_light_attack.tres` | Legacy light (deprecated) | damage=7.0, range=60.0, arc=72.0, movement=mobile |

Populate values by reading the current defaults in `operator.gd` exports (e.g., `melee_fast_hit_damage`, `melee_heavy_hit_damage`, `melee_damage`, etc.).

### 4. Resolver Helpers in `operator.gd`

```gdscript
func _get_current_melee_attack_profile(kind: String) -> MeleeAttackProfile:
	var weapon := get_current_combat_profile()
	if weapon == null:
		return null

	match kind:
		"light":
			return weapon.light_attack_profile
		"fast":
			return weapon.fast_attack_profile
		"heavy":
			return weapon.heavy_attack_profile
		_:
			return weapon.fast_attack_profile
```

### 5. Replace Hitbox Config Calls

Change this:

```gdscript
_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)
```

To this:

```gdscript
var attack := _get_current_melee_attack_profile("fast")
if attack:
	_configure_melee_hitbox(attack.damage, attack.range_px, attack.arc_degrees)
else:
	_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)  # legacy fallback
```

### 6. Replace `_apply_hit_stop()` Branching

Instead of branching on `_melee_attack_kind` with manual light/fast/heavy selection, use:

```gdscript
var profile := _active_melee_attack_profile
if profile:
	configured_scale = profile.hit_stop_scale
	configured_duration = profile.hit_stop_duration
else:
	# legacy fallback branching
```

### 7. Replace `ATTACK_MOVE_PROFILES`

The hardcoded constant in `operator.gd` should become a temporary fallback. The active movement data should come from `MeleeAttackProfile.movement_profile` and its `startup_move_mult` / `active_move_mult` / `recovery_move_mult` / `turn_locked` fields.

### 8. Legacy Fallback Strategy

Do **not** delete the old `@export var melee_*` fields immediately. Follow the rescue pattern:

```gdscript
# If a valid MeleeAttackProfile exists, use it.
# Otherwise fall back to the legacy exported operator value.
```

This avoids breaking scenes where `operator.tscn` has stale/null overrides. Remove old exports in Phase 4 after validation.

## Implementation Plan (5 Phases)

### Phase 1: Add `MeleeAttackProfile` + resolver helpers

1. Create `custodian/game/systems/combat/melee_attack_profile.gd` with the Resource class shape above.
2. Extend `OperatorWeaponDefinition` with `light_attack_profile`, `fast_attack_profile`, `heavy_attack_profile` exports.
3. Create `.tres` profile files under `custodian/game/actors/operator/attacks/` with values migrated from `operator.gd` defaults.
4. Wire profiles into `unarmed_definition.tres`.
5. Add `_get_current_melee_attack_profile(kind)` resolver helper to `operator.gd`.
6. **No behavioral change yet.** Just the data structure and resolver exist. Verify with `godot --headless --check-only`.

### Phase 2: Route hitbox/feel/timing through active profile

7. Replace `_configure_melee_hitbox()` calls to read from active profile, with legacy fallback.
8. Replace `_apply_hit_stop()` branching to read from active profile, with legacy fallback.
9. Replace `_trigger_camera_shake()` to read from active profile, with legacy fallback.
10. Route cooldown locking through profile (knockback force, cooldown_sec).
11. **Verify** fast/heavy/light attacks still deal correct damage, hit at correct range/arc, and feel values (hit-stop, shake) match.

### Phase 3: Route movement profile through active profile

12. Replace `ATTACK_MOVE_PROFILES` constant usage with `MeleeAttackProfile.movement_profile` fields.
13. Route `startup_move_mult` / `active_move_mult` / `recovery_move_mult` / `turn_locked` from profile.
14. **Verify** unarmed fast stays mobile, unarmed heavy slows, etc.

### Phase 4: Clean old exports and scene overrides

15. Remove legacy `@export var melee_*` fields from `operator.gd` (or mark explicitly deprecated).
16. Remove stale melee stat overrides from `operator.tscn`.
17. Run headless validation to confirm no missing reference errors.

### Phase 5: Extend enemies to reuse the same profile shape (future)

18. Enemies can create or reference `MeleeAttackProfile` resources.
19. Not required for this packet — only ensure the schema is reusable.

## Constraints

- **Determinism concerns:** Profile data is static (`.tres` files and `Resource` classes). Runtime reads are deterministic. No seeded variations needed for V1.
- **Simulation/UI boundary changes:** No changes to UI or HUD. Combat feel changes stay in operator/combat simulation code.
- **Asset requirements:** No new art assets. Only code and `.tres` resource files.
- **Compatibility or migration concerns:** Old exported vars must continue to work as fallbacks during the first 3 phases. Phase 4 removes them only after validation.
- **Clarifying questions:** The attack animation state scripts (`attack_fast_state.gd`, `attack_heavy_state.gd`) currently use `on_animation_event` for phase transitions (windup/active/recovery). Phase 2 should route *timing* values (cancel_start_sec, recovery thresholds) from the profile, but the animation event contract itself is stable and does not need replacement.
- **Main risk:** `operator.gd` currently uses `_melee_attack_kind`, `_melee_attack_key`, `_resolve_current_attack_id()`, animation fallback names, and profile/unarmed logic together with significant implicit coupling. Follow the phase order strictly — do not jump to deleting old fields.

## Acceptance Criteria

1. `operator.gd` no longer directly chooses melee damage/range/arc from `melee_fast_hit_damage`, `melee_heavy_hit_damage`, etc. when a profile exists.
2. `_configure_melee_hitbox` receives values from `MeleeAttackProfile`.
3. Hit-stop and camera shake resolve from `MeleeAttackProfile`.
4. Attack movement profile resolves from `MeleeAttackProfile`, not `ATTACK_MOVE_PROFILES`.
5. Fast/heavy/light string branching is reduced to profile selection only.
6. Unarmed and melee weapons use the same `MeleeAttackProfile` schema.
7. Existing attack inputs still work:
   - Unarmed primary (unarmed_fast)
   - Unarmed secondary (unarmed_heavy)
   - Melee primary (melee_fast)
   - Melee secondary (melee_heavy)
8. Existing animation maps and hit windows still work.
9. **Godot check passes:**
   ```bash
   cd custodian && godot --headless --check-only --script res://game/actors/operator/operator.gd
   ```
10. **Scene boot passes:**
    ```bash
    cd custodian && godot --headless --quit --scene res://scenes/game.tscn
    ```

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md` — Needs update: replace the melee profile-data consolidation gap line with Phase 4+ completion status.
- `custodian/docs/ai_context/CONTEXT.md` — Check if melee architecture section needs refresh.
- `custodian/docs/ai_context/FILE_INDEX.md` — Needs update: add `melee_attack_profile.gd` and new `.tres` files.
- `custodian/AGENTS.md` — No change expected.
- Design docs — `python-sim/design/MASTER_DESIGN_DOCTRINE.md` § Combat Model is already locked at the right abstraction level; no change needed.

## Completion Notes

- Implemented: Added reusable `MeleeAttackProfile` Resource data, default unarmed/melee light/fast/heavy `.tres` profiles, weapon-definition profile references, operator profile resolution for hitbox data, knockback, cooldown, cancel timing, hit-stop, camera shake, movement phases, and stale scene override cleanup.
- Validated: `godot --headless --check-only --script res://game/actors/operator/operator.gd` passed. `godot --headless --quit --scene res://scenes/game.tscn` exited 0 after loading the runtime scene; Godot still reports existing exit-time leaked ObjectDB/resource warnings.
- Deferred: Enemy reuse of `MeleeAttackProfile` remains Phase 5 future work. Legacy operator melee exports remain as deprecated fallbacks instead of being deleted outright.

## Next Steps

- Next action: Playtest profile-backed unarmed/melee primary and secondary attacks in-editor, then clean any stale design wording around deprecated `attack_light` compatibility.
- Best starting files:
  - `custodian/game/actors/operator/operator_weapon_definition.gd` (reference for Resource pattern)
  - `custodian/game/actors/operator/unarmed_definition.tres` (reference for .tres structure)
  - `custodian/game/systems/core/systems/weapon_definition_factory.gd` (reference for factory pattern)
- Required context:
  - Read `custodian/game/actors/operator/operator.gd` — particularly `_configure_melee_hitbox()`, `_apply_hit_stop()`, `_trigger_camera_shake()`, `_lock_melee_cooldown()`, `ATTACK_MOVE_PROFILES`, and the melee export block (lines ~75–125 and surrounding).
  - Read existing `attack_fast_state.gd` / `attack_heavy_state.gd` / `attack_light_state.gd` for animation state coupling.
  - Read `custodian/game/systems/combat/` directory to confirm placement.
- Validation to run after each phase:
  - `godot --headless --check-only --script res://game/actors/operator/operator.gd`
  - `godot --headless --quit --scene res://scenes/game.tscn`
- Blockers or open questions: None for Phase 1.
