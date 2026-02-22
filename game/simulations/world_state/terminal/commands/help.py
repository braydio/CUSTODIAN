"""HELP command handler with category tree output."""


TOPIC_LINES = {
    "CORE": [
        "HELP > CORE",
        "- STATUS  View current operational summary",
        "- STATUS FULL  View extended diagnostics",
        "- STATUS <FAB|POSTURE|ASSAULT|POLICY|SYSTEMS>  View grouped subsystem detail",
        "- WAIT  Advance one command wait cycle",
        "- WAIT NX  Advance N wait cycles",
        "- WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>  Advance until condition",
        "- HELP  Show command tree or topic details",
    ],
    "MOVEMENT": [
        "HELP > MOVEMENT",
        "- DEPLOY <TARGET>  Exit command center via transit",
        "- MOVE <TARGET>  Traverse connected sectors/routes",
        "- RETURN  Return to command center authority",
    ],
    "SYSTEMS": [
        "HELP > SYSTEMS",
        "- FOCUS <SECTOR>  Prioritize protection for one sector",
        "- HARDEN  Shift to system-wide defensive posture",
        "- REPAIR <STRUCTURE>  Queue targeted repair",
        "- REPAIR <STRUCTURE> FULL  Immediate full restore at extra cost",
        "- SCAVENGE  Run one material recovery cycle",
        "- SCAVENGE NX  Run N material recovery cycles",
    ],
    "POLICY": [
        "HELP > POLICY",
        "- SET <REPAIR|DEFENSE|SURVEILLANCE> <0-4>  Set policy weight",
        "- SET FAB <DEFENSE|DRONES|REPAIRS|ARCHIVE> <0-4>  Set fabrication priority",
        "- FORTIFY <SECTOR> <0-4>  Set passive fortification level",
        "- POLICY SHOW  Show policy state and allocations",
        "- POLICY PRESET <NAME>  Apply balanced preset bundle",
        "- CONFIG DOCTRINE <NAME>  Switch defense doctrine preset",
        "- ALLOCATE DEFENSE <SECTOR|GROUP> <PERCENT>  Bias defense routing",
    ],
    "FABRICATION": [
        "HELP > FABRICATION",
        "- FAB ADD <ITEM>  Queue item production",
        "- FAB QUEUE  View active fabrication queue",
        "- FAB CANCEL <ID>  Cancel queued fabrication job",
        "- FAB PRIORITY <CATEGORY>  Reorder by category priority",
    ],
    "ASSAULT": [
        "HELP > ASSAULT",
        "- SCAN RELAYS  Scan relay network links from command",
        "- STABILIZE RELAY <ID>  Field stabilization task at relay sector",
        "- SYNC  Convert stabilized relay packets to knowledge",
        "- REROUTE POWER <SECTOR>  Push emergency power to sector",
        "- BOOST DEFENSE <SECTOR>  Increase active mitigation",
        "- DEPLOY DRONE <SECTOR>  Dispatch drone support (alias)",
        "- DRONE DEPLOY <SECTOR>  Dispatch drone support",
        "- LOCKDOWN <SECTOR>  Isolate sector to contain damage",
        "- PRIORITIZE REPAIR <SECTOR>  Raise repair routing priority",
    ],
    "STATUS": [
        "HELP > STATUS",
        "- STATUS  Compact status readout",
        "- STATUS FULL  Detailed status with diagnostics",
        "- STATUS FAB  Fabrication queue, allocation, and stocks",
        "- STATUS POSTURE  Command posture and readiness",
        "- STATUS ASSAULT  Assault tracks and ETA detail",
        "- STATUS POLICY  Doctrine, allocation, and policy sliders",
        "- STATUS SYSTEMS  Sector and structure system detail",
        "- STATUS RELAY  Relay-network scan and knowledge state",
    ],
}


def _help_index(dev_mode: bool) -> list[str]:
    lines = [
        "COMMAND TREE",
        "USE: HELP <TOPIC>",
        "TOPICS: CORE | MOVEMENT | SYSTEMS | POLICY | FABRICATION | ASSAULT | STATUS",
        "",
        "[CORE] STATUS | WAIT | HELP",
        "[MOVEMENT] DEPLOY | MOVE | RETURN",
        "[SYSTEMS] FOCUS | HARDEN | REPAIR | SCAVENGE",
        "[POLICY] SET | FORTIFY | POLICY | CONFIG | ALLOCATE",
        "[FABRICATION] FAB ADD | QUEUE | CANCEL | PRIORITY",
        "[ASSAULT] SCAN | STABILIZE | SYNC | REROUTE | BOOST | DRONE | LOCKDOWN | PRIORITIZE",
        "[STATUS] STATUS | STATUS FULL | STATUS <FAB|POSTURE|ASSAULT|POLICY|SYSTEMS|RELAY>",
    ]
    if dev_mode:
        lines.extend(["", "DEBUG COMMANDS (DEV MODE):", "- DEBUG HELP"])
    return lines


def cmd_help(dev_mode: bool = False, topic: str | None = None) -> list[str]:
    """Return categorized help index or topic details."""

    if not topic:
        return _help_index(dev_mode)

    key = topic.strip().upper()
    lines = TOPIC_LINES.get(key)
    if lines:
        return lines
    return [
        "UNKNOWN HELP TOPIC.",
        "USE: HELP <TOPIC>",
        "TOPICS: CORE | MOVEMENT | SYSTEMS | POLICY | FABRICATION | ASSAULT | STATUS",
    ]
