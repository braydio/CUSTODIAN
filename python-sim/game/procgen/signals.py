"""Canonical signal registry for procedural projection."""

from __future__ import annotations

from enum import Enum


class Signal(str, Enum):
    """Semantic signal types used as projection inputs."""

    # Assault
    ASSAULT_INBOUND = "ASSAULT_INBOUND"
    ASSAULT_WARNING = "ASSAULT_WARNING"
    ASSAULT_ACTIVE = "ASSAULT_ACTIVE"

    # General simulation/event
    EVENT_DETECTED = "EVENT_DETECTED"
    STATUS_DECLINING = "STATUS_DECLINING"

    # Repair, relay, and fabrication
    REPAIR_COMPLETED = "REPAIR_COMPLETED"
    RELAY_ACTIVITY = "RELAY_ACTIVITY"
    FABRICATION_ACTIVITY = "FABRICATION_ACTIVITY"

