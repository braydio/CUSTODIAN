class_name TwinSolariaLayout
extends RefCounted

const MASTER_SIZE := Vector2i(2048, 1536)
const WORLD_BOUNDS := Rect2(-1024.0, -768.0, 2048.0, 1536.0)
const SPAWN_CROWN_CAUSEWAY := Vector2(-94.0, 682.0)
const RETURN_CROWN_TRANSFER := Vector2(-94.0, 682.0)

const PLATES: Array[Dictionary] = [
	{"id": &"solarium_i_acquisition_court", "node": "SolariumIAcquisitionCourt", "size": Vector2i(617, 695), "position": Vector2(-687.5, -335.5), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_solarium_i_acquisition_court_617x695.png"},
	{"id": &"upper_crown_court", "node": "UpperCrownCourt", "size": Vector2i(697, 520), "position": Vector2(-90.5, -328.0), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_upper_crown_court_697x520.png"},
	{"id": &"authority_threshold_plate", "node": "AuthorityThresholdPlate", "size": Vector2i(375, 355), "position": Vector2(-101.5, -35.5), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_authority_threshold_plate_375x355.png"},
	{"id": &"reciprocity_midcourt", "node": "ReciprocityMidcourt", "size": Vector2i(1190, 525), "position": Vector2(-19.0, 144.5), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_reciprocity_midcourt_1190x525.png"},
	{"id": &"home_index_lowercourt", "node": "HomeIndexLowercourt", "size": Vector2i(825, 385), "position": Vector2(-71.5, 489.5), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_home_index_lowercourt_825x385.png"},
	{"id": &"west_service_terrace", "node": "WestServiceTerrace", "size": Vector2i(275, 340), "position": Vector2(-536.5, 412.0), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_west_service_terrace_275x340.png"},
	{"id": &"east_service_terrace", "node": "EastServiceTerrace", "size": Vector2i(275, 340), "position": Vector2(473.5, 412.0), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_east_service_terrace_275x340.png"},
	{"id": &"crown_causeway", "node": "CrownCauseway", "size": Vector2i(245, 216), "position": Vector2(-91.5, 660.0), "path": "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_crown_causeway_245x216.png"},
]

const FIDELITY_UNDERLAY_PATH := "res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_fidelity/twin_solaria_v1_fidelity_fidelity_underlay_2048x1536.png"

const LANDMARKS := {
	&"outbound_anchor": {"position": Vector2(-322.0, -418.0), "label": "OUTBOUND ANCHOR"},
	&"reciprocal_anchor": {"position": Vector2(128.5, -418.0), "label": "RECIPROCAL ANCHOR"},
	&"meridian_needle": {"position": Vector2(-100.0, -560.5), "label": "MERIDIAN NEEDLE"},
	&"reciprocity_dial": {"position": Vector2(-91.5, -293.0), "label": "RECIPROCITY DIAL"},
	&"authority_threshold": {"position": Vector2(-91.5, -13.0), "label": "AUTHORITY THRESHOLD"},
	&"west_echo_drum": {"position": Vector2(-391.5, 214.5), "label": "WEST ECHO DRUM"},
	&"east_echo_drum": {"position": Vector2(248.5, 214.5), "label": "EAST ECHO DRUM"},
	&"home_index": {"position": Vector2(-99.0, 442.0), "label": "HOME INDEX"},
	&"archive_witness_ring": {"position": Vector2(-334.0, 562.0), "label": "ARCHIVE WITNESS RING"},
	&"live_witness_ring": {"position": Vector2(186.0, 562.0), "label": "LIVE WITNESS RING"},
	&"blind_witness": {"position": Vector2(-691.5, 207.0), "label": "BLIND WITNESS"},
	&"second_crown_root": {"position": Vector2(233.5, -308.0), "label": "SECOND CROWN ROOT"},
}

const POIS: Array[Dictionary] = [
	{"id": &"home_index", "landmark": &"home_index", "title": "HOME INDEX", "readout": "HOME INDEX\nLOCAL RECORD: DORMANT\nRETURN PATH: NOT OPEN"},
	{"id": &"archive_witness_ring", "landmark": &"archive_witness_ring", "title": "ARCHIVE WITNESS RING", "readout": "ARCHIVE WITNESS\nSTATE: DORMANT\nRECIPROCAL STATUS: UNRESOLVED"},
	{"id": &"live_witness_ring", "landmark": &"live_witness_ring", "title": "LIVE WITNESS RING", "readout": "LIVE WITNESS\nSTATE: DORMANT\nCOUNTERPART: UNRESOLVED"},
	{"id": &"reciprocity_dial", "landmark": &"reciprocity_dial", "title": "RECIPROCITY DIAL", "readout": "RECIPROCITY: NOT ESTABLISHED\nROUTE CANDIDATE: NONE\nACTIVATION: UNAVAILABLE"},
	{"id": &"blind_witness", "landmark": &"blind_witness", "title": "BLIND WITNESS", "readout": "WITNESS RECORD: INCOMPLETE\nINTERPRETATION: UNRESOLVED"},
	{"id": &"solarium_i_acquisition_aperture", "landmark": &"outbound_anchor", "title": "SOLARIUM I / ACQUISITION APERTURE", "readout": "SOLARIUM I\nACQUISITION RECORD: DORMANT\nCONTINUITY: UNRESOLVED"},
	{"id": &"second_crown_root", "landmark": &"second_crown_root", "title": "SECOND CROWN ROOT / THE AMPUTATION", "readout": "SECOND CROWN ROOT\nSTRUCTURAL ABSENCE: OBSERVED\nCAUSE: UNRESOLVED"},
]

const AUTHORED_BOUNDARY_SEGMENTS: Array[Array] = [
	[Vector2(-850.0, -660.0), Vector2(-1000.0, -300.0)],
	[Vector2(-1000.0, -300.0), Vector2(-960.0, -60.0)],
	[Vector2(-960.0, -60.0), Vector2(-810.0, 70.0)],
	[Vector2(-810.0, 70.0), Vector2(-735.0, 180.0)],
	[Vector2(-735.0, 180.0), Vector2(-690.0, 390.0)],
	[Vector2(-690.0, 390.0), Vector2(-520.0, 560.0)],
	[Vector2(-520.0, 560.0), Vector2(-350.0, 700.0)],
	[Vector2(-350.0, 700.0), Vector2(-300.0, 760.0)],
	[Vector2(-300.0, 760.0), Vector2(270.0, 760.0)],
	[Vector2(270.0, 760.0), Vector2(500.0, 700.0)],
	[Vector2(500.0, 700.0), Vector2(640.0, 580.0)],
	[Vector2(640.0, 580.0), Vector2(670.0, 340.0)],
	[Vector2(670.0, 340.0), Vector2(470.0, 120.0)],
	[Vector2(470.0, 120.0), Vector2(380.0, 30.0)],
	[Vector2(380.0, 30.0), Vector2(300.0, -200.0)],
	[Vector2(300.0, -200.0), Vector2(290.0, -560.0)],
	[Vector2(290.0, -560.0), Vector2(210.0, -640.0)],
	[Vector2(210.0, -640.0), Vector2(-340.0, -640.0)],
	[Vector2(-340.0, -640.0), Vector2(-850.0, -660.0)],
]


static func poi_position(poi: Dictionary) -> Vector2:
	var landmark: Dictionary = LANDMARKS.get(poi.get("landmark", &""), {})
	return landmark.get("position", Vector2.ZERO) as Vector2
