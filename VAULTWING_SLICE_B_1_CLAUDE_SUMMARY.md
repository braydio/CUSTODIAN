# Vaultwing Slice B.1 — Claude Summary

**Status:** implementation validated; changed-file coverage is incomplete only for unrelated shared worktree files

## Outcome so far

- Added safe, interruptible bait approach/observation attempts. Feed progress
  changes only on completed acceptance; same-encounter cooldown and feeder
  separation prevent API spam. Null/invalid feeders and bait, unsafe states,
  range changes, and interruptions preserve historical progress.
- Added stage policy for tolerance, safe approach distance, and escalation
  delay, plus a voluntary takeoff/approach/landing/guarded-observation/final-feed
  trial. Completion changes allegiance on the same actor and clears Operator
  hostility intent without resetting health, behavior, RNG seed, or presentation.
- Added durable species + world/contract + semantic spawn-marker identity and
  versioned `custodian.vaultwing_bond.v1` state/health serialization. Restore
  rejects malformed values and resets transient interaction state.
- Bonded actors are retained by world reset and excluded from the wild cap.
  Added stable-ID bond observability, damage-source attribution, turret overlap
  reconciliation, and direct retained-target regression checks for turret/drone.
- Added `combat/vaultwing_first_bond`; it passes its assertions and its contact
  sheet/keyframes were reviewed. The Moment uses a fixture-only Operator
  silhouette and current wild animations; no bonding art was created.

## Validation

Passing focused checks:

- `vaultwing_bond`
- `actor_relationship_contract`
- `vaultwing_runtime`
- `vaultwing_world_spawn`
- `combat/vaultwing_first_bond` (Moment Forge assertions + visual review)

The final `run_validation.py --changed --json` sweep selected 63 checks; all 63
passed with no test failures, timeouts, or skips. The command returned the
coverage-incomplete status because 25 unrelated shared-worktree Operator art,
runtime export, connector-review, and audio/Reaper files have no validation
owners. Every Slice B.1 file is covered. Historical archive-boundary validation
passed.

## Deferred / cautions

- No production bait pickup/inventory caller or global save orchestration was
  added; the semantic API and versioned local save record are implemented.
- Bonding animation art and Vaultwing production SFX remain follow-up work.
- Companion commands/behavior remain Slice C; no generic enemy/ambient manager
  refactor or sprite changes were made for this slice.

## Surprises and negative evidence

The first live trial smoke exposed missing Vaultwing actor-to-controller
delegation wrappers: the bond state activated a trial but the behavior
controller never received its approach command. The wrappers fixed both bait
approach and voluntary trial movement. The same smoke then exposed stale
Operator targeting after a rushed trial cancel; the controller now clears its
trial feeder target on cancellation. Both regressions are asserted in the smoke.

The first changed sweep also exposed a smoke-only frame-order race: the fixture
yielded one physics frame after moving the Operator into bait range, allowing
the still-hostile creature to enter `GROUND_STALK` before the safe feed call.
The fixture now calls the API in the same frame as its safe-state setup and
waits on actual feed/cooldown state. A later restore regression ensures a save
loaded onto an active instance discards transient interaction state and clears
remembered Operator hostility when the saved stage is BONDED.
