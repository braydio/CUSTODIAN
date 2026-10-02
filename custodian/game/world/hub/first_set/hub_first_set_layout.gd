class_name HubFirstSetLayout
extends RefCounted

const CELL_SIZE := 32.0
const WORLD_BOUNDS := Rect2(-2816.0, -5504.0, 6016.0, 6080.0)
const GRID_ORIGIN := Vector2(-2816.0, -5504.0)
const GRID_SIZE := Vector2i(188, 190)

const ENVELOPES := {
	"north_processional": Rect2i(72, 97, 32, 36),
	"ashen_forum": Rect2i(48, 46, 80, 56),
	"sepulcher_gardens": Rect2i(8, 50, 36, 44),
	"sepulcher_connector": Rect2i(44, 68, 4, 8),
	"lower_archive_rise": Rect2i(66, 9, 44, 40),
	"crown_transfer_court": Rect2i(110, 14, 24, 24),
	"muster_court": Rect2i(132, 56, 34, 44),
	"muster_connector": Rect2i(128, 70, 4, 10),
	"continuity_port_chamber": Rect2i(166, 64, 22, 28),
}

const THRESHOLD_VOLUME := Rect2(3104.0, -3072.0, 96.0, 128.0)

# Road module positions remain owned by RoadOfWitnessesPrototype.MODULES.
# These lower-route rectangles only define walkability over that presentation.
const WALKABLE_REGIONS: Array[Rect2i] = [
	Rect2i(80, 132, 18, 58), # South Reach and Witness approach
	Rect2i(60, 142, 58, 16), # existing side courts and plaza apron
	ENVELOPES["north_processional"],
	ENVELOPES["ashen_forum"],
	ENVELOPES["sepulcher_gardens"],
	ENVELOPES["sepulcher_connector"],
	ENVELOPES["lower_archive_rise"],
	ENVELOPES["crown_transfer_court"],
	ENVELOPES["muster_court"],
	ENVELOPES["muster_connector"],
	ENVELOPES["continuity_port_chamber"],
]

const MARKERS := {
	"Spawn_SouthReach": Vector2(-6.0, 162.0),
	"AdjudicationDais": Vector2(0.0, -3136.0),
	"ForumSouth": Vector2(0.0, -2464.0),
	"ForumNorth": Vector2(0.0, -3904.0),
	"WestGardenThreshold": Vector2(-1280.0, -3200.0),
	"EastMusterThreshold": Vector2(1280.0, -3104.0),
	"SepulcherInteriorSample": Vector2(-1984.0, -3200.0),
	"CrownTransfer": Vector2(1088.0, -4672.0),
	"Spawn_TwinReturn": Vector2(864.0, -4672.0),
	"MusterEntry": Vector2(1472.0, -3008.0),
	"MusterCenter": Vector2(1952.0, -3008.0),
	"Spawn_CampaignReturn": Vector2(2592.0, -3008.0),
	"ContinuityPort": Vector2(2944.0, -3008.0),
	"CampaignExitThreshold": Vector2(3136.0, -3008.0),
}

const MARKER_LABEL_OFFSETS := {
	"CrownTransfer": Vector2(-220.0, -84.0),
	"EastMusterThreshold": Vector2(-260.0, -84.0),
	"Spawn_CampaignReturn": Vector2(24.0, -92.0),
	"ContinuityPort": Vector2(24.0, 0.0),
	"CampaignExitThreshold": Vector2(24.0, 92.0),
}

const DISTRICT_COLORS := {
	"north_processional": Color("4b555a"),
	"ashen_forum": Color("62686a"),
	"sepulcher_gardens": Color("4d5b50"),
	"lower_archive_rise": Color("46545d"),
	"crown_transfer_court": Color("4c4a72"),
	"muster_court": Color("6a5d42"),
	"continuity_port_chamber": Color("4e646b"),
}

static func marker_cell(marker_name: StringName) -> Vector2i:
	var point: Vector2 = MARKERS.get(String(marker_name), Vector2.ZERO)
	return Vector2i(floori((point.x - GRID_ORIGIN.x) / CELL_SIZE), floori((point.y - GRID_ORIGIN.y) / CELL_SIZE))

static func cell_center(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
