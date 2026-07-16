# CUSTODIAN — Operator Ranged Aim Assets & Metadata Quick Reference

**Purpose:** single reference for finishing the operator’s modular ranged aiming system.

**Status key:**

- **COMPLETE** — already present in runtime or already authored.
- **PARTIAL** — present, but not yet governed by a complete production contract.
- **REQUIRED** — still needed for the finished system.
- **OPTIONAL** — polish or later expansion.

---

## 1. Runtime systems

| Item                                               | Status       | Requirement / Notes                                                                  |
| -------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------ |
| Modular lower-body and upper-body operator sprites | **COMPLETE** | Existing runtime supports independent locomotion and upper-body action presentation. |
| Ranged-ready state                                 | **COMPLETE** | Operator can enter and leave ranged-ready mode.                                      |
| Aim presentation hooks                             | **COMPLETE** | Existing operator runtime has dedicated ranged aim presentation behavior.            |
| Fire presentation hooks                            | **COMPLETE** | Existing runtime supports modular primary ranged fire presentation.                  |
| Recover/lower presentation hooks                   | **COMPLETE** | Existing runtime has lowering and cleanup paths.                                     |
| Aim direction tracking                             | **COMPLETE** | `aim_direction` / operator-facing state already exists.                              |
| Dynamic weapon layout entry points                 | **PARTIAL**  | Runtime has layout hooks, but not a complete frame-authored socket contract.         |
| Frame-aware weapon socket library                  | **REQUIRED** | One authoritative lookup by animation + direction + frame.                           |
| Directional weapon sprite selection                | **REQUIRED** | Weapon art must resolve from the same canonical aim-sector resolver as the body.     |
| Fine-angle correction                              | **REQUIRED** | Small clamped correction only; do not freely rotate pixel-art weapons.               |
| Muzzle/ejection socket-driven spawning             | **REQUIRED** | Projectile, muzzle flash, and casing must use the resolved frame’s sockets.          |
| Per-direction/per-frame weapon draw order          | **REQUIRED** | Prevent weapon clipping through torso, hands, or shoulders.                          |
| Weapon socket debug overlay                        | **REQUIRED** | Show grip, support grip, muzzle, ejection, pivot, and projectile ray.                |
| Aim camera feedback                                | **REQUIRED** | Subtle zoom + directional camera lead while aiming.                                  |

---

## 2. Operator animation assets

### Required state set

| State                 | Status                         | Recommended timing |                  Loop |
| --------------------- | ------------------------------ | -----------------: | --------------------: |
| Relaxed ranged stance | **COMPLETE**                   |            6–8 fps |                   Yes |
| Relaxed → Aim         | **COMPLETE / VERIFY PATH**     |  **0.18–0.26 sec** |                    No |
| Aim hold              | **COMPLETE / VERIFY COVERAGE** |            6–8 fps |                   Yes |
| Aim → Relaxed         | **COMPLETE / VERIFY PATH**     |  **0.10–0.15 sec** |                    No |
| Fire loop             | **COMPLETE / VERIFY COVERAGE** |          12–16 fps | No or controlled loop |
| Fire recovery         | **PARTIAL**                    |      0.08–0.16 sec |                    No |
| Reload                | **REQUIRED**                   |    weapon-specific |                    No |

### Timing rule

```text
Aim → Relaxed must be faster than Relaxed → Aim.
```

Recommended starting values:

```text
relaxed_to_aim: 0.22 sec
aim_to_relaxed: 0.12 sec
aim_ready_ratio: 0.70
```

### Direction coverage

Final target:

```text
n, ne, e, se, s, sw, w, nw
```

Minimum vertical slice:

```text
e, se, sw, w
```

### Recommended runtime naming

```text
custodian/content/sprites/operator/runtime/body/ranged_2h/

operator__upper__ranged_2h__relaxed_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__raise_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__aim_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__fire_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__recover_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__lower_01__<dir>__<frames>f__96.png
operator__upper__ranged_2h__reload_01__<dir>__<frames>f__96.png
```

**Frame size:** `96×96` unless an authored action requires a larger standardized cell.

---

## 3. Weapon art assets

### Directional weapon sprites

