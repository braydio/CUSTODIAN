# F06 · Campaign, Hub, continuity, death and recovery

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Detailed current-main static source/design review completed 2026-10-11; playable rendering and adversarial runtime tests **NOT EXECUTED** in this audit.  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring or claim authorized by this audit alone  
> **Snapshot:** `main@16b9dfdd6ce09889b85c61372e02d0eccea5de76` · October 11, 2026  
> **Evidence:** User playtest Dev Observatory export, 2026-10-11 15:04:44; live GitHub Godot source/scene/validation-manifest/design/queue inspection.  
> **Priority:** P0 to independently test the *true terminal* modal on the actual GameRoot scene; P1 on HUD truth and R1→H6→R2 recovery handoff.  
> **Program maturity:** R1 landed, formal R1 review and H6 generic return incomplete on inspected main; R2 pre-authored and dependency-gated, R3–R8 design/planned.

## Decision and scope

This is a source-evidenced diagnosis and bounded integration audit. The attached observatory session does **not** prove that lethal HP zero or the Game Over presentation occurred. It proves the Operator ended at **0.45/100 HP** with `player_alive=true`, `player_dead=false`, cumulative death count zero. `100 + 35 - 134.55 = 0.45`. Separate this UI mismatch from a broken death gate. The player's report that they have never *seen* the Game Over modal is a legitimate real-game concern, but without a targeted real-viewport capture it is not yet proof that the modal actually fired and was invisible.

Do **not** convert ordinary Operator death into permanent Game Over: `design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md` is the persistent design authority, in which body death normally starts local or Post recovery, whereas global Game Over represents actual lost continuity. Current R1 direct Game Over is a transitional fail-safe until exact approved H6 return and R2 reintegration.

## Source-mapped runtime call graph

```text
Enemy incoming-hit / other real lethal source
  -> game/actors/operator/operator.gd::take_damage()
      health = max(0.0, health - amount) [float; sync current_health]
      if health <= 0.0: _handle_death()
         latch _is_dead before emitting
         log player_death, snapshot damage/equipment/position
         request DEATH action animation
         emit operator_down(death_context)
           -> operator.tscn child OperatorDeathCampaignBinding
              -> world_simulation_runtime session started & unresolved?
                 yes: resolve_campaign(FAILURE, reason) exactly once
                 no: do not fabricate campaign
              -> GameState.trigger_game_over(reason) [R1 compatibility fallback]
                 latch game_over, set paused=true and tree.paused=true
                 snapshot GameStats, emit game_over_triggered
                 instantiate GameOverModal Control
                 add to SceneTree.current_scene (GameRoot Node2D in game.tscn)
         await 1.6s SceneTree timer
         _finish_death(): exits immediately while GameState.game_over
```

Separate genuine terminal: `game/actors/sector/command_post.gd::_on_destroyed` invokes `GameState.trigger_game_over`. The old `GameState.lose_life` path still exists and is tested, but R1 Operator death no longer decrements legacy lives. Do not regress Command Post/siege failure while refining death/recovery.

### Authority mapping

| Responsibility | Live owner | Current conclusion |
| --- | --- | --- |
| Operator health/death latch and damage | `game/actors/operator/operator.gd`, base `controllable_actor.gd` | Float health, lethal only when <= 0; _is_dead latch avoids duplicate signal |
| R1 campaign death adapter | `game/world/bindings/operator_death_campaign_binding.gd`; child in `operator.tscn` | _handled once per adapter lifetime, emits one exact campaign FAILURE then immediate legacy Game Over |
| One campaign outcome | `game/systems/simulation/world_simulation_runtime.gd` + CampaignSession | `resolve_campaign` and one-shot session authority; no second result produced by adapter |
| Terminal Game Over & modal | `game/systems/core/state/game_state.gd` + `game/ui/game_over/*` | Pauses tree and dynamically mounts Control to current scene |
| Game HUD | `game/ui/hud/custodian_hud.gd`, `game/ui/hud/ui.gd`, `game/ui/inventory/inventory_ui.gd` | Integer health presentation, not a true HP-zero signal |
| Generic return, death-specific reintegration | Existing H6 + R2 packets | Not live on this snapshot, no claim that complete death-return/rearm exists |
| Equipment/crèche persistence | R3–R8 roadmap/design | Future scope, not current runtime behavior |

