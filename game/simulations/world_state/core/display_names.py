"""User-facing display names for internal location and relay identifiers."""

from __future__ import annotations


LOCATION_DISPLAY = {
    "COMMAND": "COMMAND CENTER",
    "T_NORTH": "NORTH TRANSIT",
    "T_SOUTH": "SOUTH TRANSIT",
    "INGRESS_N": "NORTH INGRESS",
    "INGRESS_S": "SOUTH INGRESS",
}

RELAY_DISPLAY = {
    "R_NORTH": "NORTH RELAY",
    "R_SOUTH": "SOUTH RELAY",
    "R_ARCHIVE": "ARCHIVE RELAY",
    "R_GATEWAY": "GATEWAY RELAY",
}


def display_location(name: str) -> str:
    token = str(name).strip().upper()
    if not token:
        return "UNKNOWN"
    return LOCATION_DISPLAY.get(token, token)


def display_relay(relay_id: str) -> str:
    token = str(relay_id).strip().upper()
    if not token:
        return "UNKNOWN RELAY"
    return RELAY_DISPLAY.get(token, token.replace("_", " "))

