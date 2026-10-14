class_name ProcgenRegionFrameProfile
extends Resource

## Presentation-only region frame: names the macro envelope around a generated
## region and selects the permanent underlay used beyond its exterior boundary.
## It owns no walkability, collision, navigation, streaming or biome authority.

@export var profile_id: StringName = &""
@export var display_name := ""
@export var underlay_profile: ProcgenUnderlayProfile
## Optional frame-specific vocabulary for the presentation-only exterior cliff.
@export var cliff_fascia_profile: ProcgenCliffFasciaProfile
## True while the bound underlay is a stand-in for art that does not exist yet.
## Reported through telemetry so a fallback is never mistaken for final art.
@export var visual_fallback := false
@export var fallback_reason := ""


func is_valid() -> bool:
	return profile_id != &"" and underlay_profile != null and underlay_profile.is_valid()
