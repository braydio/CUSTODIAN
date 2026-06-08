## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-07
- Created: 2026-06-07
- Last updated: 2026-06-07

## Task

Replace the sample inventory overlay with a professional live CUSTODIAN
inventory UI and a stable production-asset drop-in contract.

## Outcome

The mounted inventory overlay uses Black Reliquary styling, reads the live
`InventoryManager`, supports item categories/details/focus, and automatically
uses canonical production assets when they appear at documented runtime paths.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/20_features/in_progress/BLACK_RELIQUARY_UI.md`
- Active runtime/docs files: `custodian/game/ui/inventory/`, `custodian/content/ui/inventory/`, `custodian/game/systems/core/systems/inventory_manager.gd`
- Historical reference only: legacy Python runtime and older no-full-inventory Shrumb scope

## Work Surface

- Files or folders expected to change: inventory UI scene/scripts/assets contract, Black Reliquary catalog/docs, validation, current state/index, required asset trackers
- Files or folders expected to be read but not changed: live item/resource data and game scene mounting
- Out-of-scope areas: drag/drop equipment, fabrication UI, resource-ledger merging, save/load changes

## Constraints

- Determinism concerns: UI sorting/category grouping must be stable
- Simulation/UI boundary concerns: inventory presentation reads ledger state but does not own gameplay item authority
- Asset requirements: no invented production art; canonical paths must fall back to existing assets
- Compatibility or migration concerns: preserve isolated local `Inventory` support while making `InventoryManager` the live source
- Clarifying questions or assumptions: “inventory” means carried item ledger, not resource/build-token storage

## Implementation Plan

1. Define canonical inventory assets and item metadata resolution.
2. Rebuild and connect the live overlay.
3. Add smoke validation and update docs/asset requests.

## Acceptance

- Runtime behavior: overlay opens from inventory input, reflects live ledger changes, filters and selects items, and closes safely
- Documentation: canonical asset paths and remaining production asks are explicit
- Path/reference validation: scene/catalog/manifest paths resolve or intentionally fall back
- Manual validation: deferred to visual in-editor review
- Automated/headless validation: dedicated inventory smoke and game/UI load checks

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? Yes

## Completion Notes

- Implemented: live InventoryManager-backed Black Reliquary field ledger, deterministic categories and item metadata, selected-item detail inspector, input/focus handling, canonical production asset manifest/resolver, fallback assets, docs, and production asset requests
- Validated: inventory script/catalog check-only, dedicated inventory UI smoke, Black Reliquary UI smoke, manifest JSON parse, required asset tracker parity, full game headless boot, and scoped diff check
- Deferred: production inventory art, in-editor visual review, equipment/drag-drop/use/drop actions, and any deliberate resource/build-token ledger views

## Next Steps

- Next action: perform in-editor visual review and replace fallback textures as production inventory art arrives
- Best starting files: `custodian/game/ui/inventory/inventory_ui.gd`
- Required context: Black Reliquary styles and InventoryManager API
- Validation to run: rerun `inventory_ui_smoke.gd` after asset drops; inspect the overlay at target resolutions in-editor
- Blockers or open questions: automated screenshot capture is unavailable through the current headless dummy renderer
