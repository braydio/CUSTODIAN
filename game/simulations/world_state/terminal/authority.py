"""Command authority policy by operator mode."""

from __future__ import annotations


COMMAND_AUTHORITY_ONLY = {"FOCUS", "HARDEN", "SCAVENGE"}


def requires_command_authority(verb: str) -> bool:
    return verb in COMMAND_AUTHORITY_ONLY

