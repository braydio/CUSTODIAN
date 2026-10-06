class_name ProcGenPresentationClass
extends RefCounted

## Archive Resolve semantic presentation classes (AR3). A small, closed
## vocabulary that only biases render-side echo styling/timing. It carries no
## gameplay, discovery, quest, collision, or navigation authority and is never
## stored as a map: callers hand `classify()` the read-only facts they just
## queried from the existing owners (surface material, road, wall/elevation,
## authored-landmark claim) and receive one class for that single cell.

enum Kind { NATURAL = 0, ROAD = 1, CONSTRUCTED = 2, WALL_CLIFF = 3, MAJOR_LANDMARK = 4 }

const KIND_COUNT := 5

## Evidence-echo lead before a first-resolve cell starts dissolving, in seconds.
## Natural cells have none; the longest (major landmark) stays within the
## design's ~100-150 ms early-silhouette window.
const ECHO_LEAD_SEC: Array[float] = [0.0, 0.06, 0.04, 0.08, 0.13]


## Priority: authored landmark claim > wall/cliff > road > constructed > natural.
## Facts only; no lookups happen here.
static func classify(
	landmark_claim: bool,
	wall_or_cliff: bool,
	road: bool,
	constructed: bool
) -> int:
	if landmark_claim:
		return Kind.MAJOR_LANDMARK
	if wall_or_cliff:
		return Kind.WALL_CLIFF
	if road:
		return Kind.ROAD
	if constructed:
		return Kind.CONSTRUCTED
	return Kind.NATURAL


static func echo_lead_sec(kind: int) -> float:
	if kind <= 0 or kind >= KIND_COUNT:
		return 0.0
	return ECHO_LEAD_SEC[kind]


## Render encoding written to the AR2 `.b` custom-data channel.
static func encode(kind: int) -> float:
	return float(clampi(kind, 0, KIND_COUNT - 1)) / float(KIND_COUNT - 1)
