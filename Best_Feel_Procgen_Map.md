This is the Developer Observatory Export for the procgen map that I think had the best feel of any so far. See below:

---

CUSTODIAN DEV OBSERVATORY PLAYTEST REPORT
============================================

Source: /home/braydenchaffee/.local/share/godot/app_userdata/CUSTODIAN/dev_observatory/latest_session.json
Schema: custodian.dev_observatory.session.v1
Exported: 2026-09-03 03:33:29
Scene: GameRoot (res://scenes/game.tscn)
Uptime: 1h 14m 07s
Captured: 300 events | 0 warnings | 112 counters | 208 gauges
NOTE: event buffer wrapped; showing the final 300/300 events (3864 logged, 3564 dropped). Counters remain cumulative.

PLAYTEST SIGNALS
player deaths 1
damage events 2
cumulative damage amount 173.667
retained-event damage 46.117
cumulative chip damage 0
cumulative healing amount 73.667
ranged shots fired 99
blocked muzzle shots 0
ranged fire failures 55
ranged empty failures total=4, empty_magazine=4
ranged state failures total=51, overheated=51
ranged internal failures total=0
ranged cancellations none
dodges started 50
iframe avoids 0
field patches committed 2
field patches cancelled 0
enemy attacks resolved 11
terminal events retained 3
terminal unique IDs retained 3
incoming hit results total 14
whiff terminals total 5
enemy attack whiffs 5
incoming hit results damaged=9, blocked=0, parried=5, dodged=0
falcon punch attempts 3
falcon punch hits 1
falcon punch parried 2
falcon punch whiffed 0
falcon punch cancelled 0
falcon punch results damaged=1, parried=2
enemies destroyed 14
retained damage before deaths 46.117
NOTE: retained damage-before-death values exclude damage dropped from the event ring.
NOTE: incoming hit results exclude whiffs; terminal outcomes include them.
NOTE: retained event/unique-ID totals are tail-window values; cumulative counters may be larger.

RANGED REQUEST RECONCILIATION
requests 154
fired 99
muzzle blocked 0
failed 55
cancelled 0
pending 0
unaccounted 0

RANGED OVERHEAT DIAGNOSTICS
cumulative failures 51
retained detailed failures 0
average heat at failure unavailable (not retained)
maximum heat at failure unavailable (not retained)
first retained overheat unavailable (not retained)
longest retained streak 0

NOTE: player was dead at export; current resource gauges reflect post-death state.
last live resources: weapon=, loaded=0, reserve=0, stamina=97.5

ENEMY ATTACK TERMINAL OUTCOMES (UNIQUE ATTACK IDs IN RETAINED EVENTS)
damaged=2, blocked=0, parried=0, whiffed=0, cancelled_by_death=1

ENEMY ATTACK INTERRUPTION CAUSES (UNIQUE ATTACK IDs IN RETAINED EVENTS)
interrupted_by_parry=0, interrupted_by_hit=0, interrupted_by_target_loss=0

ENEMY ATTACK LIFECYCLE (UNIQUE ATTACK IDs IN RETAINED EVENTS)
started=3, active=2, terminal=3

FALCON PUNCH DIAGNOSTICS
------------------------------------------------

none retained

LETHAL HIT DIAGNOSTIC
------------------------------------------------

enemy: GRUNT
attack: melee
attack ID: 10540671857242:2
damage: 13
health: 7.117 -> 0
attacker position: (4102.296, 3938.457)
player position: (4140.729, 3944.658)
contact position: (4140.729, 3944.658)
separation: 38.93
contact model: radial_arc
range: 38.93 / 56
base contact range: 40
grace multiplier: 1.15
grace pixels: 10
final allowed range: 56
contact-range source: standard_melee
arc error/half arc: 0 / 47.5
gameplay range sanity: SANE
dodge phase: none
dodge classification: neutral_hit
spatial validity: VALID

SUSPICIOUS HITS
------------------------------------------------

none

PERFORMANCE INCIDENT
------------------------------------------------

state DEGRADED_LATCHED
trigger automatic
duration 0.665s
gameplay sample count 196
external stalls excluded 0
overlay visible at start True
application focused at start True
tree paused at start True
NOTE: external stalls are excluded from gameplay average/percentile/worst calculations.

Phase summaries
phase | avg | p95 | p99 | process | physics | unaccounted
baseline | 19.22 | 16.98 | 18.72 | 17.99 | 0.13 | 1.10

Top aggregated spans
name | total ms | avg ms/gameplay sample | max ms | calls

Worst gameplay frames
NOTE: Godot process/physics monitors are sampled asynchronously and are
directional evidence, not an exact decomposition of each wall-time frame.
wall ms | phase | process | physics | unaccounted | living enemies | top span
518.01 | baseline | 18.57 | 0.26 | 499.18 | 4 |

External stalls
duration | reason | focused | paused | overlay visible

Lifetime deltas
active_audio_delta 0
active_audio_players_delta 0
active_vfx_delta 0
corpse_enemies_delta 0
draw_calls_delta 9
living_enemies_delta 0
node_count_delta 0
rendered_objects_delta 785

Likely owner
classification: unclassified — inspect worst-frame spans
confidence/evidence: []

PROCGEN RUNTIME HEALTH — INCIDENT SNAPSHOT
------------------------------------------------

snapshot active True
snapshot source /root/GameRoot/World/ProcGenRuntime/ProcGenMap
captured at uptime 4447.221
generation 1
map {"x":192,"y":192}
floor cells 8996
wall cells 1367
wall chunks 32
wall bodies 32
wall shapes 1316
boundary chunks 1
boundary bodies 1
boundary shapes 388
navigation revision 14
navigation pending False
navigation requested 14
navigation completed 14
terrain commits 0
connector commits 0
topology repairs 0
last mutation procgen_navigation_rebuild_finished
last mutation uptime 3229.01
last mutation usec 368847

PROCGEN RUNTIME HEALTH — CURRENT/LAST KNOWN
------------------------------------------------

snapshot active True
snapshot source /root/GameRoot/World/ProcGenRuntime/ProcGenMap
captured at uptime 4447.373
generation 1
map {"x":192,"y":192}
floor cells 8996
wall cells 1367
wall chunks 32
wall bodies 32
wall shapes 1316
boundary chunks 1
boundary bodies 1
boundary shapes 388
navigation revision 14
navigation pending False
navigation requested 14
navigation completed 14
terrain commits 0
connector commits 0
topology repairs 0
last mutation procgen_navigation_rebuild_finished
last mutation uptime 3229.01
last mutation usec 368847

RECENT PROCGEN MUTATIONS — INCIDENT RETAINED
------------------------------------------------

time | type | reason | duration usec | changed | before -> after
none retained

WORLD INGRESS PLACEMENT OUTCOMES
------------------------------------------------

none retained

ENEMY RUNTIME ATTRIBUTION
------------------------------------------------

Population
living 4
active 2
nearby 0
background 0
dormant 2
director 2
legacy 2

This incident
enemy total 0.000 ms/frame
enemy active 0.000 ms/frame
enemy nearby 0.000 ms/frame
enemy background 0.000 ms/frame
enemy dormant 0.000 ms/frame

Subsystem distribution
behavior 0.000 ms/frame
perception 0.000 ms/frame
objective 0.000 ms/frame
navigation 0.000 ms/frame
separation 0.000 ms/frame
movement prepare 0.000 ms/frame
move_and_slide 0.000 ms/frame
combat 0.000 ms/frame
animation 0.000 ms/frame
presentation 0.000 ms/frame

Wall-time attribution
wall 19.217 ms/frame
Godot process 17.991 ms/frame
Godot physics 0.127 ms/frame
enemy total (nested) 0.000 ms/frame
unaccounted 1.099 ms/frame

MATERIAL INTELLIGENCE
------------------------------------------------

override cells 0
total contacts 97
material cells none
current player material unknown
retained contact events 13
retained contacts/material unknown=13
retained contacts/kind bullet_impact=8, melee_impact=4, enemy_death=1

HEATMAP
------------------------------------------------

cells 771
samples 3655
event types presence=3348, incoming_hit_damaged=179.55, damage_taken=173.667, enemy_attack_hit=173.667, shot_fired=99, enemy_killed=42, material_bullet_impact=16.75, dodge_started=12.5, player_death=10, enemy_attack_parried=5, incoming_hit_parried=5, material_melee_impact=4, material_enemy_death=3.5, enemy_attack_whiff=2.5, field_patch_committed=2, field_patch_started=1

Top heat cells
-1,7 world=(-64,448) bounds=(-64,448)-(0,512) total=585.00 by_type=presence=585
60,38 world=(3840,2432) bounds=(3840,2432)-(3904,2496) total=260.75 by_type=presence=219, damage_taken=13, enemy_attack_hit=13, incoming_hit_damaged=13, enemy_attack_parried=1, incoming_hit_parried=1, material_melee_impact=0.75
-3,13 world=(-192,832) bounds=(-192,832)-(-128,896) total=168.00 by_type=presence=168
56,33 world=(3584,2112) bounds=(3584,2112)-(3648,2176) total=164.25 by_type=damage_taken=52, enemy_attack_hit=52, incoming_hit_damaged=52, presence=8, dodge_started=0.25
64,61 world=(4096,3904) bounds=(4096,3904)-(4160,3968) total=160.23 by_type=incoming_hit_damaged=52, damage_taken=46.117, enemy_attack_hit=46.117, player_death=10, presence=6
46,47 world=(2944,3008) bounds=(2944,3008)-(3008,3072) total=106.00 by_type=presence=106
38,55 world=(2432,3520) bounds=(2432,3520)-(2496,3584) total=81.00 by_type=presence=81
54,39 world=(3456,2496) bounds=(3456,2496)-(3520,2560) total=75.00 by_type=presence=75
44,44 world=(2816,2816) bounds=(2816,2816)-(2880,2880) total=69.00 by_type=presence=69
43,40 world=(2752,2560) bounds=(2752,2560)-(2816,2624) total=67.00 by_type=presence=63, enemy_killed=3, material_bullet_impact=0.75, material_enemy_death=0.25
37,50 world=(2368,3200) bounds=(2368,3200)-(2432,3264) total=65.00 by_type=presence=65
56,35 world=(3584,2240) bounds=(3584,2240)-(3648,2304) total=60.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=13, enemy_attack_parried=1, incoming_hit_parried=1

Danger cells
64,61 world=(4096,3904) bounds=(4096,3904)-(4160,3968) danger=146.12 by_type=incoming_hit_damaged=52, damage_taken=46.117, enemy_attack_hit=46.117, player_death=10, presence=6
56,33 world=(3584,2112) bounds=(3584,2112)-(3648,2176) danger=52.00 by_type=damage_taken=52, enemy_attack_hit=52, incoming_hit_damaged=52, presence=8, dodge_started=0.25
57,36 world=(3648,2304) bounds=(3648,2304)-(3712,2368) danger=17.55 by_type=damage_taken=17.55, enemy_attack_hit=17.55, incoming_hit_damaged=17.55, presence=4
56,35 world=(3584,2240) bounds=(3584,2240)-(3648,2304) danger=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=13, enemy_attack_parried=1, incoming_hit_parried=1
59,36 world=(3776,2304) bounds=(3776,2304)-(3840,2368) danger=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=5
62,38 world=(3968,2432) bounds=(3968,2432)-(4032,2496) danger=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=5, enemy_attack_parried=1, incoming_hit_parried=1, dodge_started=0.5
60,38 world=(3840,2432) bounds=(3840,2432)-(3904,2496) danger=13.00 by_type=presence=219, damage_taken=13, enemy_attack_hit=13, incoming_hit_damaged=13, enemy_attack_parried=1, incoming_hit_parried=1, material_melee_impact=0.75

Combat cells
56,33 world=(3584,2112) bounds=(3584,2112)-(3648,2176) combat=52.00 by_type=damage_taken=52, enemy_attack_hit=52, incoming_hit_damaged=52, presence=8, dodge_started=0.25
64,61 world=(4096,3904) bounds=(4096,3904)-(4160,3968) combat=46.12 by_type=incoming_hit_damaged=52, damage_taken=46.117, enemy_attack_hit=46.117, player_death=10, presence=6
57,36 world=(3648,2304) bounds=(3648,2304)-(3712,2368) combat=17.55 by_type=damage_taken=17.55, enemy_attack_hit=17.55, incoming_hit_damaged=17.55, presence=4
56,35 world=(3584,2240) bounds=(3584,2240)-(3648,2304) combat=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=13, enemy_attack_parried=1, incoming_hit_parried=1
59,36 world=(3776,2304) bounds=(3776,2304)-(3840,2368) combat=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=5
62,38 world=(3968,2432) bounds=(3968,2432)-(4032,2496) combat=15.00 by_type=damage_taken=15, enemy_attack_hit=15, incoming_hit_damaged=15, presence=5, enemy_attack_parried=1, incoming_hit_parried=1, dodge_started=0.5
60,38 world=(3840,2432) bounds=(3840,2432)-(3904,2496) combat=13.00 by_type=presence=219, damage_taken=13, enemy_attack_hit=13, incoming_hit_damaged=13, enemy_attack_parried=1, incoming_hit_parried=1, material_melee_impact=0.75
41,39 world=(2624,2496) bounds=(2624,2496)-(2688,2560) combat=11.00 by_type=presence=17, shot_fired=11
64,38 world=(4096,2432) bounds=(4096,2432)-(4160,2496) combat=11.00 by_type=presence=11, shot_fired=8, enemy_killed=3, material_bullet_impact=1.25, material_enemy_death=0.25
48,45 world=(3072,2880) bounds=(3072,2880)-(3136,2944) combat=7.00 by_type=presence=52, shot_fired=7
64,36 world=(4096,2304) bounds=(4096,2304)-(4160,2368) combat=6.00 by_type=presence=13, shot_fired=6
65,36 world=(4160,2304) bounds=(4160,2304)-(4224,2368) combat=6.00 by_type=shot_fired=6, presence=3

SIGNAL QUALITY FLAGS
------------------------------------------------

- Event buffer wrapped: 3564 events dropped after 3864 logged.
- Overheat dominates ranged failures: 51/55 (92.7%).
- Dodges were recorded, but no iframe avoids were observed.

TOP EVENT TYPES (48)
performance_incident_state_changed 82
enemy_navigation_goal_unreachable 31
player_weapon_feedback 18
enemy_simulation_tier_changed 15
material_contact 13
player_dodge_charge_presentation 10
player_dodge_charge_started 10
player_dodge_started 10
player_dodge_charge_released 10
player_dodge_chain_ended 10
player_melee_attack_targeting_committed 9
player_reclaim_rejected 7
player_melee_fast_chain_step_started 5
player_melee_soft_target_changed 5
player_ranged_shot 4
world_history_recorded 4
player_fast_attack_dodge_buffered 3
player_fast_attack_dodge_cancel 3
performance_incident_started 3
performance_incident_stopped 3
player_melee_fast_chain_input_latched 3
enemy_attack_windup 3
enemy_attack_resolved 3
terminal_layout_open 2
enemy_assault_state_changed 2
stamina_exhausted 2
player_melee_fast_chain_input_rejected 2
player_parry_started 2
player_parry_active 2
player_parry_expired 2
enemy_attack_active 2
player_failed_parry_hitreact 2
player_damage 2
incoming_hit_result 2
route_ended 1
ash_bell_threadway_unlocked 1
field_patch_prompt_shown 1
marine_dash_finished 1
player_dodge_chain_buffered 1
performance_external_stall 1
field_patch_started 1
field_patch_committed 1
player_ranged_fire_failed 1
enemy_killed 1
player_reclaim_pool_added 1
player_reclaim_forfeited 1
player_death 1
observatory_overlay_toggled 1

WARNINGS (0 total, 0 displayed)
none

NONZERO COUNTERS
ambient_critter_spawn_projected 9
ambient_enemy_duplicate_marker_suppressed 8
ambient_enemy_spawn_count 9
ambient_enemy_spawn_projected 18
enemies_destroyed 14
enemy_assault_state_commit 7
enemy_assault_state_regroup 7
enemy_attack_interrupted_by_death 1
enemy_attack_interrupted_by_parry 5
enemy_attack_result_cancelled_by_death 1
enemy_attack_result_damaged 9
enemy_attack_result_interrupted 3
enemy_attack_result_parried 5
enemy_attack_result_whiffed 5
enemy_attack_whiffed_out_of_range 5
enemy_attack_whiffs 5
enemy_attack_windups 17
enemy_attacks_resolved 11
enemy_hits_with_spatial_context 9
enemy_lethal_hits 1
enemy_los_query_count 852
enemy_los_query_total_usec 13944
enemy_nav_query_count 1059
enemy_nav_query_total_usec 160153
enemy_navigation_goal_unreachable 1752
enemy_objective_evaluations 412
enemy_objective_switches 8
enemy_parry_vulnerable_consumed 4
enemy_parry_vulnerable_opened 2
enemy_reactions_flinch 61
enemy_reactions_stagger 4
enemy_separation_candidate_checks 4482
enemy_sim_tier_active 34
enemy_sim_tier_background 48
enemy_sim_tier_dormant 45
enemy_sim_tier_nearby 39
enemy_spatial_contact_valid 9
falcon_punch_attempts 3
falcon_punch_commitment_cues 3
falcon_punch_hits 1
falcon_punch_parried 2
falcon_punch_result_damaged 1
falcon_punch_result_parried 2
falcon_punch_tracking_locks 3
falcon_reversal_completed 2
falcon_reversal_impact 2
falcon_reversal_started 2
field_patch_attempted 2
field_patch_committed 2
field_patch_prompt_shown 3
field_patch_started 2
grunt_falcon_punch_hits_resolved 3
incoming_hit_damaged 9
incoming_hit_parried 5
incoming_hits_total 14
player_critical_attack_hit 4
player_critical_attack_started 4
player_damage_amount_total 173.667
player_deaths 1
player_dodge_chain_inputs_buffered 13
player_dodge_chain_links_started 6
player_dodge_chain_rejected_stamina 7
player_dodge_charge_started 51
player_dodges_started 50
player_dodges_started_committed 12
player_dodges_started_long 14
player_dodges_started_tap 24
player_failed_parry_hitreact 3
player_fast_attacks_from_dodge_recovery 4
player_healing_amount_total 73.667
player_hits_taken 9
player_hits_taken_heavy 3
player_hits_taken_light 6
player_parry_active 12
player_parry_expired 7
player_parry_started 12
player_parry_success 5
player_parry_success_sfx_played 5
player_ranged_fire_failure_empty 4
player_ranged_fire_failure_empty_magazine 4
player_ranged_fire_failure_overheated 51
player_ranged_fire_failure_state_locked 51
player_ranged_fire_failures 55
player_ranged_fire_requests 154
player_ranged_request_failed 55
player_ranged_request_fired 99
player_ranged_shots_fired 99
player_ranged_trigger_samples 98
procgen_prop_candidates_rejected_protected_zone 7
procgen_prop_candidates_rejected_stuck_risk 1
procgen_runtime_blockers_registered 22
procgen_runtime_blockers_unregistered 3
stamina_exhaustion_sprint 9
stamina_exhaustions 9
stamina_regenerated_parry_refund 29.433
stamina_regenerated_passive 4674.933
stamina_regenerated_total 4704.367
stamina_spent_dodge 976
stamina_spent_dodge_chain 96
stamina_spent_fast_attack 191
stamina_spent_heavy_attack 28
stamina_spent_parry 96
stamina_spent_sprint 3366.067
stamina_spent_total 4753.067
world_history_enemy_killed 14
world_history_player_damage 9
world_history_player_death 1
world_history_sector_damage 1

GAUGES
active_combat_audio 1
active_enemies 4
active_projectiles 1
active_vfx 0
ambient_critters 2
ambient_enemy_animation_prewarm_usec 255349
ambient_enemy_spawn_last_usec 19056
ambient_enemy_spawn_max_usec 36504
ambient_enemy_spawn_queue_depth 0
collision_shape_count 2043
collision_shape_count_enemies 4
collision_shape_count_foliage 14
collision_shape_count_peak 2043
collision_shape_count_projectiles 0
collision_shape_count_ruin_props 15
collision_shape_count_runtime_walls 1704
corpse_enemies 0
director_behavior_agents 2
enemy_behavior_sample {"blackboard":{"alerted":false,"ambient_activity":"none","ambient_anchor":"","ambient...
enemy_los_query_last_usec 13
enemy_nav_query_last_usec 144
enemy_nav_queue_depth 0
enemy_tier_active 2
enemy_tier_active_physics_enabled 2
enemy_tier_background 0
enemy_tier_background_physics_enabled 0
enemy_tier_dormant 2
enemy_tier_dormant_physics_enabled 0
enemy_tier_nearby 0
enemy_tier_nearby_physics_enabled 0
field_patch_active False
field_patch_seconds_available_below_half_health 120.85
field_patches_max 2
field_patches_remaining 0
foliage_shared_material_count 2
foliage_z_order_inspections 0
fps 59
grid_allocated_rate 86
grid_degraded_consumer_count 0
grid_generation_rate 120
grid_net_rate 34
grid_offline_consumer_count 0
grid_requested_rate 86
grid_storage_capacity 500
grid_stored_energy 498.567
heat_player_presence_cells 1024
heatmap_cells 771
heatmap_samples 3655
infrastructure_structure_count 1
infrastructure_under_construction_count 0
interest_active 2
interest_background 0
interest_dormant 2
interest_nearby 0
legacy_combat_agents 2
legacy_enemy_sample {"carrying_loot":false,"enabled":false,"profile_id":"raider_grunt","state":"legacy"}
living_enemies 4
loaded_procgen_root_count 1
loaded_world_branch_count 2
node_class_histogram {"AnimatedSprite2D":61,"AnimationPlayer":1,"Area2D":44,"AudioStreamPlayer":2,"AudioSt...
node_count 11890
node_count_collision 2404
node_count_peak 11890
node_count_procgen 2307
node_count_props 129
node_count_ui 935
node_count_vfx 1
node_count_world 10950
observatory_full_tree_scan_count 1
observatory_overlay_build_usec 309
observatory_overlay_line_count 38
observatory_overlay_refresh_count 1
observatory_overlay_text_chars 1301
observatory_scan_usec 118678
performance_draw_calls 237
performance_frame_ms_average 17.477
performance_frame_ms_current 16.558
performance_frame_ms_p95 17.612
performance_frame_ms_p99 18.813
performance_frame_ms_worst 1346.078
performance_frame_sample_count 600
performance_hitch_count 853
performance_incident_auto_trigger_count 13
performance_incident_external_stall_count 0
performance_incident_manual_trigger_count 0
performance_incident_rearm_progress_sec 0
performance_incident_state DEGRADED_LATCHED
performance_physics_ms 0.015
performance_process_ms 18.471
performance_rendered_objects 3717
performance_severe_hitch_count 425
physics_body_count 317
physics_body_count_foliage 14
physics_body_count_peak 317
physics_body_count_ruin_props 7
physics_body_count_runtime_walls 33
physics_process_enabled_node_count 18
player_active_weapon_id  
player_active_weapon_state_key  
player_alive False
player_ammo_per_shot 0
player_dead True
player_dodge_chain_index 0
player_dodge_flow 0
player_health 0
player_last_live_loaded_ammo 0
player_last_live_reserve_ammo 0
player_last_live_stamina 97.5
player_last_live_weapon_id  
player_loaded_ammo 0
player_magazine_capacity 0
player_material unknown
player_material_footstep_noise_mult 1
player_max_health 100
player_melee_target_angle_error 2.152
player_melee_target_distance 38.93
player_melee_target_proximity 1
player_melee_target_reliable 0
player_melee_target_score 1.046
player_position {"x":4141,"y":3945}
player_ranged_requests_pending 0
player_reclaim_active 0
player_reclaim_packet_count 0
player_reclaim_window_remaining 0
player_recoil 0.45
player_reserve_ammo 0
player_sprinting False
player_stamina 0
player_stamina_max 100
player_weapon_heat 0
player_weapon_overheated False
process_enabled_node_count 64
procgen_floor_cells 8996
procgen_foliage_sprite_count 59
procgen_fruit_sprite_count 0
procgen_generated_wall_cells 1367
procgen_generation_count 1
procgen_generation_id 1
procgen_interior_prop_count 0
procgen_last_mutation_duration_usec 368847
procgen_last_mutation_kind procgen_navigation_rebuild_finished
procgen_last_mutation_uptime_sec 3229.01
procgen_map_height 192
procgen_map_width 192
procgen_navigation_last_rebuild_reason wall_change
procgen_navigation_last_rebuild_usec 368847
procgen_navigation_rebuild_completed_count 14
procgen_navigation_rebuild_pending False
procgen_navigation_rebuild_requested_count 14
procgen_navigation_revision 14
procgen_prop_candidates_rejected_existing_blocker 0
procgen_prop_candidates_rejected_protected_zone 7
procgen_prop_candidates_rejected_stuck_risk 1
procgen_prop_collision_alignment_warning_count_last_generation 0
procgen_reveal_queue 0
procgen_road_decal_count 29
procgen_runtime_blocker_sources 19
procgen_runtime_connector_commit_count 0
procgen_runtime_prop_blocker_cells 129
procgen_runtime_terrain_commit_count 0
procgen_runtime_terrain_last_changed_cell_count 0
procgen_runtime_terrain_last_commit_reason
procgen_runtime_terrain_last_commit_usec 0
procgen_runtime_topology_repair_count 0
procgen_runtime_wall_body_count 32
procgen_runtime_wall_body_peak 39
procgen_runtime_wall_chunk_count 32
procgen_runtime_wall_chunks_created_total 71
procgen_runtime_wall_chunks_freed_total 39
procgen_runtime_wall_collision_isolation_enabled True
procgen_runtime_wall_last_rebuild_reason visible_wall_sync
procgen_runtime_wall_last_rebuild_usec 5344
procgen_runtime_wall_rebuild_count 55
procgen_runtime_wall_shape_count 1316
procgen_runtime_wall_shapes_created_total 2704
procgen_runtime_wall_shapes_freed_total 1388
procgen_scattered_prop_count 11
procgen_shadow_last_rebuild_usec 6
procgen_shadow_rebuild_requested_count 59
procgen_snapshot_active True
procgen_snapshot_captured_uptime_sec 4447.222
procgen_snapshot_source /root/GameRoot/World/ProcGenRuntime/ProcGenMap
procgen_stuck_pockets_detected_last_generation 0
procgen_stuck_pockets_last_scan 0
procgen_stuck_pockets_remediated_last_generation 0
procgen_void_cliff_cells_per_frontier 3.057
procgen_void_cliff_frontier_cells 966
procgen_void_cliff_painted_cells 2953
procgen_walkable_boundary_body_count 1
procgen_walkable_boundary_chunk_count 1
procgen_walkable_boundary_chunks_created_total 2
procgen_walkable_boundary_chunks_freed_total 1
procgen_walkable_boundary_last_rebuild_reason generation
procgen_walkable_boundary_last_rebuild_usec 11336
procgen_walkable_boundary_rebuild_count 2
procgen_walkable_boundary_shape_count 388
procgen_wall_cells 1367
procgen_wall_shadow_isolation_enabled True
render_atmosphere_enabled True
render_directional_light_enabled True
render_isolation_mode production
render_point_light_count 4
render_procgen_depth_backdrop_enabled True
render_procgen_floor_enabled True
render_procgen_major_visuals_enabled True
render_procgen_walls_enabled True
top_level_subtree_counts {"ARRNManager":1,"BuildInventory":1,"CognitiveState":1,"CommandRegistry":1,"DebugBus"...
uptime_sec 4447.22
