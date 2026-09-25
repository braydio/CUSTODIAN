# Vaultwing Slice B — Bonding Vertical Slice

**Status:** Slice B.1 behavioral loop and B.2 presentation contract implemented; Slice B remains active
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

## B.2 presentation contract

`VaultwingBehaviorController` owns a presentation-only interaction override so
its per-frame behavior animation publication cannot immediately stomp bond
cues. Slice-B semantics map to `notice_bait` (bait recognition),
`guarded_approach` (cautious grounded bait approach), `inspect_bait` (bait
observation dwell), `feed_accept` (completed feed), `watch_player` (guarded
trial observation through final-feed readiness), and `bond_greet` (recognition
after completion). Timed one-shots use visual durations only; approach, feed,
trial, and bond timing remain behavior/bond-state owned. The Asset V2 family
registers all six at their designed frame/FPS contracts, with current wild
clips as semantic fallbacks until art is ingested. `command_ack` is not part of
this pass.

## Deliberate follow-up

This slice does not add production bait pickups/inventory consumption, global
save orchestration, companion commands, follow/orbit/assist behavior, authored
bonding animation assets, or bonding SFX. The bond API, versioned local save
record, and semantic presentation contract are live; art ingest and Moment
review precede production SFX, item acquisition, global persistence ownership,
and Slice C commands.

## Next Agent Slice — Bonding Art Ingest and First-Bond Review

- **Goal:** Author and ingest the six B.2 bonding actions, then review the
  existing `combat/vaultwing_first_bond` Moment.
- **Files:** Vaultwing art source under
  `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`, family
  inbox/runtime outputs, and validation/Moment reports.
- **Constraints:** 256×256 RGBA cells; E/S/N source masters; W mirrored by Asset
  V2 when valid; 18 source masters and 24 runtime strips. Do not generate
  `command_ack`. Keep gameplay timing independent of animation completion.
- **Acceptance:** All six action contracts ingest with expected counts and
  directional coverage; focused Vaultwing asset/bond checks pass;
  `combat/vaultwing_first_bond` passes with `--capture-mode evidence`; use one
  `full` capture for final visual judgment.

## Validation

`vaultwing_bond_smoke.gd` covers safe feed attempts and interruption, stage
policies, repeated-encounter gating, rushed and damage-cancelled trials,
same-instance bond completion, damage attribution, durable identity, versioned
save/restore and malformed data, wild reset ownership, and turret/drone target
release. `combat/vaultwing_first_bond` is the reviewed Moment Forge sequence for
the voluntary landing/observation/final-feed transition, using existing wild
presentation as a temporary fallback rather than new bonding art.
