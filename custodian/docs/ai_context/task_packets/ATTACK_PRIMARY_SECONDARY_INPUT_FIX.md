# ATTACK PRIMARY SECONDARY INPUT FIX TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Fix M1 attack input so plain M1 triggers the primary fast attack path and only Shift+M1 triggers secondary heavy attack.

## Outcome

`attack_primary` remains plain M1, while `attack_secondary` is no longer also plain M1. Operator input ordering can keep checking secondary first because secondary now requires the shift modifier.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime files: `custodian/project.godot`, `custodian/game/actors/operator/operator.gd`
- Active context docs: `custodian/docs/ai_context/CURRENT_STATE.md`

## Work Surface

- Files expected to change: `custodian/project.godot`, AI context task packet/index.
- Files inspected: operator attack input and combat intent code.
- Out of scope: retuning fast/heavy animation timing or weapon definitions.

## Constraints

- Plain M1 must not satisfy both primary and secondary in the same frame.
- Existing operator secondary-first branch should remain valid for chorded input.

## Implementation Plan

1. Confirm current input map bindings for primary and secondary attack.
2. Change `attack_secondary` from plain M1 to Shift+M1.
3. Validate project/script parsing.
4. Update packet status and docs.

## Acceptance

- Plain M1 maps to `attack_primary`, not `attack_secondary`.
- Shift+M1 maps to `attack_secondary`.
- Operator script still parses.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No, existing state already documents the intended input split.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does any design doc need an update? No.

## Completion Notes

- Implemented: changed `attack_secondary` from plain M1 to Shift+M1 in `project.godot`; `attack_primary` and the legacy `attack` action remain plain M1.
- Validated: `godot --headless --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --quit`.
- Deferred: existing headless exit leak warnings remain unrelated to this input-map fix.

## Next Steps

- Next action: live-test M1 and Shift+M1 in melee/unarmed loadouts to confirm animation selection feels correct.
