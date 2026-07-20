# AUTHORED LEVEL AUTHORING PIPELINE

- Status: `complete`
- Authority: `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`
- Goal: Deliver a deterministic CLI-first authored-level scaffold, generic mapper, named-spawn loader contract, and registry-driven procgen ingress placement.
- Files: `game/world/levels/`, `game/world/procgen/ingress/`, `game/systems/core/systems/contract_world_loader.gd`, `scenes/debug/`, `tools/level_authoring/`, `tools/validation/`, `content/levels/`, AI context docs.
- Constraints: Preserve the persistent main-world Operator, Sundered routed-chain compatibility, deterministic simulation, atomic writes, and unrelated dirty-worktree changes.
- Acceptance: New generic smokes plus existing Sundered ingress/mapper/chain smokes pass; project imports; registry remains valid.
- Completed: Design authority; shared production/playtest contracts; named-spawn loader activation; authoritative ingress failure recovery; generic mapper and Sundered wrapper; deterministic registry spawner; transactional scaffold generator/templates; generic and Sundered regression smokes; AI-context updates.
- Deferred: Editor dock and full WorldTransitionManager migration.

## Plan

1. Add shared level and named-spawn runtime contracts.
2. Generalize mapper and preserve Sundered wrapper behavior.
3. Add generator/templates and alternate-root smoke coverage.
4. Add deterministic registry ingress placement.
5. Run regression suite and update AI context.
