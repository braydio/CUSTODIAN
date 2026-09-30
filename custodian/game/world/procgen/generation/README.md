# Procgen Generation

- Belongs here: generation contexts, level-data builders, candidate evaluation policy and metrics, construction summaries.
- Does not belong here: live actor behavior, HUD pages, persistent campaign mutation.
- Current migration status: `candidate_evaluator.gd` owns candidate measurement, acceptance/rejection, scoring, terrain failure classification, and fallback policy. `procgen_candidate_materializer.gd` validates the selected semantic record and delegates the one final realization to `ProcGenTilemap`. `CustodianContractMap` retains seed/profile/attempt orchestration and creates a fresh final map from captured candidate settings.
- Current source of truth: `candidate_evaluator.gd` for selection policy; `procgen_candidate_materializer.gd` for accepted-candidate handoff validation; `game/world/procgen/proc_gen_tilemap.gd` for runtime topology and final realization.

Runtime topology mutation remains in `ProcGenTilemap`. Its connector dry-run is
also the placement precondition for isolated Ash-Bell pockets, so generation
acceptance and later White Thread commit use one definition of valid geometry.
Cached runtime-health counters are updated only at wall, boundary, navigation,
and terrain mutation sites; Observatory sampling is read-only.
