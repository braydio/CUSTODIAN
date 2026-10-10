class_name TwinSolariaLayout
extends AuthoredLevel2D

const READOUT_SCRIPT := preload("res://game/world/interactions/world_readout_interactable.gd")
const CANVAS_SIZE := Vector2(2048.0, 1536.0)
const CANVAS_ORIGIN := -CANVAS_SIZE * 0.5
const NAVIGATION_REGIONS: Array[Rect2i] = [Rect2i(16, 34, 32, 14)]
const PLATE_TEXTURES := {
 "solarium_i_acquisition_court": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_solarium_i_acquisition_court_617x695.png"),
 "upper_crown_court": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_upper_crown_court_697x520.png"),
 "authority_threshold_plate": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_authority_threshold_plate_375x355.png"),
 "reciprocity_midcourt": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_reciprocity_midcourt_1190x525.png"),
 "home_index_lowercourt": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_home_index_lowercourt_825x385.png"),
 "west_service_terrace": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_west_service_terrace_275x340.png"),
 "east_service_terrace": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_east_service_terrace_275x340.png"),
 "crown_causeway": preload("res://content/levels/hub/twin_solaria/v1/twin_solaria_v1_crown_causeway_245x216.png"),
}
const PLATES := [
 {"state":"solarium_i_acquisition_court","size":Vector2(617,695),"position":Vector2(-687.5,-335.5)},
 {"state":"upper_crown_court","size":Vector2(697,520),"position":Vector2(-90.5,-328.0)},
 {"state":"authority_threshold_plate","size":Vector2(375,355),"position":Vector2(-101.5,-35.5)},
 {"state":"reciprocity_midcourt","size":Vector2(1190,525),"position":Vector2(-19,144.5)},
 {"state":"home_index_lowercourt","size":Vector2(825,385),"position":Vector2(-71.5,489.5)},
 {"state":"west_service_terrace","size":Vector2(275,340),"position":Vector2(-536.5,412)},
 {"state":"east_service_terrace","size":Vector2(275,340),"position":Vector2(473.5,412)},
 {"state":"crown_causeway","size":Vector2(245,216),"position":Vector2(-91.5,660)},
]
const MARKERS := {
 "spawn_crown_causeway":{"kind":"spawn","node_name":"Spawn_CrownCauseway","position":Vector2(-91.5,660)},
 "home_index":{"kind":"poi","node_name":"HomeIndex","position":Vector2(-99,442)},
 "archive_witness_ring":{"kind":"poi","node_name":"ArchiveWitnessRing","position":Vector2(-334,562)},
 "live_witness_ring":{"kind":"poi","node_name":"LiveWitnessRing","position":Vector2(186,562)},
 "reciprocity_dial":{"kind":"poi","node_name":"ReciprocityDial","position":Vector2(-91.5,-293)},
 "blind_witness":{"kind":"poi","node_name":"BlindWitness","position":Vector2(-691.5,207)},
 "authority_threshold":{"kind":"poi","node_name":"AuthorityThreshold","position":Vector2(-91.5,-13)},
 "outbound_anchor":{"kind":"poi","node_name":"OutboundAnchor","position":Vector2(-322,-418)},
 "reciprocal_anchor":{"kind":"poi","node_name":"ReciprocalAnchor","position":Vector2(128.5,-418)},
 "meridian_needle":{"kind":"poi","node_name":"MeridianNeedle","position":Vector2(-100,-560.5)},
 "west_echo_drum":{"kind":"poi","node_name":"WestEchoDrum","position":Vector2(-391.5,214.5)},
 "east_echo_drum":{"kind":"poi","node_name":"EastEchoDrum","position":Vector2(248.5,214.5)},
 "second_crown_root":{"kind":"poi","node_name":"SecondCrownRoot","position":Vector2(233.5,-308)},
}
const READOUTS := [
 {"marker":"home_index","title":"HOME INDEX / ESTABLISH LOCAL REFERENCE","readout":"HOME INDEX
LOCAL REFERENCE: AVAILABLE
ROUTE USE: NOT AUTHORIZED

This index records the facility's local frame. A matching address is not proof of a safe reciprocal return."},
 {"marker":"archive_witness_ring","title":"ARCHIVE WITNESS / PRIOR HOLDS","readout":"ARCHIVE WITNESS
PRIOR HOLD RECORDS: PRESERVED
CURRENT ROUTE CLAIM: NOT ESTABLISHED

Historical authorization does not substitute for current field evidence."},
 {"marker":"live_witness_ring","title":"LIVE WITNESS / FIELD EVIDENCE","readout":"LIVE WITNESS
FIELD RESPONSE: DORMANT
RECIPROCAL OBSERVATION: REQUIRED

This witness records present conditions; no route candidate is active."},
 {"marker":"reciprocity_dial","title":"RECIPROCITY DIAL / RETURN-PATH REVIEW","readout":"RECIPROCITY REVIEW
RETURN PATH: UNRESOLVED
DISPOSITION: HOLD

A route that answers is not necessarily a route that returns safely. No acquisition action is available."},
 {"marker":"blind_witness","title":"BLIND WITNESS / ISOLATED CHANNEL","readout":"BLIND WITNESS
ISOLATED CHANNEL: DORMANT
REPAIR AUTHORITY: NOT PRESENT

The channel remains isolated. No missing witness state is inferred from this display."},
 {"marker":"authority_threshold","title":"AUTHORITY THRESHOLD / ACQUISITION CHECKPOINT","readout":"AUTHORITY THRESHOLD
CUSTODIAN DECISION: NOT RECORDED
ACQUISITION: NOT AUTHORIZED

Solarium I is an acquisition instrument, not an available walk-through gate."},
 {"marker":"second_crown_root","title":"SECOND CROWN / FORENSIC RECORD","readout":"SECOND CROWN
PASSAGE APERTURE: ABSENT
CAUSE: NOT RESOLVED HERE

The missing upper-right court remains absent. Its forensic history requires a separate evidence sequence."},
]

@onready var background_root: Node2D = $BackgroundRoot
@onready var blockout_grid: AuthoredBlockoutGrid2D = $BlockoutGrid
@onready var authored_navigation: AuthoredNavigationProvider2D = $NavigationRoot/AuthoredNavigationProvider

func _ready() -> void:
 camera_bounds = Rect2(CANVAS_ORIGIN, CANVAS_SIZE)
 placeholder_canvas_size = CANVAS_SIZE
 draw_placeholder_grid = false
 blockout_grid.position = CANVAS_ORIGIN
 blockout_grid.configure(32.0, Vector2i(64, 48), NAVIGATION_REGIONS)
 authored_navigation.configure(blockout_grid)
 _build_registered_plates()
 _build_readouts()
 super._ready()

func _build_registered_plates() -> void:
 for plate: Dictionary in PLATES:
  var sprite := Sprite2D.new()
  sprite.name = String(plate.state).to_pascal_case()
  sprite.texture = PLATE_TEXTURES[plate.state]
  sprite.position = plate.position
  sprite.centered = true
  sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  background_root.add_child(sprite)

func _build_readouts() -> void:
 for entry: Dictionary in READOUTS:
  var marker_data: Dictionary = MARKERS[entry.marker]
  var interactable := READOUT_SCRIPT.new() as WorldReadoutInteractable
  interactable.name = String(entry.marker).to_pascal_case() + "Readout"
  interactable.title = entry.title
  interactable.readout = entry.readout
  interactable.acknowledged_readout = "RECORD ACKNOWLEDGED\n\n" + entry.readout
  interactable.position = marker_data.position
  $POIRoot.add_child(interactable)

func get_authoring_markers() -> Dictionary:
 return MARKERS.duplicate(true)

func get_boundary_segments() -> Array:
 # The authored walkable island edge and the Second Crown void remain hard barriers.
 var loop: Array[Vector2] = [
  Vector2(-995,-400), Vector2(-975,-475), Vector2(-900,-545), Vector2(-780,-560),
  Vector2(-690,-520), Vector2(-620,-430), Vector2(-545,-330), Vector2(-430,-315),
  Vector2(-320,-400), Vector2(-255,-550), Vector2(-150,-700), Vector2(5,-740),
  Vector2(170,-700), Vector2(300,-590), Vector2(470,-520), Vector2(650,-465),
  Vector2(800,-350), Vector2(900,-180), Vector2(940,20), Vector2(930,220),
  Vector2(870,390), Vector2(770,515), Vector2(600,580), Vector2(520,680),
  Vector2(370,740), Vector2(180,755), Vector2(0,767), Vector2(-190,750),
  Vector2(-360,700), Vector2(-540,650), Vector2(-700,565), Vector2(-840,420),
  Vector2(-930,240), Vector2(-975,40), Vector2(-1005,-180)
 ]
 var segments: Array = []
 for index in loop.size():
  segments.append([loop[index], loop[(index + 1) % loop.size()]])
 # Keep the collapsed Passage court a void separated from the surviving Crown.
 segments.append([Vector2(250,-515), Vector2(820,-515)])
 segments.append([Vector2(250,-515), Vector2(250,-360)])
 segments.append([Vector2(820,-515), Vector2(820,-360)])
 return segments
