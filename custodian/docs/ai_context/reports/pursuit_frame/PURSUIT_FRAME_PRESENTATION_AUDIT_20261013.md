# Pursuit Frame runtime state and actor-bar presentation audit (2026-10-13)

**Status:** repository-source audit, NOT an implementation completion report. **Investigated main:** `55105e4a90546453d2a537add5d859305289411d`. **Authoring chat:** `not-recorded`. **Owning correction:** `enemy-health-bars-and-pursuit-frame-presentation-v1`.

## Source-confirmed defects and work items

| ID | Finding | Proof / exact owner | Corrective disposition |
| --- | --- | --- | --- |
| H-01 | Changing one enemy HP can tint other bars. `update_visuals()` writes `get_theme_stylebox("fill").bg_color`, not a guaranteed per-instance override. | `custodian/game/actors/enemies/enemy.gd` ~1612–1623 | Allocate/cache an actor-owned StyleBoxFlat before first UI update; isolate green/yellow/red thresholds per instance. |
| H-02 | The intended `_setup_health_bar_style()` initializes geometry only. Remaining geometry plus style creation is accidentally inside `_on_observatory_exit()`, gated by observatory registration; normal startup cannot own its style. | `enemy.gd` ~442–480 | Restore setup-body indentation/function ownership. Observatory exit must only decrement gauge. |
| H-03 | Sector health and power bar updates mutate styles returned by `get_theme_stylebox`, a second shared-resource ownership leak. | `custodian/game/actors/sector/sector.gd` ~310–333; `sector.tscn` StyleBox subresources | Duplicate/own fill styles per Sector instance and keep health and power independent. |
| PF-01 | User-observed west attack uses east-facing art and vice versa. Facing in attack-start is taken from `_last_move_direction` while standard melee tracks contact with a separate committed-forward vector. **The precise reversal cause is not yet proven.** | `enemy.gd` ~843–891, ~1992–2023; `enemy_presentation_controller.gd` `_direction_suffix()`; `standard_enemy_melee.gd`; scene-specific E/W clips | Reproduce real west/east attacks with opposite prior movement. Verify committed direction, clip name, flip flag and actual sprite-pixel orientation; fix owner responsible. |
| PF-02 | Pursuit Frame's authored `reaction.death` eight-frame `death_shutdown_01` is mapped but skipped by the enemy death dispatcher, which only invokes `_play_grunt_death()` for Grunt. | `enemy.gd` ~1685–1697; `pursuit_frame_animation_set.gd` | Play the registered authored death semantic with safe missing-clip/one-completion fallback. |
| PF-03 | Pursuit state transitions for notice/search/investigate/ambient/return do not trigger the configured presentation actions because the callback is Grunt-exclusive. | `enemy.gd` ~915–943; `enemy_behavior_state_machine.gd`; `pursuit_frame_animation_set.gd` | Introduce a bounded Pursuit presentation seam for existing states; retain BSM state ownership and prioritize attack/reaction/death. |
| PF-04 | Normal attack animation selection is Grunt-only. Pursuit always uses default `combat.fast_01`; its `fast_02` and `fast_03` aliases map the same brace art, so there is currently no visual variety even if actions rotate. | `enemy.gd` ~879–891, `pursuit_frame_animation_set.gd` | Document aliases honestly; avoid inventing variants. Any selector adjustment must preserve real attack commitment. |
| PF-05 | Grunt-only recoil severity picks an alternate action. Pursuit's available `reaction.flinch_01/02` aliases same 4-frame strip; generic recoil defaults to light action. | `enemy.gd` ~2414–2420, `pursuit_frame_animation_set.gd` | Verify recoil actually plays and interrupt priority is correct; preserve aliases unless new authored art is approved. |
| PF-06 | Direction fallback may resolve N/S/diagonals to E for E/W-only actions. Locomotion run is S-only; N/S patrol walk is available while E/W locomotion is not mapped. A correct action name alone does not prove world-facing presentation. | `enemy_animation_set.gd` `_direction_fallbacks()`; `pursuit_frame_animation_set.gd`; Asset V2 manifest | Test cardinal/diagonal cases and explicitly document or improve only proven misleading fallbacks. No fabricated directional assets. |
| PF-07 | `intercept_windup`, `intercept_burst`, `intercept_recover` are art mappings only; the bespoke intercept gameplay remains deferred. | `design/02_features/enemies/PURSUIT_FRAME.md`; Pursuit set; no intercept ability bound in actor scene | Keep deferred; do not repurpose burst assets as ordinary melee to simulate a nonexistent ability. |
| PF-08 | Existing `pursuit_frame_animation_set_smoke.gd` proves clip names, counts/cache/collisions, not spawned enemy facing, BSM state routing, real E/W sprite pixels or death lifecycle. | `custodian/tools/validation/pursuit_frame_animation_set_smoke.gd` | Add focused instantiated-scene runtime proof and compact 16-state reachability matrix. |

