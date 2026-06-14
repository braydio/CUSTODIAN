# Fabrication Terminal Readability Pass

- Status: `complete`
- Authority: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`
- Goal: Turn the player-facing FABRICATION terminal into a work-order screen that translates raw fabrication state into decisions, ready builds, and concrete next actions.
- Files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/terminal/fabrication_terminal_view_model.gd`, `custodian/game/systems/core/systems/turret_placement.gd`, `custodian/autoload/fab_pipeline.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/autoload/build_inventory.gd`, docs/context updates, validation.
- Constraints: Keep simulation authority in the fabrication autoloads; treat the terminal as a presentation/translation layer; preserve current recipe/token backend behavior; use player-facing terms like Work Order and Ready Build.
- Acceptance: FABRICATION shows status, next action, available work orders, selected work order detail, queue, ready builds, and tiny command help; raw dictionaries/IDs are not the primary UI; `BUILD PLACE <ready_build_id>` works as a terminal alias for the existing placement bridge; docs reflect the live flow.
- Completed:
- Implemented a player-facing FABRICATION work-order translation layer in `custodian/game/ui/terminal/fabrication_terminal_view_model.gd`.
- Refined the terminal wording and sorting so deployable ready builds rise first, stored ready builds are labeled honestly, and the FABRICATION page now shows richer recipe purpose/result text for barricade, power, sensor, archive, and support outputs instead of collapsing everything into one turret-only model.
- Updated `custodian/game/ui/hud/ui.gd` to render the work-order layout, teach `BUILD PLACE <ready_build_id>`, and route `BUILD PLACE` into turret placement via the existing build-token bridge.
- Added `custodian/tools/validation/fabrication_terminal_readability_smoke.gd` and validated it against the live autoloads.
- Deferred:
