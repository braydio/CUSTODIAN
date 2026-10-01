extends SceneTree

## Placeholder path-existence stub for `procgen-pause-aware-streaming` (M3).
##
## This file exists only to satisfy dispatch.py's pre-claim structural check
## (task_packet_contract.validate_packet_validation_references), which rejects
## a ready/auto packet whose Validation field names a script that is not yet
## present on origin/main. PROCGEN_PAUSE_AWARE_STREAMING.md's own Work surface
## calls for this script to be authored as part of that packet's
## implementation, which created a claim deadlock: the packet could not be
## claimed to write the file the claim gate required to already exist.
##
## The M3 implementation workstream must replace this entire file with the
## real pause/resume PREPARE-COMMIT smoke described in the packet's
## Validation field and register it in validation_manifest.json. Until then
## this stub intentionally fails if executed, so it is never mistaken for
## real coverage.


func _init() -> void:
	push_error("[ProcgenPauseAwareStreamingSmoke] placeholder stub: real coverage not yet implemented (see procgen-pause-aware-streaming packet)")
	quit(1)
