# Modular Next Actions And DevMode

- Status: `complete`
- Authority: `design/02_features/debug_ui/DEV_MODE_SYSTEM.md`, `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md`, `custodian/tools/validation/contracts/operator_modular_core.json`
- Goal: Centralize runtime developer eligibility and join modular visual-fit evidence to production coverage/drift for actionable grouped recommendations.
- Constraints: Runtime `DevMode` does not govern offline tools; the production contract owns priority/groups; combo reports are generated evidence, never project authority; preserve canonical resolved source paths.
- Completed: DevMode autoload/capabilities and debug-system gates; canonical pair/chain source paths; fit center threshold; report-only backfill; next-actions JSON/Markdown helper; HTML recommendations; timestamp/commit/artifact metadata; tooling-doc drift fixes; focused validation.
- Deferred: `DevBootstrap` conditional instantiation/removal of native ImGui and the remaining debug autoloads.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/dev_mode_smoke.gd
python tools/validation/operator_next_actions_report_smoke.py
```
