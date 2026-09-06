# Codex Task Packet Guide

**Purpose:** Keep Codex implementation work precise, reviewable, and cheap to reason about as CUSTODIAN grows. This guide governs how implementation tasks should be written, not how gameplay itself must be designed.

## Core Rule

A Codex task should specify the **smallest coherent implementation slice** that achieves the requested behavior while leaving the project simpler, or at least no more coupled, than before.

Prefer:

```text
one subsystem
+ explicit integration seams
+ exact behavioral contract
+ focused validation
```

over multi-system milestone packets.

## 1. Write implementation contracts, not essays

Codex instructions should primarily contain:

- the behavior to implement;
- the authority/file or subsystem that should own it when known;
- concrete target values or data contracts;
- invariants and edge cases;
- explicit non-goals;
- focused tests and acceptance criteria.

Include rationale only when it prevents a likely wrong architectural choice. Do not spend large sections explaining subjective game feel when the required code behavior can be stated directly.

## 2. Keep task scope atomic

Split a broad design change into sequential patches when independent parts can be implemented and validated separately.

Example:

```text
Patch A: impact presentation
Patch B: melee cadence
Patch C: enemy attack cadence
Patch D: dodge economy
```

Do not combine them merely because they were discussed in one design session.

Each task should have one primary subsystem owner and only the integration seams necessary to make that change production-ready.

## 3. Do not grow god files by default

`operator.gd` and `enemy.gd` are integration boundaries, not preferred homes for new large gameplay systems.

For future work:

- small orchestration/delegation changes are acceptable;
- substantial new stateful behavior should prefer a focused controller/component/resource;
- new feature work should aim for zero or negative net growth in large authority files when practical;
- do not extract random helpers that still depend on large numbers of private variables. Extract a complete stateful authority with a narrow API.

If a task would add a large new block to a god file, Codex should first consider whether an existing controller can own it or whether a focused controller is warranted.

## 4. One mechanic, one authority

Do not create parallel sources of truth.

A mechanic should have one clear owner for state and mutation. Other systems may query it, request actions from it, or subscribe to signals, but should not independently maintain competing versions of the same state.

Examples of healthy ownership:

```text
Dodge controller      -> dodge clocks, Flow, iframes, chain state
Melee controller      -> melee chain lifecycle
Guard controller      -> block/parry state
Stamina authority     -> spend/regen policy
Weapon definition     -> weapon-specific tuning/data
Impact presenter      -> hit presentation
Operator              -> coordination and integration
```

Use existing project authorities when they already express the concept cleanly.

## 5. Prefer data/config for tuning

If a change is a tuning value rather than behavior, keep it in the appropriate Resource/config/profile instead of embedding weapon- or enemy-specific numbers in orchestration code.

Examples:

- attack timings;
- stamina costs;
- posture damage;
- knockback values;
- target-assist values;
- archetype movement speeds;
- presentation intensity.

Runtime code should interpret the contract. Data should own tuneable values where practical.

## 6. Avoid duplicate replacement systems

When replacing an old mechanic:

1. identify the existing authority;
2. migrate behavior to the new authority;
3. preserve compatibility only where currently required;
4. add regression coverage;
5. remove the obsolete path when migration is complete.

Do not leave `legacy`, `v2`, and `new` implementations alive indefinitely unless there is an explicit migration reason and exit condition.

## 7. Validation must scale with the slice

Every task packet should name the smallest useful validation set.

Prefer:

```text
focused smoke for changed behavior
+ directly affected regression tests
+ --changed / broader validation only after focused tests pass
```

Do not begin with broad validation when a focused smoke can catch the expected failure faster.

When a subsystem is extracted into its own file, update `validation_manifest.json` ownership so future edits select focused tests instead of dragging in unrelated suites through a giant shared file.

New telemetry should be transition/event level unless per-frame data is explicitly necessary. Avoid observability changes that flood the event ring or make debugging noisier.

## 8. Preserve current truth in docs

Task packets should call for documentation updates only where the implementation changes an active contract.

- active design docs describe current behavior;
- `CURRENT_STATE.md` records concise current runtime truth;
- completed task packets/history should not become required reading for future implementation work;
- do not retain stale numeric claims after changing runtime values.

Codex should not be told to read a long boilerplate document list. It already has repository context instructions. Call out a file only when it is specifically authoritative for the task.

## 9. State non-goals explicitly

Every nontrivial packet should say what nearby systems must remain unchanged. This limits opportunistic refactors and makes review easier.

Typical examples:

```text
Do not change HP/damage balance.
Do not redesign the Director.
Do not rename weapon identities.
Do not change camera/procgen scale.
Do not add new art.
```

Only include non-goals that are plausibly adjacent to the requested implementation.

## 10. Let Codex choose local implementation details

Specify exact external behavior and architecture constraints, but do not force unnecessary private function names, field names, or class shapes when the live code has a cleaner seam.

Use wording such as:

> Implement this through the existing authority when possible. If the exact helper/field differs from this packet, preserve the behavioral contract and avoid a parallel system.

This keeps the task precise without turning the instruction packet into a brittle pseudo-diff.

## 11. Completion reports should be compact and factual

Ask Codex to report only what is needed to review the implementation:

- files changed;
- final values/contracts;
- tests run and results;
- any intentionally deferred piece;
- any discovered architectural conflict or follow-up risk.

Do not request long prose recaps of the task itself.

## 12. Complexity check before issuing a packet

Before handing a task to Codex, verify:

```text
[ ] Is this one coherent implementation slice?
[ ] Is there a clear subsystem owner?
[ ] Can it avoid adding substantial new logic to operator.gd/enemy.gd?
[ ] Are tuning values kept in data/config where appropriate?
[ ] Does it reuse rather than duplicate existing authorities?
[ ] Are nearby non-goals explicit?
[ ] Are focused tests identified before broad validation?
[ ] Can the completion report be reviewed without rereading the whole project?
```

If several answers are "no", split or restructure the task before implementation.

## Guiding Principle

**Optimize for total project complexity, not minimum files or minimum lines changed in one patch.**

A slightly larger patch that creates a clean subsystem boundary can be cheaper long-term than another 100 lines in a god file. Conversely, do not refactor architecture merely because a task touches an old file. Extract only when the behavior forms a real reusable/stateful authority or when continued in-place growth would deepen coupling.