## Detailed finding register

**F06-01 · P1 · Confirmed UI false-zero, not a confirmed death-engine bug.**
Live `operator.gd::take_damage` keeps `health/current_health` floating point and calls `_handle_death` at <=0; base `ControllableActor.is_alive` checks >0. The observational value 0.45 HP rounds to zero in both `custodian_hud.gd::_refresh_operator_status` and `ui.gd` health text; the `CustodianHUD.set_health` and inventory APIs take int. This explains 0/100 display with the player still alive. Correct presentation: real zero -> `0/100`; strictly positive subunit -> `<1/100` (or equally explicit alive indicator); >=1 use agreed integer policy. Keep exact float bars and all damage/restore/reclaim mechanics authoritative; centralize formatter, test inventory and all HUD views and 0.45->0 lethal transition. Do not force death at a rounded visual zero.

**F06-02 · P0 validation / likely visual defect · Modal is not viewport-anchored to topmost UI canvas.**
`game_state.gd::_show_game_over_modal` instantiates `game_over_modal.tscn` (root `Control`) and adds it to `SceneTree.current_scene`. Production `scenes/game.tscn` root `GameRoot` is `Node2D` with a moving Camera2D, while its main UI is `CanvasLayer` **20**; the modal has no dedicated CanvasLayer and no explicit layer guarantee. This creates a high-confidence risk of world-canvas displacement and being rendered behind the live HUD/other layers. The direct GameState smoke creates a modal but does not render/check pixels, camera position, clipping, topmost stacking or clickable controls in GameRoot. **Reproduce on actual GameRoot at an operator position far from world origin and obtain screenshot/viewport-rect + layer evidence before implementing the smallest topmost viewport-modal host** (likely CanvasLayer above existing UI, process_mode ALWAYS, anchored full viewport). Test pause-state interactive input and both buttons.

**F06-03 · P1 · Death presentation may be frozen by immediate global pause.**
`operator.gd::_handle_death` requests the DEATH action immediately before synchronous `operator_down.emit`. The R1 death binding synchronously calls `GameState.trigger_game_over`, which sets `SceneTree.paused=true` before the requested death presentation's 1.6-second timer. The modal itself processes ALWAYS, but gameplay actor animation generally inherits pause semantics. This can hide/freeze the death animation and replace the body death beat with a synchronous terminal screen. Test actual animated frames and seconds between death trigger/modal mounting; choose a defined presentation-versus-macro freeze boundary. Do not defer outcome sealing or allow duplicate handoff while presenting.

**F06-04 · P1 · Ordinary death is still routed to legacy one-life Game Over (known transitional scope).**
The adapter always calls `GameState.trigger_game_over` even after active session failure outcome; R2 is the existing owner for suppression **only when H6 accepts the exact death outcome** and for persistent Operator reintegration. Avoid a one-off modal suppression patch: with H6 not yet reviewed, that would strand the player without either safe return or fail-safe terminal UI. R2 must preserve non-death FAILURE differentiation, exactly-once Hub mutation, two later deaths with rearmed life-scoped latch and eventual R3–R8 equipment/Crèche semantics.

**F06-05 · P1 · Existing lifecycle tests don't exercise production lethal-hit → visible modal.**
`operator_death_campaign_handoff_smoke.gd` calls `_handle_death` directly, with Operator processing disabled and a synthetic runtime, to verify one outcome/reentrancy/fallback. `game_over_flow_smoke.gd` calls `GameState.trigger_game_over` directly, checking flag, tree pause, modal node, reason, restart and legacy lives but not production GameRoot camera/HUD overlay. Neither test begins at `take_damage` with 0.45 HP and a lethal final hit in the real game scene; neither verifies rendered visibility, focus or animation timing. Register a new integration smoke and add the previously standalone `game_over_flow_smoke.gd` to `validation_manifest.json` (no existing `game_over_flow` entry found in inspected manifest). Register proper owners for `game_state.gd`, modal scene/script, GameRoot, relevant death binding, Operator and HUD. Keep headless logic checks plus actual render/visual evidence; a headless node-in-tree assertion alone cannot prove visible modal.

