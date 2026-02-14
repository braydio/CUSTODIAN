"""Location token normalization for field movement commands."""

from game.simulations.world_state.core.location_registry import LocationRegistry


LOCATION_REGISTRY = LocationRegistry()
LOCATION_REGISTRY.register("COMMAND", ["CC", "CMD"])
LOCATION_REGISTRY.register("T_NORTH", ["TN", "NORTH"])
LOCATION_REGISTRY.register("T_SOUTH", ["TS", "SOUTH"])
LOCATION_REGISTRY.register("ARCHIVE", ["AR"])
LOCATION_REGISTRY.register("DEFENSE GRID", ["DEFENSE", "DF"])
LOCATION_REGISTRY.register("POWER", ["PW"])
LOCATION_REGISTRY.register("FABRICATION", ["FAB", "FB"])
LOCATION_REGISTRY.register("COMMS", ["CM"])
LOCATION_REGISTRY.register("STORAGE", ["ST"])
LOCATION_REGISTRY.register("HANGAR", ["HG"])
LOCATION_REGISTRY.register("GATEWAY", ["GATE", "GS"])


def resolve_location_token(raw: str) -> str | None:
    return LOCATION_REGISTRY.normalize(raw)
