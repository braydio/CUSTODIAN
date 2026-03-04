# ENGINE PORT PLAN

Status: Superseded by Godot-native runtime
Last updated: 2026-03-04

## Summary

The original "port" plan is no longer active. The primary game runtime is already Godot-native.

## Active Plan

1. Implement all net-new gameplay systems directly in `custodian/`.
2. Use `python-sim/` only for historical reference and migration parity checks.
3. Maintain deterministic simulation design in fixed-step Godot systems.
4. Build save/load, assault loop, and infrastructure systems natively in GDScript.

## Active Deliverables

- Godot architecture and module boundaries (`custodian/docs/ARCHITECTURE.md`)
- GDScript coding standards (`custodian/docs/GDSCRIPT_STANDARDS.md`)
- Scene hierarchy contract (`custodian/docs/SCENE_HIERARCHY.md`)

## Legacy Artifacts

Terminal transport adapters and `/command` contract docs are archived under:

- `python-sim/design/archive/terminal-deprecated/`
