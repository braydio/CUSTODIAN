class_name DefaultCampaignScenarioFactory
extends RefCounted
static func create_scenario(seed: int = 1) -> CampaignScenario:
	var scenario := CampaignScenario.new("COMMAND_POST_UNDER_PRESSURE", seed); scenario.title = "Command Post Under Pressure"; scenario.rules = {"macro_sector_ids": WorldIdentityContract.MACRO_SECTOR_IDS.duplicate(), "transit_ids": WorldIdentityContract.TRANSIT_IDS.duplicate(), "materials": 3, "inventory": {"SCRAP": 12, "COMPONENTS": 0, "ASSEMBLIES": 0, "MODULES": 0}, "stocks": {"repair_drones": 0, "turret_ammo": 6}, "structures": [{"id": "COMMAND_POST", "type": "COMMAND_POST", "sector": "COMMAND", "max_hp": 100, "hp": 100, "critical_role": "COMMAND_POST"}], "repairs": [], "fabrication_queue": [], "assaults_enabled": false, "scene_bindings_enabled": true}; return scenario
static func create_world(scenario: CampaignScenario) -> WorldSimulationState:
	var state := WorldSimulationState.new(scenario.seed); state.materials=int(scenario.rules.get("materials", 3)); state.inventory=(scenario.rules.get("inventory", state.inventory) as Dictionary).duplicate(true); state.stocks=(scenario.rules.get("stocks", state.stocks) as Dictionary).duplicate(true); state.repairs=(scenario.rules.get("repairs", []) as Array).duplicate(true); state.fabrication_queue=(scenario.rules.get("fabrication_queue", []) as Array).duplicate(true)
	for row: Dictionary in scenario.rules.get("structures", []): var structure := StructureSimulationState.from_dict(row); state.structures[structure.structure_id] = structure
	return state
