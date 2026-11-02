# ENGINE TRANSITION STRATEGY

Status: Transition Complete
Last updated: 2026-03-04

## Outcome

CUSTODIAN has completed its primary architecture transition to Godot 4.x native runtime.
The Python terminal stack is retained as a legacy reference and debug aid.

## Current Execution Model

- Primary development target: `custodian/` (Godot project)
- Legacy reference target: `python-sim/` (terminal-era simulation and docs)
- Design doctrine authority: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`

## Migration Rules Going Forward

1. New gameplay/system implementation happens in Godot.
2. Python runtime changes are limited to archival/reference maintenance unless explicitly requested.
3. Cross-check major mechanical ports against legacy deterministic intent where applicable.
4. Documentation must clearly label active vs legacy authority.

## Remaining Transition Work

- Port prioritized legacy mechanics (assault, infrastructure, ARRN relay, save pipeline) into Godot systems.
- Keep terminal-specific contracts archived under `design/archive/terminal-deprecated/`.
- Maintain one canonical active architecture narrative across `README`, `ai/*`, and `design/00_foundations/*`.
