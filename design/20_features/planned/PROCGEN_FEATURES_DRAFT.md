
Good.
We are going to do this correctly.

Below are **production-grade Codex instruction blocks**, written to:

* Preserve determinism
* Respect the terminal contract in AGENTS.md 
* Stay aligned with current unified backlog state 
* Avoid gameplay drift
* Avoid simulation behavior change

Each block is atomic.
Do **not** merge slices.
Run tests after each.

---

# 🔷 SLICE 1 — RNG Isolation (Zero Behavior Change)

## Objective

Introduce `text_rng` to isolate procedural projection randomness from simulation RNG.

Simulation behavior must remain 100% identical.

---

## Codex Instruction Block

```
TASK: Isolate text RNG from simulation RNG without altering simulation behavior.

FILES:
- game/simulations/world_state/core/state.py

REQUIREMENTS:

1. Locate world state initialization where RNG is seeded.
   There is currently a seeded RNG used for simulation (likely self.rng or similar).

2. Rename that RNG to:
   self.sim_rng

3. Introduce a second RNG:
   self.text_rng

   It must be seeded deterministically but independently.

   Use:
       self.text_rng = random.Random(self.seed ^ 0xBEEFCAFE)

   (Assume self.seed exists; if not, derive from existing seed source.)

4. Ensure:
   - All simulation logic uses self.sim_rng.
   - No existing code uses text_rng yet.
   - No behavior changes occur.

5. DO NOT:
   - Change any simulation calls.
   - Modify function signatures.
   - Change assault logic.
   - Change event ordering.
   - Modify tests.

6. After change:
   - Run full pytest.
   - Confirm 100% identical test pass count.
   - Confirm no diff in simulation outcomes.

OUTPUT:
- Minimal diff.
- No refactor beyond RNG rename.
```

---

# 🔷 SLICE 2 — Canonical Signal Registry

## Objective

Introduce a typed, centralized signal system.
No gameplay wiring yet.

---

## Codex Instruction Block

```
TASK: Introduce canonical signal registry for procedural projection.

FILES TO CREATE:
- game/procgen/signals.py

CONTENT REQUIREMENTS:

1. Use Python Enum.
2. Use auto() for values.
3. Group signals by category.

Include:

Assault:
    ASSAULT_INBOUND
    ASSAULT_INTERCEPTED
    ASSAULT_BREACH
    ASSAULT_REPULSED

Infrastructure:
    POWER_STRAIN
    POWER_FAILURE
    FAB_THROUGHPUT_REDUCED
    REPAIR_DELAY

Relay:
    RELAY_UNSTABLE
    RELAY_STABILIZED
    RELAY_SYNC_COMPLETE

Tick:
    SECTOR_DECAY
    THREAT_ESCALATION

4. Add docstring at top explaining:
   - Signals represent semantic simulation events.
   - They are projection inputs.
   - They must not encode gameplay mechanics.

5. Do NOT:
   - Wire signals into simulation yet.
   - Modify existing files.

6. Add minimal import-safe structure.

OUTPUT:
- New file only.
```

Run tests (should remain unchanged).

---

# 🔷 SLICE 3 — Projection Engine Skeleton

## Objective

Create projection abstraction layer without modifying existing surfaces.

---

## Codex Instruction Block

```
TASK: Create projection engine skeleton.

FILES TO CREATE:
- game/procgen/projection.py

REQUIREMENTS:

1. Define function:

   def project(signals: list[Signal], fidelity: float, state) -> list[str]:

2. Import:
   - Signal enum
   - typing
   - state.text_rng

3. For now:
   - Return empty list.

4. Add TODO comments:
   - Grammar selection
   - Fidelity gating
   - Anti-spam suppression

5. DO NOT:
   - Modify existing command handlers.
   - Modify WAIT.
   - Modify assault.

6. Ensure file imports cleanly.
```

Tests should still pass.

---

# 🔷 SLICE 4 — Migrate WAIT to Projection Layer

## Objective

Move WAIT messaging to use projection abstraction.

No change in semantics.

---

## Codex Instruction Block

```
TASK: Route WAIT command messaging through projection layer.

FILES:
- game/simulations/world_state/terminal/commands/wait.py

STEPS:

1. Identify where WAIT currently generates procedural text.

2. Replace direct grammar calls with:

   signals = [Signal.SECTOR_DECAY]  # or equivalent based on existing event mapping

   lines = project(signals, fidelity=state.comms_fidelity, state=state)

3. Maintain:
   - Same primary CommandResult.text line.
   - Same ordering.
   - Same fidelity redaction behavior.

4. DO NOT:
   - Change simulation tick logic.
   - Change state mutation.
   - Introduce new randomness.
   - Remove existing text until projection fully matches behavior.

5. Add temporary compatibility fallback:
   If project() returns empty list:
       use previous WAIT text logic.

6. Run full pytest.
7. Verify deterministic output remains identical.
```

