# Sensors Intelligence System

- **Status:** implemented-v1
- **Owner:** terminal-facing derived hostile intelligence
- **Runtime:** Godot `custodian/`
- **Last updated:** 2026-08-12

## Purpose

Sensors answers where hostile activity is, what observed contacts are doing,
how trustworthy/current the return is, and what the existing EnemyDirector
expects next. It presents confidence-bearing evidence rather than omniscient
world truth.

## Authority

`WorldSimulationRuntime` remains the sole deterministic campaign simulation
authority. `SensorIntelligenceReadModel` observes live actors and exposes a
read-only truth snapshot. `IntelProjector` removes information according to the
fidelity resolved by `TerminalFidelityPolicy`. `SensorsTerminalViewModel`
combines projected contacts, the existing EnemyDirector forecast, and read-only
ARRN network support for UI consumption. None of these outputs feed gameplay,
AI, spawning, power, saves, sectors, ARRN, or simulation state.

ARRN remains relay infrastructure and epistemic support. `SCAN RELAYS` discovers
network infrastructure; it does not scan hostiles. Physical sensor arrays and
coverage hardware are deferred until production gameplay owns such entities.

## Contact Truth

Living, non-passive enemies receive stable `C-###` IDs for their instance
lifetime. Truth records include first/last observed simulation ticks, current
transform/velocity, class, health fraction, behavior state, objective, loot
state, and deterministic operational activity. Freed/dead actors cease being
current contacts but remain as last-known stale records for a bounded 180-tick
TTL. Expiry prunes both the record and its instance-ID bookkeeping. The read
model never mutates observed nodes.

Production activity vocabulary is:

`MOVING THROUGH`, `SEARCHING`, `ENGAGING`, `VANDALIZING`, `STEALING`,
`EXFILTRATING`, `WITHDRAWING`, `DISRUPTED`, `IDLE`, and `LOITERING`.
`ENTERING` requires future real ingress evidence. `INDEXING` is reserved/future;
no current Enemy behavior emits it.

## Fidelity Projection

- **FULL + COMMAND:** individual ID, exact position/sector, class, health,
  velocity heading, fine age, activity, and HIGH confidence.
- **DEGRADED:** individual ID, coarse sector/last-known region, class and
  activity; no exact current position, health, or heading. Age is bucketed and
  confidence is MEDIUM.
- **FRAGMENTED:** sector activity aggregation only. No individual ID, class,
  health, heading, or exact position. Confidence is LOW.
- **LOST:** `NO USABLE NETWORK RETURN` only. No location, count, class,
  objective, or hostile marker; confidence is NONE.

Projected structures omit prohibited keys. UI and map code cannot recover raw
positions by simply forgetting to hide a field.

## Forecast

EnemyDirector remains planning authority, but `IntelProjector` removes
player-forbidden forecast truth before the Sensors view model receives it.
FULL exposes exact ingress/objective/composition; DEGRADED keeps a coarse lane
and generalized pressure/composition; FRAGMENTED reports only unconfirmed
ingress, hostile pressure, and unconfirmed composition; LOST reports no return
for all three. ARRN threat warning contributes only `early_warning_ticks` and
never contact or forecast confidence.

## Terminal Presentation

The page title is `SENSORS // TACTICAL INTELLIGENCE` with a summary explaining
location, activity, movement forecast, and fidelity. Top panels present
Intelligence Quality/Network Support and Forecast. The lower panel presents
individual Contacts plus Selected Contact at FULL/DEGRADED, sector activity at
FRAGMENTED, and signal loss at LOST. The existing terminal tactical map consumes
the same projected data and never raw enemy nodes while Sensors is active.
FRAGMENTED map markers use known sector centers and broad low-confidence glyphs,
never hostile centroids. Contact rows are selectable; FULL details include fine
age, health, and heading while DEGRADED uses bucketed age and explicitly omits
health/heading.

## Validation

Focused semantic projection and terminal layout smokes prove stable IDs,
stale lifecycle/counts/bookkeeping expiry, activity classification, forecast
omission at every fidelity, ARRN isolation, FRAGMENTED/LOST map leakage
prevention, contact selection/details, map restoration, and safe 1280x720 /
1366x768 layout.

## Next Agent Slice

- Goal: production visual review and future physical sensor coverage only when
  gameplay owns real sensor assets.
- Constraints: preserve read-only authority and projection-first omission.
- Acceptance: no exact hostile truth below FULL Command.
