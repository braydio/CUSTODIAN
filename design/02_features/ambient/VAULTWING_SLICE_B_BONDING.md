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

## Bonding Art Pass 1 — Partial Production Ingest (2026-09-26)

Pass 1 ingested seven clean normalized inbox strips into nine canonical runtime
strips. `guarded_approach` is READY N/E/S/W; `notice_bait` has authored N/S;
`inspect_bait` has authored N/E plus mirrored W. The fixed inputs `vw1` and
`vw10` were absent. `vw8` was retained in source_work and quarantined because
its generated matte covered the sheet. No gameplay timing or mechanics changed.
The manifest-driven asset validator now accepts partial recommended states
while continuing to enforce every present strip and all required directions.

The evidence-mode `combat/vaultwing_first_bond` run passes its behavioral
assertions. Its report has no baseline capture and is not a final art judgment;
use a full visual capture only after the remaining art is ingested.

## Bonding Art Pass 2 — Source and Direction Fallback Corrections (2026-09-26)

Pass 2 corrected the Pass-1 rejected-source lifecycle: the `vw8` matte-bearing
candidate was byte-compared against its canonical copy, removed from
`source_work`, and retained as hash-named evidence under
`custodian/asset_drop/unresolved/vaultwing_bonding_rejected/`. The staging
helper validates backgrounds before assigning canonical source names, so a
clean replacement can occupy the previously rejected semantic slot without
overwriting a different accepted master. The Vaultwing animation set now keeps
all six Slice-B actions direction-strict: exact directions resolve, W may use a
mirrored E strip, and other missing directions return empty so the existing
semantic fallback chain can use correctly-facing wild art. Generic ambient
direction fallback and bonding gameplay timing are unchanged.

No Pass-2 numbered source images were present. Art remains partial at nine
bonding runtime strips: `guarded_approach` is N/E/S/W; `notice_bait` is N/S;
`inspect_bait` is N/E/W. `feed_accept`, `watch_player`, and `bond_greet` remain
missing. First-bond evidence/full visual review is deferred until all six art
families are complete; production SFX is still the next presentation task after
art closure.

## Bonding Art Pass 3 — Partial Local-Sheet Ingest (2026-09-28)

The twelve task-local inputs were mapped by the packet's semantic map and
hash-checked; none were downloaded from `main`. Seven clean sheets passed the
family-aware stager, were resized with the repository pixel-art converter's
balanced preset, and ingested through Asset V2. `vw6` (`watch_player_e`) was
also converted as a fixed-cell six-frame sheet, visually checked for complete
silhouettes and cell bounds, and ingested with its raw source preserved. The
eight accepted masters produced eleven runtime strips, including mirrored W
outputs for E.

Three greeting sheets (`vw9`, `vw10`, and `vw12`) did not survive fixed-cell
conversion: the resulting frames visibly cut substantial wing sections. They
remain byte-verified under
`custodian/asset_drop/unresolved/vaultwing_bonding_rejected/` and were not
ingested. `vw2`, the superseded wrong-facing inspect attempt, is retained there
as rejected evidence. Do not treat these four quarantined files as production
inputs without corrected sheets or a reviewed source segmentation.

Current coverage is 15/18 authored bonding masters and 20/24 bonding runtime
strips; total Vaultwing runtime coverage is 76/80 strips. `feed_accept` has
authored E/S/N plus mirrored W, `watch_player` has authored E/S/N plus mirrored
W, `notice_bait` has authored E plus mirrored W, and `inspect_bait` has
authored S. The three `bond_greet` directions remain missing. First-bond visual
review is deferred until those sheets can be separated without clipping.

## Remaining Bonding Art Closure

- **Goal:** Supply or safely segment the three quarantined `bond_greet` E/S/N
  sheets, then complete all six B.2 actions and review the existing
  `combat/vaultwing_first_bond` Moment.
- **Files:** Vaultwing art source under
  `custodian/asset_drop/source_work/fauna/ambient_vaultwing_common/`, family
  inbox/runtime outputs, and validation/Moment reports.
- **Constraints:** Preserve ordinal mapping and source masters; 256×256 RGBA
  cells; E/S/N source masters; W mirrored by Asset V2 when valid. Do not change
  frame/FPS contracts or generate `command_ack`. Keep gameplay timing
  independent of animation completion.
- **Acceptance:** All six action contracts ingest with expected counts and
  directional coverage; focused Vaultwing asset/bond checks pass;
  `combat/vaultwing_first_bond` passes with `--capture-mode evidence`; use one
  `full` capture for final visual judgment after art completion.

## Validation

`vaultwing_bond_smoke.gd` covers safe feed attempts and interruption, stage
policies, repeated-encounter gating, rushed and damage-cancelled trials,
same-instance bond completion, damage attribution, durable identity, versioned
save/restore and malformed data, wild reset ownership, and turret/drone target
release. `combat/vaultwing_first_bond` is the reviewed Moment Forge sequence for
the voluntary landing/observation/final-feed transition, using existing wild
presentation as a temporary fallback rather than new bonding art.