---

# 🔷 SLICE 5 — Deterministic Replay Tests

## Objective

Guarantee projection does not affect simulation determinism.

---

## Codex Instruction Block

```
TASK: Add deterministic replay test harness.

FILES TO CREATE:
- game/simulations/world_state/tests/test_procgen_determinism.py

TESTS REQUIRED:

1. test_same_seed_same_output:
   - Run 500 WAIT ticks twice with same seed.
   - Capture projection output.
   - Assert identical output.

2. test_different_seed_same_sim_state:
   - Run simulation with seed A and B.
   - Assert final simulation state identical.
   - Allow projection phrasing to differ.

3. test_text_rng_does_not_affect_sim:
   - Capture sim state after 100 ticks.
   - Confirm altering projection code does not change sim outcome.

DO NOT:
   - Mock simulation internals.
   - Skip fidelity gating.
   - Use randomness outside state.text_rng.

Ensure tests are fast (<2 seconds).
```

---

# 🔷 SLICE 6 — Assault Summary Migration

## Objective

Move assault after-action narration to projection layer.

---

## Codex Instruction Block

```
TASK: Replace assault summary templating with signal projection.

FILES:
- game/simulations/world_state/core/assaults.py
- relevant command handler returning assault result

STEPS:

1. Identify final assault outcome branch:
   - repelled
   - breached
   - intercepted

2. Replace hardcoded summary lines with:

   signals = [appropriate Signal enums]
   lines = project(signals, fidelity=state.comms_fidelity, state=state)

3. Preserve:
   - CommandResult contract.
   - text primary line.
   - ordering of detail lines.

4. Ensure:
   - No simulation logic changes.
   - No timing changes.
   - No RNG changes in sim path.

5. Run full pytest.
6. Verify assault tests pass.
```

---

# 🔷 SLICE 7 — Infrastructure Event Projection

## Objective

Unify infrastructure messages under signal system.

---

## Codex Instruction Block

```
TASK: Route infrastructure event messaging through projection system.

FILES:
- core/power.py
- core/fabrication.py
- core/logistics.py
- relay handlers

STEPS:

1. Identify text emission points.
2. Replace direct message strings with:

   signals = [...]
   lines = project(...)

3. Preserve exact semantics.
4. Maintain CommandResult.text integrity.
5. Do not modify policy math.
6. Run pytest.
```

---

# 🔷 SLICE 8 — Fidelity Redaction Formalization

## Objective

Centralize fidelity gating inside projection layer.

---

## Codex Instruction Block

```
TASK: Implement fidelity redaction rules inside projection engine.

FILES:
- game/procgen/projection.py

RULES:

1. If fidelity < 0.4:
   - remove sector identifiers
   - generalize threat descriptors

2. If fidelity < 0.2:
   - collapse detail lines into generic operational alerts

3. Never fabricate information.
4. Never remove signals entirely.
5. Never contradict simulation state.

Add unit tests validating:
- high fidelity shows full detail
- low fidelity redacts correctly
- determinism preserved
```

---

# 🔷 SLICE 9 — Anti-Spam Suppression Formalization

## Objective

Prevent repeated semantic spam under variant phrasing.

---

## Codex Instruction Block

```
TASK: Add semantic suppression layer to projection.

FILES:
- projection.py
- state.py (store last_emitted_signals)

RULES:

1. Track recently emitted signals.
2. Suppress identical signal within N ticks.
3. Use state-based tracking.
4. Suppression must not affect simulation.
5. Deterministic.
```

---

# 🔷 Execution Order (Do Not Deviate)

1. RNG Isolation
2. Signal Registry
3. Projection Skeleton
4. WAIT Migration
5. Determinism Tests
6. Assault Migration
7. Infrastructure Migration
8. Fidelity Formalization
9. Suppression Layer

---

# Final Recommendation

Do not hand all slices to Codex at once.

Give:

* Slice 1
* Run tests
* Audit diff
* Continue

CUSTODIAN’s strength is deterministic integrity.

We protect that first.

---

If you want, next I can:

* Review Slice 1 diff after Codex runs it
* Or pre-draft the full projection engine implementation (grammar + fidelity + suppression fully wired)
* Or formally integrate this into your DEVLOG update format
