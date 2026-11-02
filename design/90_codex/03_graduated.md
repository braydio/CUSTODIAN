# Graduated Ideas

Graduated ideas have moved from parking-lot cards into active implementation specs.

Do not treat this file as runtime truth. It is an audit trail that points to the real spec.

| Idea | Graduated To | Date | Notes |
|---|---|---|---|
| Developer Observatory | `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md` | before 2026-07-08 | First F9 observability/runtime telemetry foundation is live; use active spec and `CURRENT_STATE.md` as authority. |
| World State Graph | `design/01_systems/WORLD_STATE_GRAPH_SYSTEM.md` | before 2026-07-08 | Keyed reactive world-state autoload is live. |
| Persistent World History | `design/01_systems/WORLD_HISTORY_SYSTEM.md` | before 2026-07-08 | In-memory sector event journal is live. |
| Interest Management | `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md` | before 2026-07-08 | First distance-tier classifier is live. |
| Navigation and Combat Heatmaps | `design/02_features/debug_ui/NAVIGATION_COMBAT_HEATMAP_REPORTING.md` | 2026-07-24 | Runtime seed: `custodian/game/systems/world/sector_heatmap.gd`. First production slice records developer-only heatmap events, includes them in Observatory exports, and reports them through the session analyzer. |
| Material Intelligence System | `design/02_features/world/MATERIAL_INTELLIGENCE_SYSTEM.md` | 2026-07-24 | Runtime seed: `custodian/game/systems/world/material_intelligence.gd`. First slice provides typed world-position material lookup, contact telemetry, Heatmap tagging, and Observatory analyzer reporting. |
