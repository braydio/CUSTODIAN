class_name FabricationJobState
extends RefCounted
var job_id := ""
var recipe_id := ""
var category := "REPAIRS"
var remaining: float = 0.0
var total: float = 0.0
var outputs: Dictionary = {}
func to_dict() -> Dictionary: return {"job_id":job_id,"recipe_id":recipe_id,"category":category,"remaining":remaining,"total":total,"outputs":outputs.duplicate(true)}
static func from_dict(data: Dictionary) -> FabricationJobState: var v:=FabricationJobState.new(); v.job_id=String(data.get("job_id","")); v.recipe_id=String(data.get("recipe_id","")); v.category=String(data.get("category","REPAIRS")); v.remaining=float(data.get("remaining",0)); v.total=float(data.get("total",0)); v.outputs=(data.get("outputs",{}) as Dictionary).duplicate(true); return v
