# Procgen Phase 0.5: Signal Registry and Projection Infrastructure

## Status

- Lifecycle: `planned`
- Parent roadmap: `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md`
- Prerequisite: Phase 0 instrumentation accepted (or equivalent fingerprint coverage merged)
- Implementation start condition: explicit approval to move this doc to `in_progress`

## Purpose

Establish the canonical signal registry and projection engine infrastructure required for all subsequent procgen phases. This is the foundational vocabulary layer.

Phase 0.5 does not add new gameplay mechanics. It formalizes the existing implicit signal flow into explicit contracts.

## Problem This Phase Solves

Current procgen text rendering is functional but still fragmented for upcoming procgen phases:

1. No formal typed signal registry exists; signal semantics are encoded in ad hoc strings and grammar prefixes.
2. Simulation RNG and text generation are conceptually separate (`rng` vs `text_seed`) but not explicitly modeled via dedicated RNG fields.
3. Projection is scattered across wait-specific helpers rather than a reusable procgen projection entrypoint.
4. Signal suppression logic exists in WAIT but is not represented as a reusable projection contract.
5. Fidelity gating exists, but central projection API for future surfaces is not defined.

## Scope

1. Isolate text RNG from simulation RNG.
2. Create canonical signal registry enum.
3. Formalize projection engine as abstract layer.
4. Add deterministic replay tests.
5. Verify existing WAIT projection is stable.

## Out of Scope

- No new topology generation (Phase 1).
- No threat doctrine changes (Phase 2).
- No economy profile generation (Phase 3).
- No new user-facing command contracts.
- No changes to simulation mechanics.

## Design Constraints

1. Existing simulation behavior must remain 100% identical.
2. Same seed + same command stream = same text output (determinism preserved).
3. Fidelity contract remains canonical discrete levels: `FULL | DEGRADED | FRAGMENTED | LOST`.
4. Signal registry values should be stable and explicit (safe for logging/debugging).
5. Anti-spam suppression remains deterministic and state-tracked in command layer.

## Implementation Plan

### Slice A: RNG Isolation

**Objective:** Make RNG separation explicit without breaking existing call sites.

**Target file:**
- `game/simulations/world_state/core/state.py`

**Current state:**
```python
self.rng = random.Random(self.seed)
self.text_seed = mix_seed64(self.seed, "text")
```

**Implementation:**
1. Add `self.sim_rng` as the canonical simulation RNG.
2. Keep `self.rng` as a backward-compatible alias to avoid broad churn in this phase.
3. Add `self.text_rng` initialized from `text_seed` for explicit text RNG ownership.
4. Do not alter simulation mechanics or RNG consumption order in core loops.

**Verification:**
- Run full pytest suite
- Confirm identical test pass count
- Confirm no diff in simulation outcomes

---

### Slice B: Canonical Signal Registry

**Objective:** Create typed signal registry as source of truth.

**Target file to create:**
- `game/procgen/signals.py`

**Structure:**
```python
from enum import Enum

class Signal(Enum):
    ASSAULT_INBOUND = "ASSAULT_INBOUND"
    ASSAULT_WARNING = "ASSAULT_WARNING"
    ASSAULT_ACTIVE = "ASSAULT_ACTIVE"
    EVENT_DETECTED = "EVENT_DETECTED"
    REPAIR_COMPLETED = "REPAIR_COMPLETED"
    STATUS_DECLINING = "STATUS_DECLINING"
    RELAY_ACTIVITY = "RELAY_ACTIVITY"
    FABRICATION_ACTIVITY = "FABRICATION_ACTIVITY"
```

**Rules:**
- Use explicit string values
- Group by category with comments/docstrings
- No gameplay mechanics encoded
- Add docstring explaining purpose

**Verification:**
- File imports cleanly
- Existing tests pass unchanged

---

### Slice C: Projection Engine Formalization

**Objective:** Abstract projection into formal layer.

**Target file to create:**
- `game/procgen/projection.py`

