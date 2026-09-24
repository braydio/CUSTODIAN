# Vaultwing Slice B — Bonding Vertical Slice

**Status:** active implementation slice
**Authority:** `design/02_features/ambient/VAULTWING_SYSTEM.md`

This slice establishes the first same-instance bonding lifecycle without adding
companion commands or a new generic creature framework.

## Implemented boundary

- `VaultwingBondState` owns semantic stages: `WILD`, `OBSERVING`, `TOLERANT`,
  `ACCEPTING`, and `BONDED`.
- Valid bait is represented semantically by `vaultwing_bait` and `carrion` until
  a production bait item contract is authored.
- Peaceful feeding advances progress; invalid bait, invalid feeders, unsafe
  altitude, and out-of-range offers are rejected without erasing prior progress.
- `ACCEPTING` permits an explicit voluntary bond trial. Completing it mutates
  the same actor's allegiance to `OPERATOR_ALLIED`.
- Stable creature identity, bond stage/value, feed count, trial state, and
  allegiance are exposed through save/restore dictionaries.
- Bonded Vaultwings stop hostile player-interest and dive requests while keeping
  their actor, health, behavior controller, and presentation intact.

## Deliberate follow-up

This vertical slice does not add production bait pickups, inventory consumption,
companion commands, follow/orbit/assist behavior, global save orchestration, or
new bonding animation assets. Those require the interaction and persistence
contracts to be settled against a working bond sequence first.

## Validation

`vaultwing_bond_smoke.gd` proves stage progression, invalid-bait rejection,
voluntary trial completion, same-instance allegiance mutation, stable identity,
save/restore, and malformed-stage rejection.
