# SIMULATION RULES — CUSTODIAN

## Time

- World mutation is tick-based and explicit.
- In terminal mode, only time-bearing commands advance world time.
- `STATUS` and other read/config commands do not advance time.

## State Authority

- `GameState` is authoritative and mutated server-side only.
- Frontend rendering must not infer or apply gameplay mutations.

## Assault Lifecycle

- Approaches traverse spatial ingress routes before tactical engagement.
- Transit interception can reduce incoming threat budget prior to engagement.
- Active assaults resolve across multiple tactical ticks.

## Repair and Fabrication

- Repair progression and fabrication ticking happen in world stepping.
- Power/fidelity/assault conditions can change repair and detection outcomes.

## Information Fidelity

- Comms fidelity gates what operators can see in `WAIT` and `STATUS`.
- Fidelity changes emit diegetic signal events (`SIGNAL CLARITY RESTORED`, `SIGNAL DEGRADATION DETECTED`).

## Output Tone

- Keep output terse, operational, and diegetic.
- Avoid meta-system phrasing in player-facing lines.
