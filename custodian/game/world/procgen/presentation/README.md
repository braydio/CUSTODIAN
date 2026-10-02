# Procgen Presentation

Presentation-only systems derived from accepted procgen semantics live here.
Generated-region macro border/depth selection is governed by `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`. The first starting region uses `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`. Archive Resolve remains separately governed by `STREAMING_REVEAL_PRESENTATION_V1.md`.
They may plan and instantiate visual nodes, but never own or mutate simulation,
terrain, collision, navigation, minimap, required-cell, or save authority.

`ProcgenMacroPresentationComposer` is the generic region/stamp system. It is
distinct from the Sundered Keep shoreline compositor and the void-cliff fascia
renderer; those specialized systems are not replaced by Macro Presentation V1.