**F06-06 · P1 · Destination/restart semantics still legacy.**
`GameOverModal._on_restart_pressed` resets global GameState/GameStats then calls `SceneTree.reload_current_scene`; Return to Menu uses default `res://ui/main_menu.tscn` and falls back to the configured boot main scene if unavailable. `project.godot` config points to `res://game/app/boot/runtime_entrypoint.tscn`. Restart/return may intentionally be okay for true terminal failure but is **not** the future continuity-preserving death recovery. Test the real boot and active contract entrypoint, event/transition cleanup, duplicate modal/input, and pause reset. Preserve existing macro-failure stats and no false resurrection/replay of recovery path.

**F06-07 · P1 · Death-outcome latch is instance-scoped and rearm requires R2.**
`OperatorDeathCampaignBinding._handled` latches before calling outcome/terminal state and is never reset in the current adapter. This is acceptable for one-life R1 but cannot serve successful multi-life Post reintegration. R2 already requires rearm after reintegration and a second death in a *new* campaign, not just one closeout. Prove two-life test and no duplicate outcome/Hub mutation before moving recovery into runtime.

**F06-08 · P2 · Documentation and queue drift.**
`custodian/docs/ai_context/task_packets/GAME_OVER_FLOW.md` remains a legacy `in_progress` May 2026 packet, while `design/02_features/game_over/GAME_OVER_FLOW.md` calls the first modal runtime slice implemented. The original R1/H6/R2 roadmap labels R2 `refreshed / blocked`, whereas current R2 packet is `ready/auto` but has unmet dependencies; it is **dependency-gated**, not yet implemented. R1 implementation is archived complete, but its formal review `REVIEW_CUSTODIAN_DEATH_HANDOFF_FOUNDATION_RECOVERY_1.md` is still active ready/auto, as are H6 `HUB_CAMPAIGN_RETURN.md` and its paired review. The game-over spec still describes Custodian death as `lose_life` immediate one-life path; on current code Operator now uses R1 `operator_down` binding and direct `trigger_game_over` fallback, not `lose_life`. Treat the legacy packet as separate lifecycle debt; update authored design docs only in their scoped lifecycle or explicit docs-reconciliation work, never silently edit claimed packets.

**F06-09 · P2 · Telemetry has enough signal but no terminal presentation receipt.**
User playtest export: 4m06s, cumulative deaths 0, player_health 0.45, alive true/dead false, 8 incoming hit results, 134.55 applied damage, 35 healing. 994 events dropped from rolling detailed event buffer; lifetime counters still retained. Add compact terminal transition observability (`lethal_damage_applied`, `operator_down_emitted`, `campaign_outcome_committed`, `game_over_triggered`, `modal_visible_in_viewport`, `modal_focused`, `restart_or_return_accepted`, `reintegration_completed`) with exact IDs/outcome IDs where available. Keep event provenance and avoid interpreting dropped tail events as proof of missing triggers.

## Tests to falsify/confirm before modifying production

1. **Live GameRoot viewport:** Programmatically call `GameState.trigger_game_over("AUDIT PROBE")` with the Operator/camera in a non-origin procgen position. Inspect Control global rectangle, actual visibility, pause mode, canvas layer and hit/focus region. Capture screenshot. Verify full viewport backdrop, not just tree membership. Dismiss safely using the real button.
2. **Lethal threshold:** Set Operator to 0.45 HP via authorized test setup; display must be `<1/100` while alive. Apply a legal 0.44 hit (still alive), then 0.02 (health becomes zero); exactly one `operator_down`, `player_death` and result. Verify dead controls, collision/action locks, no further damage; do not bypass invulnerability for this fixture.
3. **R1 campaign present vs absent:** Active/unresolved session returns exactly one `FAILURE` before fallback; no session, already resolved and unstarted sessions reach safe fallback without fabricating outcomes. Reentrant callback cannot duplicate either. Test death animation frame advancement or intentional freeze and actual modal visibility.
4. **Terminal macro callers:** Destroy Command Post / invoke explicit Game Over; modal should take input, show stats and reason with once-only GameState/scene pause, and restart/menu routes should not retain paused state or duplicate GameState modal instances.
5. **R2 dependencies only after accepted R1/H6:** An exact accepted death outcome suppresses fallback and returns via one Hub authority; rejected return preserves fallback; non-death FAILURE/SUCCESS/PARTIAL/ABANDON never auto-recover; a second separate life commits one new death; interrupted recovery does not incorrectly rearm.
6. **Automated selection:** Ensure actor, GameRoot/UI, binding, state and modal edits select the correct manifest smoke and no false-green result from zero selected tests; retain `game_over_flow_smoke.gd` plus real-game integration.

