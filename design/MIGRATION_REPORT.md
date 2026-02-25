# Migration Report

Date: 2026-02-25
Reference: `design/MIGRATION.md`

## Merged / Canonicalized

- Architecture canon -> `design/00_foundations/ARCHITECTURE.md`
  - Source: `docs/_ai_context/ARCHITECTURE.md`
- Simulation rules canon -> `design/00_foundations/SIMULATION_RULES.md`
  - Source: `docs/_ai_context/SIMULATION_RULES.md`
- Core principles canon -> `design/00_foundations/CORE_DESIGN_PRINCIPLES.md`
  - Source: `docs/Broad_Overview_Design_Rules.md`
- Engine transition strategy canon -> `design/00_foundations/ENGINE_TRANSITION_STRATEGY.md`
  - Source: `docs/ROADMAP.md`
- Assault canon -> `design/10_systems/assault/ASSAULT_DESIGN.md`
  - Source: `feature_planning/ASSAULT-RESOURCE-LINK-V2.md`
- Infrastructure canon -> `design/10_systems/infrastructure/INFRASTRUCTURE_DESIGN.md`
  - Source: `feature_planning/INFRASTRUCTURE.md`
- Policy layer canon -> `design/10_systems/infrastructure/POLICY_LAYER.md`
  - Source: `feature_planning/INFRASTRUCTURE_POLICY_LAYER-FINAL.md`
- Power systems canon -> `design/10_systems/infrastructure/POWER_SYSTEMS.md`
  - Source: `feature_planning/POWER_SYSTEMS.md`
- Repair mechanics canon -> `design/10_systems/infrastructure/REPAIR_MECHANICS.md`
  - Source: `feature_planning/REPAIR_MECHANICS.md`

## Archived

- Audit docs -> `design/archive/audit/`
  - from `docs/audit/*`
- Superseded/draft planning variants -> `design/archive/deprecated/`
  - `FEATURE_CLEANUP_FINALIZE*.md`
  - `INFRASTRUCTURE_POLICY_LAYER.md`
  - `INFRASTRUCTURE-REVIEW-CHECK-STATE.md`
  - `RECOMMENDED_IMROVEMENTS.md`
  - `UI_RECOMMENDS_INSTRUCT.md`
  - `_check-completion-ASSAULT-RESOURCE-LINK.md`
- Historical docs + root artifacts -> `design/archive/historical/`
  - legacy docs from `docs/*`
  - legacy AI context not retained in `ai/`
  - `IMPLEMENTATION*.txt`, `COMMANDS.txt`
  - prior assault roadmap snapshot `feature_planning/ASSAULT-RESOURCE-LINK.md`

## Removed

- `docs/` directory (fully migrated)
- `feature_planning/` directory (fully migrated)

## Renamed / Relocated Highlights

- `feature_planning/CODEX-FEATURE-RECOMMEND.md` -> `design/20_features/planned/ARRN_FEATURE_RECOMMENDATIONS.md`
- `feature_planning/ENGINE-DESIGN-IMPLEMENTATION.md` -> `design/10_systems/procgen/ENGINE_DESIGN_IMPLEMENTATION.md`
- `docs/CommandCenter.md` -> `design/10_systems/hub_campaign/COMMAND_CENTER.md`
- `docs/INFORMATION_DEGRADATION.md` -> `design/10_systems/procgen/INFORMATION_DEGRADATION.md`

## AI Projection Layer

- `ai/CONTEXT.md` (from primer, updated path references)
- `ai/CURRENT_STATE.md`
- `ai/FILE_INDEX.md`

## Notes

- Migration was documentation-only.
- Runtime code was not modified as part of this migration task.
