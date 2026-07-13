# Developer Observatory Code Proposal

Status: proposal
Target feature spec: `design/20_features/in_progress/DEVELOPER_OBSERVATORY_SYSTEM.md`

## Files to add

- `custodian/scripts/debug/dev_observatory.gd`
- `custodian/scripts/debug/dev_observatory_overlay.gd`
- `custodian/scenes/debug/dev_observatory_overlay.tscn`

## Required manual Project Settings change

Add autoload:

- Name: `DevObservatory`
- Path: `res://scripts/debug/dev_observatory.gd`

## Notes

This code is intentionally minimal and safe. It does not require any current combat, player, enemy, or world-state APIs to exist. Those systems can be instrumented incrementally.