## Recommended execution order (candidate only; do not claim)

- **Fast isolation, true terminal UI:** Reproduce F06-02 with viewport evidence. If reproduced, narrowly attach the Game Over modal to a viewport-fixed, topmost CanvasLayer and ensure button focus and restart/menu routes; keep true terminal callers active. Do not turn all Operator deaths into Game Over permanently.
- **Small source-truth/UI repair:** F06-01 centralized <1 positive-health formatter across all visible HUD and inventory surfaces, plus exact health float bars and threshold integration test. Follow active Operator UI ownership/locks.
- **Death-beat/pause sequencing:** F06-03 animation and authority ordering with live picture/clock evidence, preserving exactly-once outcome and fail-safe. Scope with UI and R2 ownership to avoid conflicting patches.
- **Existing core program:** Formal R1 independent review; H6 return plus independent review; R2 death-only reintegration plus independent review. **These packets already exist.** Then R3–R8 per roadmap only when design/human gates clear.
- **Cross-series F06 integration:** Add CS-F06-A *only if* existing H7/R2 reviews do not already prove actual GameRoot death, return and multi-life semantics. Do not duplicate or leapfrog.

## Source evidence index

- `custodian/game/actors/operator/operator.gd` (damage around 13754, death around 14226, finish around 14309); `custodian/game/actors/base/controllable_actor.gd`.
- `custodian/game/actors/operator/operator.tscn` (`OperatorDeathCampaignBinding` child); `custodian/game/world/bindings/operator_death_campaign_binding.gd`.
- `custodian/game/systems/core/state/game_state.gd` (terminal ownership, pause, modal mount, restart); `custodian/game/ui/game_over/game_over_modal.gd/.tscn`.
- `custodian/scenes/game.tscn` (Node2D GameRoot, Camera2D, CanvasLayer UI layer 20); `custodian/game/ui/hud/custodian_hud.gd`, `ui.gd`, `inventory_ui.gd`.
- `custodian/tools/validation/operator_death_campaign_handoff_smoke.gd`, `game_over_flow_smoke.gd`, `validation_manifest.json`.
- `design/02_features/game_over/GAME_OVER_FLOW.md`; `design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md` and `PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`; `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`.
- Active `custodian/docs/ai_context/task_packets/REVIEW_CUSTODIAN_DEATH_HANDOFF_FOUNDATION_RECOVERY_1.md`, `HUB_CAMPAIGN_RETURN.md`, `REVIEW_HUB_CAMPAIGN_RETURN.md`, `CUSTODIAN_POST_RECOVERY_REINTEGRATION.md`, paired R2 review.

## Decision lock record

- **Audit verdict:** Static source/design audit done; F06-01 and old R1 fallback verified in code. F06-02/F06-03 are substantial source-supported real-playtest risks **awaiting runtime/screenshot proof**. End-to-end R2 is not implemented.
- **Boundary:** UI false-zero, terminal-modal presentation, death animation pause seam, and existing Campaign outcome→Hub→Post-reintegration seam are distinct authorities.
- **Live acceptance evidence:** Existing standalone smoke tests only; targeted real-viewport and two-life adversarial checks have not been run in this audit.
- **Documentation drift:** Legacy Game Over task status, `lose_life` language and R2 status description need scoped reconciliation. F06 snapshot updated.
- **User/ChatGPT decision lock:** **NOT LOCKED**. No new packet activation by this audit; only the already-authorized R1/H6/R2 packets may proceed under their existing dispatcher gates.
- **Next measurable action:** Run the real GameRoot UI visibility/death-presentation reproduction (F06-02/F06-03), record a screenshot and trace; then decide whether to authorize narrowly scoped UI/health repair packets and any nonduplicative F06 integration packet.
