# Vaultwing Slice B — Bonding Vertical Slice

**Status:** Slice B.1 behavioral loop implemented; Slice B remains active
**Authority:** `design/02_features/ambient/VAULTWING_SYSTEM.md`

This slice establishes the first same-instance bonding lifecycle without adding
companion commands or a new generic creature framework.

## Implemented boundary

- `VaultwingBondState` owns semantic stages: `WILD`, `OBSERVING`, `TOLERANT`,
  `ACCEPTING`, and `BONDED`.
- Valid bait is represented semantically by `vaultwing_bait` and `carrion` until
  a production bait inventory/item contract is authored. A feed is an
  interruptible approach-and-observation attempt; only its completed acceptance
  changes progress, with cooldown and feeder separation preventing encounter
  spam.
- Invalid/null feeders, invalid bait, unsafe behavior states, range violations,
  damage, and rushed trial approach reject or interrupt only the active attempt;
  historical progress remains.
- Stage policy changes tolerance, safe approach distance, and escalation delay.
  TOLERANT/ACCEPTING can hold grounded or perched near the Operator while a safe
  interaction is active.
- `ACCEPTING` permits a voluntary flight/landing approach, guarded observation,
  controlled final approach, and final feed. Trial interruption preserves
  `ACCEPTING`.
- Bond completion mutates the same actor's allegiance to `OPERATOR_ALLIED`,
  clears Operator-directed hostile intent, and preserves actor, health, seed,
  behavior, and presentation identity.
- Stable identity derives from species plus durable world/contract and semantic
  spawn-marker provenance. Versioned `custodian.vaultwing_bond.v1` records store
  identity, stage/progress, bonded status, and health; transient interaction
  state resets on restore.
- Bonded actors are excluded from disposable wild population reset and wild
  population caps. Turret/drone retained-target behavior is covered across the
  dynamic allegiance change.
- Bond feed, rejection, stage, trial, completion, and population observability
  include stable identity where applicable.

## Deliberate follow-up

This slice does not add production bait pickups/inventory consumption, global
save orchestration, companion commands, follow/orbit/assist behavior, or new
bonding animation assets. The bond API and versioned local save record are live;
item acquisition, global persistence ownership, presentation art, and Slice C
commands remain later integration work.

## Validation

`vaultwing_bond_smoke.gd` covers safe feed attempts and interruption, stage
policies, repeated-encounter gating, rushed and damage-cancelled trials,
same-instance bond completion, damage attribution, durable identity, versioned
save/restore and malformed data, wild reset ownership, and turret/drone target
release. `combat/vaultwing_first_bond` is the reviewed Moment Forge sequence for
the voluntary landing/observation/final-feed transition, using existing wild
presentation as a temporary fallback rather than new bonding art.
