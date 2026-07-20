# Idea Codex Index

This index tracks non-runtime ideas only. It does not replace active implementation specs. Cards with `Runtime: live` have corresponding runtime code but remain non-authoritative — use the active design specs and `custodian/docs/ai_context/CURRENT_STATE.md` for build truth.

## Core Files

- `README.md` - purpose, authority boundary, workflow, status values, and graduation rules
- `01_hall_of_great_ideas.md` - strongest unbuilt ideas worth revisiting
- `02_backlog.md` - one-line capture list for seeds
- `03_graduated.md` - record of cards moved into active implementation specs
- `templates/IDEA_CARD.md` - card template

## Categories

- `ai/`
- `animation/`
- `audio/`
- `combat/`
- `experiments/`
- `lore/`
- `rendering/`
- `simulation/`
- `tooling/`
- `world/`

## Cards

| Card | Status | Priority | Maturity | Runtime |
|---|---|---|---|---|
| `tooling/developer_observatory.md` | candidate | P0 | system | live |
| `ai/director_memory.md` | candidate | P1 | system | |
| `world/world_state_graph.md` | candidate | P0 | system | live |
| `world/persistent_world_history.md` | candidate | P0 | system | live |
| `world/world_autopsy.md` | candidate | P0 | system | |
| `world/encounter_language.md` | candidate | P0 | system | |
| `world/mystery_budget.md` | candidate | P0 | vibe | |
| `world/ambient_scheduler.md` | candidate | P2 | system | |
| `world/landmark_hierarchy.md` | candidate | P1 | system | |
| `world/spatial_compression.md` | candidate | P1 | mechanic | |
| `simulation/interest_management.md` | triaged | P1 | system | live |
| `simulation/navigation_combat_heatmaps.md` | candidate | P1 | system | live |
| `simulation/simulation_camera.md` | candidate | P2 | system | |
| `ai/ai_morale_cohesion_system.md` | candidate | | card | |
| `ai/faction_knowledge_system.md` | candidate | | card | |
| `simulation/sector_activity_simulator.md` | candidate | | card | |
| `tooling/developer_replay_system.md` | candidate | | card | |
| `tooling/performance_budget_manager.md` | candidate | | card | |
| `world/line_of_communication_graph.md` | candidate | | card | |
| `world/material_intelligence_system.md` | candidate | | card | |
| `world/procedural_ruin_generator.md` | candidate | | card | |
| `world/resource_economy_graph.md` | candidate | | card | |
| `world/world_event_timeline.md` | candidate | | card | |

## Active-Spec Cross-Check

Some initial cards now overlap with live implementation specs and runtime systems. Treat those cards as parking-lot framing only; use the active specs and runtime context for build truth:

- `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`
- `design/01_systems/WORLD_STATE_GRAPH_SYSTEM.md`
- `design/01_systems/WORLD_HISTORY_SYSTEM.md`
- `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`
- `design/01_systems/SECTOR_HEATMAP_SYSTEM.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`

## Wave History

Wave 3 (2026-07-08) — Technical Systems — all 10 cards disseminated into category folders above. Staging receipt removed; cards are canonical in their category folders.
