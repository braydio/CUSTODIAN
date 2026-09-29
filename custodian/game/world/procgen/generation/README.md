# Procgen Generation

- Belongs here: generation contexts, level-data builders, candidate evaluation policy and metrics, construction summaries.
- Does not belong here: live actor behavior, HUD pages, persistent campaign mutation.
- Current migration status: `candidate_evaluator.gd` owns candidate measurement, acceptance/rejection, scoring, terrain failure classification, and fallback policy. `CustodianContractMap` retains seed/profile/attempt orchestration and final winner handoff.
- Current source of truth: `game/world/procgen/generation/candidate_evaluator.gd` for selection policy; `game/world/procgen/proc_gen_tilemap.gd` for candidate construction and runtime topology.

Runtime topology mutation remains in `ProcGenTilemap`. Its connector dry-run is
also the placement precondition for isolated Ash-Bell pockets, so generation
acceptance and later White Thread commit use one definition of valid geometry.
Cached runtime-health counters are updated only at wall, boundary, navigation,
and terrain mutation sites; Observatory sampling is read-only.
