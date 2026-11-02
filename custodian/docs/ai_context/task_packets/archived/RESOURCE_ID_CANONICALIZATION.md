# Resource ID Canonicalization

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-16
- Created: 2026-05-16
- Last updated: 2026-05-16

## Task

Normalize resource naming so harvest nodes, `ResourceLedger`, fabrication recipes, and player-facing fabrication UI use CUSTODIAN-flavored resource IDs directly instead of generic `timber`, `ore`, and `scrap` ledger keys.

## Outcome

The live resource economy stores and spends canonical resource IDs such as `blackwood`, `structural_alloy`, and `ruin_scrap`. `node_kind` remains source-object identity, not resource identity.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/02_features/resource_fabrication/RESOURCE_FABRICATION_PIPELINE.md`
- Active runtime/docs files: `custodian/autoload/resource_ledger.gd`, `custodian/content/resources/resource_defs.json`, `custodian/content/fabrication/fab_recipes.json`, `custodian/game/resources/resource_node.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: active resource/fabrication design docs, resource ledger/data, recipe data, resource node enum, fabrication reference doc, AI context pack
- Files or folders expected to be read but not changed: live HUD fabrication rendering, scene-placed resource nodes
- Out-of-scope areas: save/load migration, new production art, procedural resource placement, broader build placement

## Constraints

- Determinism concerns: resource accounting must stay data-driven and deterministic.
- Simulation/UI boundary concerns: UI may display ledger and recipe keys, but `ResourceLedger` remains the accounting authority.
- Asset requirements: no new art required for this naming pass.
- Compatibility or migration concerns: old generic keys should not be canonical; any compatibility aliases must not map flavored IDs back to generic storage.
- Clarifying questions or assumptions: `fiber_moss` is included because the final source-node model calls out `moss_patch` and `fungal_resin_pod` drops, but no current recipe consumes it.

## Implementation Plan

1. Update active design docs and pipeline references to define canonical resource IDs and source-object `node_kind` values.
2. Update ledger/resource metadata/recipes so runtime accounting uses flavored resource IDs directly.
3. Update AI context and reference docs, then run focused headless validation.

## Acceptance

- Runtime behavior: `ResourceLedger.add("blackwood", amount)` stores `blackwood`; recipes consume `blackwood`, `structural_alloy`, `ruin_scrap`, and rare resources directly.
- Documentation: active design docs and AI context no longer describe `blackwood -> timber`, `structural_alloy -> ore`, or `ruin_scrap -> scrap` as the canonical path.
- Path/reference validation: active resource/fabrication references mention the correct files and canonical names.
- Manual validation: search active code/docs for stale generic recipe/resource ledger references.
- Automated/headless validation: run Godot script checks for changed scripts and JSON parse checks where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Canonicalized `ResourceLedger` to store flavored resource IDs directly; retained only forward legacy aliases from `timber`/`ore`/`scrap` to flavored IDs; updated resource metadata, fabrication recipes, resource-node source-kind enums, active design docs, sprite-pipeline examples, AI context, and resource asset specs.
- Validated: Parsed `resource_defs.json` and `fab_recipes.json` with `python -m json.tool`; checked `resource_node.gd` and `resource_ledger.gd` with Godot headless script checks; ran a temporary Godot smoke script confirming `blackwood` is stored canonically and legacy `timber` aliases forward to `blackwood`; booted `godot --headless --path custodian --quit`.
- Deferred: Save/load migration for any future persisted generic keys; procedural placement of the new source nodes; production art for the expanded resource set.

## Next Steps

- Next action: Add procedural/resource placement for new source objects when the resource loop expands beyond hand-placed test nodes.
- Best starting files: `custodian/autoload/resource_ledger.gd`, `custodian/content/resources/resource_defs.json`, `custodian/content/fabrication/fab_recipes.json`
- Required context: active resource fabrication design docs and previous fabrication packets
- Validation to run: playtest harvest prompts and FABRICATION page once the next placement/UI slice is touched.
- Blockers or open questions: none
