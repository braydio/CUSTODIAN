# CUSTODIAN Developer Observatory Starter

This bundle starts the first high-value CUSTODIAN tooling system: Developer Observatory.

## What this includes

- A docs-first feature spec
- A code proposal note
- A Godot autoload script
- A Godot overlay scene
- A debug overlay script
- Instrumentation examples
- A CURRENT_STATE note
- Optional Python helper to inject the autoload

## Drop paths

Copy the folders into repo root so paths line up:

- `design/...`
- `custodian/...`
- `scripts/...`

## Required Project Settings step

Add autoload:

- Name: `DevObservatory`
- Path: `res://scripts/debug/dev_observatory.gd`

Or run:

`python scripts/install_dev_observatory_starter.py`

## First validation

1. Launch project.
2. Press F9.
3. Confirm overlay appears.
4. Instrument one player damage/death event.
5. Confirm events appear.

## Important

This is not the full telemetry/replay/heatmap implementation. This is the shared first brick.