**Structure:**
```python
from typing import Iterable
from game.procgen.signals import Signal
from game.procgen.engine import GrammarEngine, load_grammar_bank
from game.simulations.world_state.core.state import GameState

_GRAMMAR_PATH = ...  # Same as procgen_text.py
_GRAMMAR_BANK = load_grammar_bank(_GRAMMAR_PATH)
_GRAMMAR_ENGINE = GrammarEngine(_GRAMMAR_BANK)

def project(
    signals: Iterable[Signal],
    fidelity: str,
    state: GameState,
) -> list[str]:
    # Deterministic projection with fidelity gating.
    ...
```

**Rules:**
- Support canonical fidelity labels (`FULL|DEGRADED|FRAGMENTED|LOST`)
- Reuse existing grammar bank and state variant memory
- Return deterministic lines only; no state mutation beyond variant memory
- Do not modify existing command handlers in this phase

**Verification:**
- File imports cleanly
- Existing `procgen_text.py` functions continue to work unchanged

---

### Slice D: WAIT Migration Verification

**Objective:** Verify existing WAIT projection is stable and uses correct seeds.

**Target file:**
- `game/simulations/world_state/terminal/procgen_text.py`

**Current state:**
- Uses `text_seed` deterministic hashing and per-line salts
- Uses `variant_memory` on state

**Verification needed:**
1. Confirm `render_wait_event_line()` stays deterministic with `text_seed` + salt
2. Confirm fidelity gating works (returns None for LOST)
3. Confirm semantic suppression remains active (`WAIT` signal-key + variant-memory behavior)

**Changes:** None required if verification passes.

---

### Slice E: Deterministic Replay Tests

**Objective:** Guarantee projection does not affect simulation determinism.

**Target file to create:**
- `game/simulations/world_state/tests/test_procgen_determinism.py`

**Tests required:**

```python
def test_same_seed_same_output():
    """Same seed/text seed and same sequence yields identical projected lines."""

def test_text_rng_does_not_affect_sim():
    """Text RNG consumption does not change simulation evolution."""

def test_different_seed_different_output():
    """Different text seeds can produce different deterministic phrasing."""
```

**Rules:**
- Tests must be fast (<2 seconds each on typical dev machine)
- Prefer targeted deterministic helper calls over long tick loops
- Do not mutate code/assets inside tests

---

## Test Plan

### Slice Tests

| Slice | Test | Pass Criteria |
|-------|------|---------------|
| A | `pytest` full suite | 100% identical pass count |
| B | Import test | `from game.procgen.signals import Signal` works |
| C | Import test | `from game.procgen.projection import project` works |
| D | Existing tests | `test_wait_*` pass |
| E | New tests | Determinism and RNG-isolation tests pass |

### Regression Tests

1. Existing snapshot tests pass
2. Existing terminal contract tests pass
3. No behavior changes in simulation

---

## Acceptance Criteria

Phase 0.5 is complete when all are true:

1. ✅ `state.sim_rng` and `state.text_rng` are isolated
2. ✅ `game/procgen/signals.py` exists with Signal enum
3. ✅ `game/procgen/projection.py` exists with project() function
4. ✅ WAIT projection verified stable
5. ✅ Determinism tests added and passing
6. ✅ Zero simulation behavior changes
7. ✅ Full pytest suite unchanged

---

## Relationship to Other Phases

| Phase | Dependency |
|-------|------------|
| Phase 0 (Instrumentation) | Should merge first so fingerprints can include projection capability metadata |
| Phase 1 (Topology) | Uses Signal enum for topology events |
| Phase 2 (Threat Doctrine) | Uses Signal enum for assault events |
| Phase 3 (Economy) | Uses Signal enum for infrastructure events |

---

## Review Checklist

- [ ] Does RNG isolation preserve 100% simulation behavior?
- [ ] Are all Signal enum values full-name (no shorthand)?
- [ ] Does projection.py support fidelity gating natively?
- [ ] Are determinism tests fast and reproducible?
- [ ] Is this document instructional and free of guessing?
