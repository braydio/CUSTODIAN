# Fabrication Terminal Hierarchy And Fit

- Status: `complete`
- Authority: `design/02_features/terminal/BLACK_RELIQUARY_UI.md`
- Goal: Make Fabrication work orders scannable, keep selection/detail state coherent, and fit all actions within the terminal viewport.
- Files: `game/ui/hud/ui.gd`, `game/ui/terminal/fabrication_terminal_view_model.gd`, `scenes/game.tscn`, focused terminal validation scripts, and active state/index docs.
- Constraints: Presentation-only; no fabrication backend changes, no horizontal scrolling, no new required art.
- Acceptance: Flat field-based rows, visible selected-row match, resource grid, collapsed empty status, reachable navigation, visible bottom actions, and missing terminal assets recorded by `DevObservatory`.
- Completed: Runtime and view-model changes, documentation drift remediation, and focused headless validation.
- Deferred: Interactive category filtering and broader build-token deployment remain future Fabrication work.