**Status:** **REQUIRED**

Example Carbine MK1 paths:

```text
custodian/content/sprites/weapons/carbine_mk1/runtime/

carbine_mk1__weapon__aim__n.png
carbine_mk1__weapon__aim__ne.png
carbine_mk1__weapon__aim__e.png
carbine_mk1__weapon__aim__se.png
carbine_mk1__weapon__aim__s.png
carbine_mk1__weapon__aim__sw.png
carbine_mk1__weapon__aim__w.png
carbine_mk1__weapon__aim__nw.png
```

Recommended canvas:

```text
64×64 transparent canvas
```

Use `96×96` only if long weapons clip at `64×64`.

### Weapon image pivot contract

Every weapon direction requires:

```text
primary_grip_pivot
support_grip_point
muzzle_point
ejection_point
```

The primary grip is the weapon’s local pivot. Do not use the texture center.

Example metadata:

```json
{
  "direction": "e",
  "texture_size": [64, 64],
  "primary_grip_pivot": [20, 34],
  "support_grip_point": [35, 32],
  "muzzle_point": [55, 27],
  "ejection_point": [31, 26]
}
```

---

## 4. Operator per-frame socket metadata

**Status:** **REQUIRED — highest-priority missing deliverable**

### Required sockets

```text
weapon_grip
support_grip
muzzle
ejection
```

Optional later:

```text
magazine
offhand_prop
weapon_sling
```

### Metadata key

```text
animation + direction + frame
```

Example:

```json
{
  "animation": "ranged_2h_fire_01",
  "direction": "e",
  "frame": 2,
  "weapon_grip": [58, 43],
  "support_grip": [70, 42],
  "weapon_angle_deg": 0.0,
  "weapon_z": 3
}
```

### Authoritative generated file

```text
custodian/content/data/operator/generated/operator_weapon_sockets.generated.json
```

### Runtime loader

```text
custodian/game/actors/operator/animations/operator_weapon_socket_library.gd
```

### Aseprite exporter

```text
custodian/tools/aseprite/export_operator_weapon_sockets.lua
```

### Aseprite marker names

```text
socket_weapon_grip
socket_support_grip
socket_muzzle
socket_ejection
```

Markers must remain on the full uncropped frame canvas.

---

## 5. Scene/node requirements

**Status:** **PARTIAL**

Recommended operator hierarchy:

```text
Operator
├── ModularLowerBodySprite
├── ModularUpperBodySprite
├── ModularCapeSprite
├── WeaponRoot
│   ├── WeaponSprite
│   ├── MuzzleSocket
│   ├── EjectionSocket
│   └── SupportGripDebug
├── ModularUpperFxSprite
└── AimController
```

For complex internal layering, later upgrade to:

```text
RearWeaponSprite
UpperBodySprite
FrontWeaponSprite
FrontHandOverlay
```

---

## 6. Runtime aiming contract

### Direction resolution

Use one canonical eight-way resolver for:

```text
upper-body animation
weapon directional sprite
socket metadata
weapon draw order
muzzle flash orientation
projectile direction baseline
```

### Fine-angle correction

**Status:** **REQUIRED**

Recommended limits:

```text
rifles: ±6° to ±8°
pistols: ±8° to ±10°
north/south: allow 0° if rotation damages readability
```

Do not rotate the operator’s arms separately from the authored animation.

### Recoil

Use both:

```text
authored upper-body recoil
+ small procedural weapon kick
```

Recommended procedural kick:

```text
translation: 2–4 px backward
rotation: 1–3°
return: 0.05–0.10 sec
```

---

## 7. Ranged VFX assets

| Asset                         | Status                  | Contract                                                                         |
| ----------------------------- | ----------------------- | -------------------------------------------------------------------------------- |
| Muzzle flash sheet            | **COMPLETE / AUTHORED** | Must align to the firing animation or spawn at the frame-resolved muzzle socket. |
| Projectile travel animation   | **COMPLETE**            | Existing projectile asset work has been authored.                                |
| Projectile impact animation   | **COMPLETE**            | Existing impact asset work has been authored.                                    |
| Shell casing sprite/animation | **REQUIRED**            | Spawn from `ejection` socket.                                                    |
| Residual smoke                | **OPTIONAL**            | Small and directionally consistent.                                              |

