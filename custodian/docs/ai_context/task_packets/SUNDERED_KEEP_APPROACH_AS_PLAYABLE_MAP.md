# Sundered Keep Approach As Playable Map

- Status: `superseded`
- Authority: `custodian/AGENTS.md`, `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Superseded by: `SUNDERED_KEEP_AUTHORED_INGRESS.md`
- Historical goal: connect the Vista Approach through Return Causeway.
- Files: `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd`, `custodian/scenes/debug/sundered_keep_approach_collision_mapper.gd`, `custodian/scenes/debug/sundered_keep_approach_collision_mapper_overlay.gd`, `custodian/content/levels/sundered_keep/front_gate.json`, `custodian/game/systems/core/systems/contract_world_loader.gd`, relevant Sundered Keep docs/context, focused validation smokes.
- Constraints: Keep mapper-drawn collision rails as authored collision authority; do not let art alpha own collision; keep deterministic gameplay state local to each level; use explicit handoffs and one active authored branch at a time.
- Current production explicitly skips Return Causeway: the continuous authored
  Approach and Outskirts ends at a mist-covered direct Front Gate handoff.
- Completed: Promoted the approach scene into the normal registered entry, retained its Vista-only markers/collision, and connected the unconditional endpoint through the shared transition controller to `ReturnCausewayApproach`, then through the Causeway north gate to `SunderedKeepMap`. LevelLoader adoption and Causeway return reactivation are explicit. Validated by the existing approach/ingress smokes plus `sundered_keep_level_chain_smoke.gd`.
- Deferred: Vista reference marker positions remain first-pass defaults; Return Causeway content/polish acceptance remains tracked by its own packet.
