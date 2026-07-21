# AUTHORED LEVEL AUTHORING PIPELINE

- Status: `complete-v1; lifecycle hardening complete; route traversal v1 complete`
- Authority: `design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`
- Goal: Deliver a deterministic CLI-first authored-level scaffold, generic mapper, named-spawn loader contract, and registry-driven procgen ingress placement.
- Files: `game/world/levels/`, `game/world/procgen/ingress/`, `game/systems/core/systems/contract_world_loader.gd`, `scenes/debug/`, `tools/level_authoring/`, `tools/validation/`, `content/levels/`, AI context docs.
- Constraints: Preserve the persistent main-world Operator, Sundered routed-chain compatibility, deterministic simulation, atomic writes, and unrelated dirty-worktree changes.
- Acceptance: New generic smokes plus existing Sundered ingress/mapper/chain smokes pass; project imports; registry remains valid.
- Completed: Design authority; shared production/playtest contracts; named-spawn loader activation; explicit presentation/lifecycle definitions; exact procgen/connected/actor/camera/UI origin snapshots; authoritative entry rollback; immediate outgoing-level deactivation before origin restore; structured restoration preflight and rollback; fail-closed loader-owned returns; real physics-driven ingress re-entry; exact camera rebind validation; loader-mediated world return and instance release; ingress reset/re-entry; generic mapper and Sundered wrapper; deterministic registry spawner; transactional scaffold generator/templates; lifecycle, generic, and Sundered regression smokes; AI-context updates.
- Completed: Route-aware generic exits, managed route create/append generation, and the live one-node wrapper now extend the original level pipeline.
- Deferred: Editor dock; save-file route persistence; major-context WorldTransitionManager.

## Plan

1. Add shared level and named-spawn runtime contracts.
2. Generalize mapper and preserve Sundered wrapper behavior.
3. Add generator/templates and alternate-root smoke coverage.
4. Add deterministic registry ingress placement.
5. Run regression suite and update AI context.
6. Harden entry/return lifecycle, presentation profiles, rollback, and re-entry before registering another destination.
