> IMPLEMENTATION CORRECTION --> THIS TAKES PRIORITY, PLEASE REPLACE CONFLICTING SECTION BELOW WITH THE FOLLOWING CORRECTION:

# Implementation correction:

Do not treat the P-9 as globally available by default. The current Operator already has `sidearm_weapon_definition` preloaded and `sidearm_slot_equipped` defaulting true; change the progression contract so the sidearm slot starts locked.

Desired behavior:

- Before the Great Hall sidearm chest is looted:
  - melee/unarmed selected
  - no active ranged primary selected
  - holding Secondary / Aim does nothing

- After the chest is looted:
  - melee/unarmed selected
  - holding Secondary / Aim draws the P-9 Sidearm
  - pressing Primary while held-ready fires the P-9

- If a ranged primary is actively selected, Secondary readies that ranged primary.
- If a ranged primary exists in inventory but melee/unarmed is selected, the unlocked P-9 may still serve as the fallback ready weapon.

Implementation uses `InventoryManager` as equipment ownership and the existing Operator `sidearm_slot_equipped` flag as the combat gate. Recovery and equip are distinct: the locker adds `p9_sidearm` to carried inventory, and only the Equipment page moves it into the sidearm slot and calls `grant_sidearm(...)` to activate visuals/ammo/readiness.

For Sundered Keep, add a new sidearm chest/locker interactable after the strong enemy in the right Great Hall hallway. Prefer following the existing Sundered Gate Key pattern in `sundered_keep_map.gd`: build an interactable, handle a new interaction kind, grant the reward, hide/disable the opened interactable, refresh HUD state, and print/show a pickup message. Do not assume a global `GameState` autoload exists unless verified; use existing inventory/autoload patterns or a local fallback like the Sundered Gate Key path.

> END OF IMPLEMENTATION CORRECTION

---

Update `operator_ranged_ready_input_smoke.gd` so it tests:

1. sidearm locked: cannot enter ranged-ready from melee/unarmed fallback
2. sidearm granted: can enter ranged-ready
3. active ranged definition is `sidearm_pistol`
4. sidearm does not masquerade as `ranged_2h`
5. pistol profile resolves to the ranged-balance baseline: 8 damage and 10-round magazine
6. actively selected ranged primary still takes priority over sidearm
   Implement the Sundered Keep P-9 sidearm unlock.

Design intent:
The P-9 Sidearm is the first sidearm unlock. Before the player loots it from the chest past the strong enemy in the inner Great Hall/right hallway route, holding Secondary with no ranged primary equipped should do nothing. After the chest is opened, holding Secondary with no ranged primary equipped should draw the P-9 sidearm. Primary then fires it through the existing ranged fire path. If the player later has a primary ranged weapon, Secondary should ready the primary ranged weapon first; sidearm remains the fallback only when no primary ranged definition exists.

Lore:
The chest is a sealed Custodian field-retention locker. The item is the “P-9 Field Sidearm,” a compact emergency weapon recognized by Custodian service imprint. It is fast to draw, low recoil, short range, less accurate, and weaker than a standard ranged primary.

Implementation notes:

- Current repo already has `sidearm_pistol_definition.tres`, `pistol_mk1.json`, and sidearm fallback logic.
- Convert sidearm fallback from default-equipped to progression-unlocked.
- In `operator.gd`, do not start with the sidearm equipped. Default `sidearm_slot_equipped` should be false, or split it into `sidearm_unlocked` + `sidearm_slot_equipped`.
- Add an Operator method like `grant_sidearm(definition := preload("res://game/actors/operator/sidearm_pistol_definition.tres"))`.
- `grant_sidearm` is the equip-time Operator hook. It gives the player an initial loaded magazine/reserve ammo, refreshes active weapon frames, and updates visuals only after `InventoryManager` has filled the sidearm slot.
- Preserve current priority: primary ranged weapon beats sidearm fallback.
- Add a Sundered Keep loot chest/interactable after the strong enemy in the right hallway route.
- On chest interaction:
  - persist an opened/acquired flag
  - add `p9_sidearm` to `InventoryManager` as carried equipment
  - require the player to equip it from the Equipment page before `operator.grant_sidearm(...)` is called
  - show a HUD pickup message: `P-9 FIELD SIDEARM ACQUIRED`
  - leave the opened chest state persistent for the run

- Update `operator_ranged_ready_input_smoke.gd`:
  - assert no primary ranged + locked sidearm cannot enter ranged-ready
  - assert no primary ranged + granted sidearm can enter ranged-ready
  - assert active ranged weapon is sidearm
  - assert sidearm is not treated as `ranged_2h`
  - assert pistol profile resolves to the ranged-balance baseline: 8 damage and 10-round magazine

- Update `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`.
- Update `custodian/docs/ai_context/CURRENT_STATE.md`.
- Update `REQUIRED_ASSETS.md` if production 1H pistol-ready/fire/reload body/weapon/FX clips are still missing.

Validation:

```bash
cd custodian
godot --headless --import --quit
godot --headless --script tools/validation/operator_ranged_ready_input_smoke.gd
godot --headless --script tools/validation/sundered_keep_sidearm_unlock_smoke.gd
godot --headless --script tools/validation/sundered_keep_asset_smoke.gd
godot --headless --script tools/validation/sundered_keep_layout_smoke.gd
godot --headless --script tools/validation/sundered_keep_large_layout_smoke.gd
godot --headless --quit
```

Manual check:

1. Start before sidearm chest.
2. Equip melee/unarmed with no ranged primary.
3. Hold Secondary: no ranged-ready, no pistol visual, no firing.
4. Kill/clear the strong enemy.
5. Open the chest.
6. Confirm `P-9 FIELD SIDEARM ACQUIRED`.
7. Hold Secondary: Operator draws sidearm.
8. Press Primary: sidearm fires using pistol stats.
9. Equip/add a primary ranged weapon later.
10. Hold Secondary: primary ranged weapon takes priority over sidearm.

## Implementation Status

Status: complete  
Last updated: 2026-06-21

- Operator sidearm fallback starts inactive. The locker recovers a carried P-9; the Equipment page activates it through `grant_sidearm(...)` only while the sidearm slot is filled.
- The authored Sundered Keep level places the field-retention locker at tile `[73, 27]`, beyond the Great Hall right-hallway marine.
- The locker grants the P-9 once per run, becomes non-interactable after a successful grant, and shows the acquisition prompt.
- Actively selected ranged primaries retain priority over the unlocked sidearm fallback.
- Unequipping the P-9 returns it to carried inventory and restores offhand parry/guard.
- Focused validation lives at:
  - `custodian/tools/validation/operator_ranged_ready_input_smoke.gd`
  - `custodian/tools/validation/sundered_keep_sidearm_unlock_smoke.gd`

Remaining production assets are tracked in root `REQUIRED_ASSETS.md`: the final Sundered Keep sidearm locker art and the complete modular sidearm ready/fire/recover/reload suite.
