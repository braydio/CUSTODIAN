# PLAYER CONTROL MODEL

## Scope
- Define operator control semantics for a playable RTS layer without changing simulation authority.

## Constraints
- Backend remains authoritative for all world mutation.
- UI/client input maps to existing command contract semantics.
- Deterministic outcomes must remain stable under fixed seed and command sequence.

## Near-Term Focus
- Define command abstraction for mixed terminal + RTS input.
- Preserve command/field authority split in any playable interface.
