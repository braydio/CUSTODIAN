# Fallen Star Katana

- **Status:** implemented — later equippable weapon
- **Owner:** gameplay/weapons
- **Runtime target:** Godot 4 (`custodian/`)

## Role

The Fallen Star Katana is a separate heavier melee weapon. It is no longer the
default Operator melee definition and is not the baseline for universal melee
timing or movement.

Its authored three-link chain remains authoritative in
`combat_feel/OPERATOR_MELEE_FAST_CHAIN.md`: Fast 01/02/03 use the existing
7/7/8-frame body clips, 10/7/8-frame directional FX overlays, commit frames
5/5/6, and stamina costs 7/8/10. The Katana definition and regression smoke
remain live so later inventory/equipment work can expose it without rebuilding
the weapon.

Katana-specific attack drive is deferred. Its current profiles retain the
zero-distance default and therefore preserve existing movement behavior.

## Next Agent Slice

Goal: make the Katana obtainable/equippable through progression and tune its
own slower, larger profile-owned drive values.

Constraints: do not copy dagger timing, reach, damage, or silhouettes.

Acceptance: equipment selection swaps definitions/resources cleanly and the
Katana chain smoke remains green.
