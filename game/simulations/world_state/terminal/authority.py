"""Command authority policy by operator mode."""

from __future__ import annotations


COMMAND_AUTHORITY_ONLY = {
    "FOCUS",
    "HARDEN",
    "SCAVENGE",
    "CONFIG",
    "ALLOCATE",
    "SET",
    "FORTIFY",
    "FAB",
    "REROUTE",
    "BOOST",
    "DRONE",
    "LOCKDOWN",
    "PRIORITIZE",
    "SCAN",
    "SYNC",
    "POLICY",
}


def requires_command_authority(verb: str) -> bool:
    return verb in COMMAND_AUTHORITY_ONLY