## Current canonical 16-state inventory

These are **Asset V2 state registrations**, not proof each is reachable in gameplay. Each live-action outcome must be recorded in the implementation's final matrix with input state, emitter, direction requested/resolved, whether played at runtime and fallback.

| Asset V2 state | Direction(s) initially authored / derived | Set semantic / current status |
| --- | --- | --- |
| `idle_ready_01` | S; N/E additions, W mirroring | `locomotion.relaxed_idle`, `locomotion.ready_idle`; active idle mapping |
| `patrol_walk_01` | S/N; E/W availability requires runtime verification | `locomotion.relaxed_walk`, `locomotion.walk`; active locomotion mapping |
| `patrol_scan_01` | S | `activity.patrol_scan`; no verified Pursuit BSM callback |
| `checkpoint_halt_01` | S | `activity.checkpoint_halt`; no verified Pursuit BSM trigger |
| `notice_01` | S | `posture.draw`, `posture.alert`; Pursuit BSM callback absent |
| `pursuit_run_01` | S | `locomotion.relaxed_run`, `locomotion.run`; fallback for other facings |
| `intercept_windup_01` | E, derived W | mapped only, bespoke ability deferred |
| `intercept_burst_01` | E, derived W | mapped only, bespoke ability deferred |
| `intercept_recover_01` | E, derived W | mapped only, bespoke ability deferred |
| `melee_brace_01` | E, derived W | `combat.fast_01/02/03` all alias one 6-frame strip; ordinary melee active |
| `flinch_01` | S | `reaction.flinch_01/02` same strip; real reaction path to verify |
| `stagger_01` | S | `reaction.stagger`; existing name fallback to verify |
| `death_shutdown_01` | S | `reaction.death` mapped, unreachable via existing Pursuit death dispatcher |
| `search_sweep_01` | S | `activity.search_sweep`, callback not wired |
| `investigate_scan_01` | S | `activity.investigate_scan`, callback not wired |
| `return_to_route_01` | S | `activity.return_to_route`, callback not wired |

## Contract boundaries and drift

- The active `design/02_features/enemies/PURSUIT_FRAME.md` correctly says bespoke intercept gameplay is deferred. Do not rewrite as implemented.
- Its runtime-wiring text says flinch, stagger and death semantics are mapped; **mapping is not evidence they play**. Correct the live implementation first, then update design/runtime truth with tested states.
- Existing LFS PNG files are visible by path but their image pixels were not inspectable through the repository text connector. Actual image-direction inversion remains **user-observed and unresolved** until reproducible runtime/pixel proof. Do not silently flip source names based only on a file suffix.
- The separate `combat-attack-tell-contact-alignment-v1` ready/auto packet owns attack tell/contact timing; do not alter or waive its acceptance as part of this presentation correction. Shared `enemy-runtime, combat-feel` locks serialize the work when it is claimed.
- No new art is authorized. If a novel source sheet is later required, separately route through Asset Pipeline V2 using 96x96 RGBA frame cells and the existing family manifest. Do not place unreviewed art directly in runtime or inbox during this correction.

## Resume and evidence boundary

Perform the corrective packet on its own canonical dispatcher claim when genuinely eligible; do not reuse the currently claimed Kenney/Dropbox asset-pipeline lock, clear other branches, or touch dirty `operator.gd`. Reconcile existing current-main scene hashes and code before patching; this report is an initial source audit, not a substitute for smoke results. The fix is complete only when the implementation and fresh review pass their stated gates.