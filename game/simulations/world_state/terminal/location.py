"""Location token normalization for field movement commands."""

LOCATION_ALIASES = {
    "COMMAND": "COMMAND",
    "CC": "COMMAND",
    "CMD": "COMMAND",
    "T_NORTH": "T_NORTH",
    "TN": "T_NORTH",
    "NORTH": "T_NORTH",
    "T_SOUTH": "T_SOUTH",
    "TS": "T_SOUTH",
    "SOUTH": "T_SOUTH",
    "ARCHIVE": "ARCHIVE",
    "AR": "ARCHIVE",
    "DEFENSE GRID": "DEFENSE GRID",
    "DEFENSE": "DEFENSE GRID",
    "DF": "DEFENSE GRID",
    "POWER": "POWER",
    "PW": "POWER",
    "FABRICATION": "FABRICATION",
    "FAB": "FABRICATION",
    "FB": "FABRICATION",
    "COMMS": "COMMS",
    "CM": "COMMS",
    "STORAGE": "STORAGE",
    "ST": "STORAGE",
    "HANGAR": "HANGAR",
    "HG": "HANGAR",
    "GATEWAY": "GATEWAY",
    "GATE": "GATEWAY",
    "GS": "GATEWAY",
}


def resolve_location_token(raw: str) -> str | None:
    if not raw:
        return None
    token = raw.strip().upper()
    return LOCATION_ALIASES.get(token)
