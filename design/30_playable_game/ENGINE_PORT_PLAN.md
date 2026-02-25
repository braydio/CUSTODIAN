# ENGINE PORT PLAN

## Goal
- Port presentation/gameplay layer to an engine runtime while keeping world-state simulation portable and deterministic.

## Portability Rules
- Keep simulation engine Python-first and transport-agnostic.
- Use adapter boundaries for input, rendering, and audio.
- Keep save/snapshot compatibility stable across port phases.

## Phased Plan
1. Stabilize simulation contracts and deterministic tests.
2. Build engine-side adapter for command/snapshot transport.
3. Incrementally replace terminal-only presentation with engine UI.
