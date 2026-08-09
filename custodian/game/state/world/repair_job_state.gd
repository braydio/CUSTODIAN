class_name RepairJobState
extends RefCounted
var job_id := ""
var structure_id := ""
var remaining: float = 0.0
var total: float = 0.0
var material_cost := 0
func to_dict() -> Dictionary: return {"job_id":job_id,"structure_id":structure_id,"remaining":remaining,"total":total,"material_cost":material_cost}
static func from_dict(data: Dictionary) -> RepairJobState: var v:=RepairJobState.new(); v.job_id=String(data.get("job_id","")); v.structure_id=String(data.get("structure_id","")); v.remaining=float(data.get("remaining",0)); v.total=float(data.get("total",0)); v.material_cost=int(data.get("material_cost",0)); return v
