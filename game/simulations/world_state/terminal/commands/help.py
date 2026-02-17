"""HELP command handler."""


def cmd_help(dev_mode: bool = False) -> list[str]:
    """Return the locked Phase 1 command list."""

    lines = [
        "AVAILABLE COMMANDS:",
        "- STATUS   View current situation",
        "- WAIT     Advance time (1 tick)",
        "- WAIT NX  Advance time by N x 1 tick",
        "- WAIT UNTIL <COND>  Advance until ASSAULT/APPROACH/REPAIR_DONE",
        "- DEPLOY   Leave command via transit",
        "- MOVE     Traverse transit and sectors",
        "- RETURN   Return to command center",
        "- FOCUS    Reallocate attention to a sector",
        "- HARDEN   Reinforce systems against impact",
        "- REPAIR   Begin structure repair",
        "- REPAIR <ID> FULL  Force sector stabilization",
        "- SET <POLICY> <0-4>  Set REPAIR/DEFENSE/SURVEILLANCE",
        "- SET FAB <CAT> <0-4>  Set FAB DEFENSE/DRONES/REPAIRS/ARCHIVE",
        "- FORTIFY <SECTOR> <0-4>  Set sector fortification level",
        "- SCAVENGE Recover materials",
        "- SCAVENGE NX  Run N scavenge cycles",
        "- CONFIG   Set defense doctrine",
        "- ALLOCATE Set defense allocation bias",
        "- HELP     Show this list",
    ]
    if dev_mode:
        lines.extend(
            [
                "",
                "DEBUG COMMANDS (DEV MODE):",
                "- DEBUG HELP",
            ]
        )
    return lines
