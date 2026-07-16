# Operator Frame-Aware Weapon Sockets

- Status: `complete`
- Authority: `design/02_features/operator_modular_weapon/HYBRID_WEAPON_SOCKET_SYSTEM.md`
- Goal: Deliver the Carbine MK1 `e/w/se/sw` frame-aware socket vertical slice plus asymmetric aim timing and camera-owned aim feedback.
- Files: Operator runtime/scene/definition, camera controller, ranged reticle, Carbine data, generated socket JSON, Aseprite exporter, focused smoke, design and AI context.
- Constraints: Preserve fixed-step gameplay authority; keep upper body as presentation clock; no generic muzzle fallback for required phase-1 sectors; camera remains final framing owner; preserve unrelated dirty-worktree changes.
- Acceptance: Required sectors expose directional art and every stance/aim/fire frame has grip/support/muzzle/ejection metadata; projectile and muzzle FX share the resolved muzzle; lower is faster than raise; camera lead/zoom cleanly cancel; focused and adjacent ranged smokes pass.
- Completed: Generated-data loader, canonical eight-way resolver, phase-1 JSON, definition schema/data, frame layout, muzzle/ejection getters, authored plus procedural recoil, direction-aware draw order, debug overlay, Aseprite exporter, 0.22s/0.12s transitions, 0.70 readiness, camera zoom/lead, reticle readiness, validation and drift updates.
- Deferred: Replace compatibility modular weapon strips with dedicated static runtime nodes; author/re-export source markers instead of bootstrap coordinates; enable reviewed fine-angle correction; add N/NE/S/NW production metadata; add casing art and frame-authored magazine/offhand reload events.

## Ownership And Timing

- Owner: gameplay/combat + animation pipeline
- Agent/session: Codex
- Created: 2026-07-16
- Last updated: 2026-07-16

## Work Surface

- Read: active hybrid socket, ranged combat, weapon animation, current-state, file-index, validation, Operator, camera, Carbine definition/data, current modular SpriteFrames.
- Change: active Godot runtime and active design/AI context only.
- Out of scope: legacy Python simulation and authoring new production sprite pixels.

## Drift Review

- Primary authority: updated to phase-1 implementation and strict runtime ownership.
- `CURRENT_STATE.md`: updated.
- `CONTEXT.md`: updated.
- `FILE_INDEX.md`: updated.
- Local routing/readmes: no new routing entry required beyond `FILE_INDEX.md` and validation recipes.

## Handoff

- Next action: Replace bootstrap socket coordinates with an Aseprite marker export after hand-contact review, then migrate the compatibility strips to one static runtime weapon node.
- Best starting files: generated JSON, exporter, socket library, Operator frame-layout method.
- Validation to run: `operator_weapon_socket_smoke.gd`, `operator_primary_ranged_modular_fire_smoke.gd`, `operator_ranged_ready_input_smoke.gd`, `ranged_combat_balance_smoke.gd`.
- Blockers or open questions: production source files do not yet carry reviewed per-frame slice markers; no casing scene or magazine prop art is assigned.
