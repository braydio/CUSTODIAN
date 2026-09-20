# Operator `animated_sprite` cutover evidence

Scope is `animated_sprite` alone. The melee and weapon overlays remain
compatibility renderers and belong to their own later slices.

135 clips in the compatibility resource; 2 are reachable by a live consumer.

| disposition | all clips | live only |
|---|---|---|
| AUTHORING_DECISION | 2 | 2 |
| RETIRED | 133 | 0 |

## Live clips

| clip | canonical identity | published | timing | disposition |
|---|---|---|---|---|
| `ranged_2h_fire` | `ranged_2h/cosmetic/legacy_fire_body/omni/full_body` | NO | - | AUTHORING_DECISION |
| `ranged_2h_stance` | `unarmed/posture/stance_01/e/full_body` | yes | preserved | AUTHORING_DECISION |

## Authoring decisions

Each of these is a live clip drawing art published only under a legacy action
id, so none has a canonical counterpart that evidence alone can establish.
They are decisions, and they are recorded as decisions: a resolved decision is
not the same claim as a proof of equivalence, and is deliberately not filed as
`PROVEN_CANONICAL`. `REPLACE` chooses the canonical identity the intent moves
to, with pixels that differ on purpose. `RETIRE` drops the clip or the
mechanism that reaches it.

2 resolved, 0 open.

| clip | legacy art | authored | decision | resolution |
|---|---|---|---|---|
| `ranged_2h_fire` | `legacy_fire_body` | 4f @12.0 | RETIRE | no replacement |
| `ranged_2h_stance` | `stance_01` | 12f @8.0 | RETIRE | no replacement |

Rationale:

- `ranged_2h_fire` — The full-body ranged fire fallback is retired rather than migrated. Canonical ranged fire is the modular composition -- movement-owned lower body, ranged_2h/cosmetic/fire_01 upper_body, the socketed static carbine, and fire_01 FX -- and WEAPON_OWNED_ANIMATION_SYSTEM.md forbids substituting a compatibility full-body clip for a missing ranged layer. Promoting the old legacy_fire_body strip would produce a schema-clean asset that violates the architecture being migrated to, so ranged_2h/cosmetic/fire_01/*/full_body is deliberately not published. The historical strip stays as provenance art and simply stops being reachable; a modular stack that cannot present reports the missing canonical presentation instead of falling back. After the cutover this clip still counts as live because the name survives as a hardcoded weapon-map default, but its remaining consumers draw from the weapon renderer's own SpriteFrames rather than animated_sprite -- operator_weapon_frames.tres has its own clip of the same name. The count is left conservative on purpose: under-reporting is the failure mode that hid consumers in four consecutive slices, so a name collision is reported and explained rather than filtered away.
- `ranged_2h_stance` — The historical mapping is mechanically proven and semantically rejected: this clip drew unarmed/posture/stance_01/e/full_body, the unarmed stance standing in for a ranged one. That the pixels were really shown does not make the substitution a valid canonical ranged stance, exactly as in R3. Ranged stance remains the canonical modular upper-body and socketed-weapon composition over a movement-owned lower body, so ranged_2h/posture/stance_01/*/full_body is deliberately not created. As with ranged_2h_fire, the surviving references resolve against primary_weapon_sprite and the weapon icon's frames_resource, which the weapon-overlay slice owns, so this stays reported as live while no longer reaching animated_sprite.

## Weapon `animation_map` sites

A name reached through `_get_weapon_animation_name()` is only data-driven where a
weapon definition actually overrides that key. Where none does, the actor's
literal default is what ships, and it is an ordinary live request. Reading these
as resource values is what hid `ranged_2h_fire` and `ranged_2h_stance`, so the
generator now fails if one of them names a clip with no recorded consumer.

- `ranged_fire` -> default `ranged_2h_fire` — overridden by sidearm_pistol_definition.tres to ranged_2h_fire
- `ranged_stance` -> default `ranged_2h_stance` — overridden by sidearm_pistol_definition.tres to ranged_2h_stance

## Data-driven bases

- `_get_weapon_animation_name(...unarmed_light_hitreact...)` — OperatorWeaponDefinition animation_map; the damage-reaction base is a weapon-definition field, not a literal in the actor
- `_get_authored_melee_body_stance_animation()` — melee posture resolver / weapon definition; the stance base is authored per weapon rather than named in the actor

## External name/frame consumers

- `instant_replay_recorder.gd` (observability) — captures `sprite.animation` and restores it on playback. In-memory only with no checked-in fixtures, so it round-trips whatever names are live; a replay captured before a cutover cannot be restored after one.
- `animation_state_machine.gd` (presentation) — `current_animation()` returns `sprite.animation` and `is_animation_playing(name)` compares it. The comparison helper has zero callers, so no gameplay state keys off the clip name today.
- `hit_recoil_state.gd` (gameplay-semantic) — detects reaction completion by comparing `sprite.animation` against the name it played. Survives renaming only because both sides move together; it must keep comparing the same string the state played.
- `operator_presentation_rig_2d.gd` (presentation) — mirrors `animated.animation = source_animated.animation` onto a preview rig, so the rig needs the same SpriteFrames the source renderer uses.
- `operator.gd::_apply_knight_test_skin_if_requested` (observability) — swaps `animated_sprite.sprite_frames` for a debug Knight skin built under legacy clip names, caching the production resource to restore. After canonicalization the skin's own names no longer match what consumers request, so the debug skin needs its own disposition.
