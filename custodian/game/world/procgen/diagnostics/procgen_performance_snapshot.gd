class_name ProcgenPerformanceSnapshot
extends RefCounted

const CANDIDATE_SEMANTIC_ADAPTER_SCRIPT := preload(
	"res://game/world/procgen/generation/candidate_semantic_adapter.gd"
)

## Narrow normalizer for custodian.procgen_performance_baseline.v1 snapshots,
## consumed by custodian/tools/validation/procgen_performance_baseline_bench.gd.
##
## Never re-runs generation, mutation, or streaming reveal work. Only reshapes
## timing/state facts already computed and owned by ProcGenTilemap,
## CustodianContractMap, and DevObservatory.


## Structured generation phase-timing/identity snapshot, plus a same-seed
## output-stability fingerprint derived from the authoritative floor/wall
## cell dictionaries the same way procgen_candidate_promotion_smoke.gd does.
static func generation_snapshot(tilemap: ProcGenTilemap) -> Dictionary:
	var snapshot := tilemap.get_last_generation_timing_snapshot()
	snapshot["promotion"] = tilemap.get_last_promotion_timing_snapshot()
	snapshot["materialization"] = tilemap.get_last_materialization_timing_snapshot()
	snapshot["floor_cell_count"] = tilemap.debug_get_generated_floor_cells().size()
	snapshot["wall_cell_count"] = tilemap.debug_get_generated_wall_cells().size()
	snapshot["fingerprint"] = CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.fingerprint_runtime_state(tilemap)
	return snapshot


## Structured candidate-loop timing/acceptance report already captured by
## CustodianContractMap during generate_contract().
static func contract_snapshot(contract_map: CustodianContractMap) -> Dictionary:
	var snapshot := contract_map.get_last_contract_generation_report()
	var contract: Dictionary = contract_map.get_latest_contract()
	var map_record: Dictionary = contract.get("map", {})
	var map_instance: Variant = map_record.get("instance")
	if map_instance is ProcGenTilemap:
		var tilemap := map_instance as ProcGenTilemap
		snapshot["materialized_world"] = {
			"fingerprint": CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.fingerprint_runtime_state(tilemap),
			"floor_cell_count": tilemap.debug_get_generated_floor_cells().size(),
			"wall_cell_count": tilemap.debug_get_generated_wall_cells().size(),
			"materialization": tilemap.get_last_materialization_timing_snapshot(),
		}
	return snapshot


## Deterministic same-seed fingerprint over authoritative floor/wall cell
## identity (position, source, atlas, alternative). Two runs with the same
## seed/config must produce the same fingerprint even if wall-clock timings
## differ.
static func fingerprint_generation(tilemap: ProcGenTilemap) -> String:
	return CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.fingerprint_runtime_state(tilemap)


## Structured runtime/streaming snapshot for the benchmark's scripted runtime
## case. Consumes ProcGenTilemap.get_runtime_health_snapshot(), the tilemap's
## own streaming reveal bookkeeping, and DevObservatory's existing node/render
## engine monitors rather than starting a second telemetry system.
static func runtime_snapshot(
	tilemap: ProcGenTilemap,
	tree: SceneTree,
	streaming_reveal_queue_peak: int,
	revealed_chunk_count_peak: int,
	frame_time_ms_samples: Array
) -> Dictionary:
	var revealed_chunks: Dictionary = tilemap.get("_revealed_chunks")
	var queued_chunks: Dictionary = tilemap.get("_queued_chunks")
	var reveal_queue: Array = tilemap.get("_streaming_reveal_queue")
	var blocker_cells: Dictionary = tilemap.get("_runtime_prop_blocker_cells")
	var node_stats := {}
	var observatory: Node = tree.root.get_node_or_null("DevObservatory") if tree != null else null
	if observatory != null and observatory.has_method("_collect_node_stats"):
		node_stats = observatory.call("_collect_node_stats", tree.root) as Dictionary
	return {
		"runtime_health": tilemap.get_runtime_health_snapshot(),
		"revealed_chunk_count": revealed_chunks.size(),
		"queued_chunk_count": queued_chunks.size(),
		"revealed_chunk_count_peak": revealed_chunk_count_peak,
		"streaming_reveal_queue_current": reveal_queue.size(),
		"streaming_reveal_queue_peak": streaming_reveal_queue_peak,
		"runtime_prop_blocker_count": blocker_cells.size(),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"procgen_node_count": int(node_stats.get("node_count_procgen", 0)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"rendered_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"frame_time_ms_samples": frame_time_ms_samples,
	}
