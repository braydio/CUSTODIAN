---

# AGENTS.md

## CUSTODIAN Architectural Governance Rules

This document governs how AI agents (Codex, ChatGPT, or others) interact with the CUSTODIAN repository.

This is a systems-first deterministic simulation project transitioning toward a playable RTS hybrid colony game.

---

# 1. CANONICAL STRUCTURE

## Code Layer

```plaintext
game/
  simulations/
    world_state/
      core/
      terminal/
      tests/
```

This is the simulation engine.

It must remain deterministic.

No rendering logic belongs here.

---

## Design Layer

```plaintext
design/
```

This is the canonical source of truth for:

- System rules
- Design decisions
- Feature definitions
- Engine transition planning

No duplicate design sources are allowed.

---

## AI Context Layer

```plaintext
ai/
```

This is a projection layer for AI tooling.

It is NOT canonical design.

It must summarize, not redefine.

---

# 2. DOCUMENT HIERARCHY

## 00_foundations

Immutable system principles.

Updated only when core architecture changes.

Examples:

- Determinism guarantees
- Tick ordering rules
- State mutation constraints

---

## 10_systems

One directory per major system.

Each system must have:

- Purpose
- Data model
- Mutation rules
- Invariants
- Cross-system dependencies
- Determinism notes

---

## 20_features

Lifecycle-based feature tracking.

States:

- planned
- in_progress
- completed

Features must move directories when status changes.

No feature document may exist outside this lifecycle.

---

## 30_playable_game

Engine-facing layer.

Contains:

- Player control model
- Drone logic
- RTS layer
- Engine port strategy

Simulation design must not assume rendering engine behavior.

---

# 3. UPDATE RULES

Whenever code changes:

AI must:

1. Identify affected system.
2. Update corresponding design document.
3. Update CHANGELOG.md.
4. Update ai/CURRENT_STATE.md.
5. Verify no duplicate documents created.
6. Confirm invariants still hold.

No code mutation is complete without documentation update.

---

# 4. DETERMINISM ENFORCEMENT

All systems must:

- Avoid unseeded randomness
- Maintain tick-order stability
- Preserve snapshot compatibility
- Include test coverage for new mutation logic

If determinism is modified:

- Update SIMULATION_RULES.md
- Add regression tests

---

# 5. FEATURE ADDITION PROCESS

When adding a feature:

1. Draft under:

   ```
   design/20_features/planned/
   ```

2. Define:
   - Scope
   - System impact
   - Required invariants

3. Move to:

   ```
   in_progress/
   ```

4. After implementation + tests:
   Move to:

   ```
   completed/
   ```

5. Update relevant system document in `10_systems/`

No orphan feature documents allowed.

---

# 6. DOCUMENT SPRAWL PREVENTION

Agents must:

- Merge overlapping documents.
- Archive superseded drafts.
- Never create “FINAL-V2-UPDATED” files.
- Maintain one canonical file per concept.

---

# 7. ENGINE TRANSITION PREPARATION

Simulation must remain:

- Engine-agnostic
- Transport-agnostic
- Input-agnostic

When preparing for engine port:

- Add adapter layer
- Do not embed rendering logic into simulation core

---

# 8. TEST REQUIREMENTS

New system logic requires:

- Unit tests
- Determinism test
- Snapshot compatibility test

Tests must live alongside system in:

```plaintext
world_state/tests/
```

---

# 9. MIGRATION & REFACTOR POLICY

During refactor:

- Update design first.
- Migrate code second.
- Validate invariants third.
- Update AI context last.

---

# 10. FINAL PRINCIPLE

CUSTODIAN is:

- Systems-first
- Deterministic
- Simulation-driven
- Engine-portable

All architectural decisions must reinforce those properties.

---

If you want next, I can:

- Generate a migration checklist Codex can execute step-by-step
- Or simulate what the new design tree would look like after consolidation
- Or define strict doc templates for each system folder to prevent future sprawl
