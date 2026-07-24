#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
tests=(
  route_registry_contract_smoke.gd
  route_connectivity_smoke.gd
  route_forward_backtrack_smoke.gd
  route_profile_selection_smoke.gd
  route_transition_rollback_smoke.gd
  route_entry_post_commit_rollback_smoke.gd
  route_world_exfil_smoke.gd
  route_single_level_wrapper_smoke.gd
  route_cache_policy_smoke.gd
  route_state_policy_smoke.gd
  route_exit_binding_smoke.gd
  sundered_keep_route_graph_smoke.gd
  sundered_keep_route_state_smoke.gd
  sundered_keep_authored_exits_smoke.gd
  sundered_keep_no_direct_transition_authority_smoke.gd
  sundered_keep_parallax_depth_smoke.gd
  sundered_keep_vista_polish_smoke.gd
  level_scaffold_route_generator_smoke.gd
)

for test_script in "${tests[@]}"; do
  "${GODOT_BIN}" --headless --path . --script "res://tools/validation/${test_script}"
done