Recommended paths:

```text
custodian/content/sprites/effects/weapons/carbine_mk1/
carbine_mk1__fx__muzzle_flash_01__<dir>__<frames>f__96.png
carbine_mk1__fx__ejected_casing_01.png
```

---

## 8. Aim camera feedback

**Status:** **REQUIRED**

Recommended behavior while aiming:

```text
subtle apparent zoom-in: ~1.07×
camera lead toward aim direction: 32 px
enter duration: 0.22 sec
exit duration: 0.13 sec
```

The lead should provide most of the practical benefit; zoom is the presentation cue.

Required exports:

```gdscript
ranged_aim_zoom_multiplier = 1.07
ranged_aim_camera_lead_px = 32.0
ranged_aim_camera_enter_sec = 0.22
ranged_aim_camera_exit_sec = 0.13
ranged_aim_camera_lead_smoothing = 12.0
```

Required behavior:

```text
camera entry begins during relaxed_to_aim
full aim cue at aim-ready threshold
camera exits faster during aim_to_relaxed
camera shake remains additive
camera bounds remain authoritative
no stale zoom/offset after death, dodge, execution, terminal use, or scene transition
```

---

## 9. Input/state behavior

```text
RANGED_RELAXED
  → RANGED_RAISING
  → RANGED_AIM
  → RANGED_LOWERING
  → RANGED_RELAXED
```

Rules:

```text
raising is slower than lowering
firing may buffer until aim_ready_ratio
lowering may be cancelled by renewed aim input
dodge may interrupt lowering
weapon swapping waits until sufficiently lowered
paired execution hides weapon and clears aim camera state
```

---

## 10. Reload metadata

**Status:** **REQUIRED AFTER AIM/FIRE VERTICAL SLICE**

Required sockets/events:

```text
magazine_socket
offhand_prop_socket
mag_out
mag_in
reload_commit
```

Recommended assets:

```text
operator__upper__ranged_2h__reload_01__<dir>__<frames>f__96.png
carbine_mk1__prop__magazine.png
```

Ammunition must commit exactly once at `reload_commit`.

---

## 11. Validation requirements

Create:

```text
custodian/tools/validation/operator_weapon_socket_smoke.gd
```

Must validate:

- every required aim direction resolves;
- every animation frame has a primary grip socket;
- every required weapon direction has a texture;
- muzzle and ejection sockets exist;
- projectile and muzzle flash share the resolved muzzle world position;
- body, weapon, and VFX remain frame-synchronized;
- draw order changes correctly;
- no stale socket data survives direction/state changes;
- lower duration is less than raise duration;
- camera returns exactly to baseline after cancellation;
- missing production metadata fails loudly.

---

## 12. Recommended implementation order

### Phase 1 — Carbine MK1 vertical slice

```text
Directions: e, se, sw, w
States: relaxed, raise, aim, fire, recover, lower
Sockets: primary grip, muzzle, ejection
Fine rotation: disabled initially
Camera: zoom + lead enabled
```

### Phase 2 — Full eight-direction coverage

```text
n, ne, s, nw
per-direction draw order
```

### Phase 3 — Fine aim and support hand

```text
clamped fine-angle correction
support-grip socket
alignment debug validation
```

### Phase 4 — Reload and weapon generalization

```text
magazine prop/events
shared contract for additional rifles and sidearms
```

---

## 13. Immediate next assets/tasks

1. **Create/export per-frame operator socket metadata.**
2. **Verify exact paths and directional coverage of existing raise/aim/fire/recover/lower sheets.**
3. **Create directional Carbine MK1 weapon sprites using one grip-pivot convention.**
4. **Wire muzzle/ejection spawn positions to the socket library.**
5. **Add aim zoom + directional camera lead.**
6. **Add the socket/debug validation smoke test.**

---

## Documentation drift note

The runtime already contains modular ranged presentation and dynamic layout hooks, but the asset pipeline does not yet have one authoritative, generated per-frame socket metadata contract. Documentation should not describe the socket system as complete until the exporter, generated metadata, runtime loader, and smoke test all exist.
