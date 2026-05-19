extends RefCounted
class_name ARRNKnowledgeSystem

const KNOWLEDGE_TRACK := "RELAY_RECOVERY"
const KNOWLEDGE_MAX := 7


func clamp_index(value: int) -> int:
	return clampi(value, 0, KNOWLEDGE_MAX)


func compute_sync_gain(packets: int, weak_count: int, active_relays: int, failed_packets: int) -> int:
	var successful: int = maxi(0, packets - maxi(0, failed_packets))
	if successful <= 0:
		return 0
	var weak_ratio := 0.0
	if active_relays > 0:
		weak_ratio = float(weak_count) / float(active_relays)
	var effective_gain := int(round(float(successful) * (1.0 - 0.5 * weak_ratio)))
	return maxi(0, effective_gain)
