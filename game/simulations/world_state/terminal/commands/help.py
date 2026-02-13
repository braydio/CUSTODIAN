"""HELP command handler."""


def cmd_help() -> list[str]:
    """Return the locked Phase 1 command list."""

    return [
        "AVAILABLE COMMANDS:",
        "- STATUS   View current situation",
        "- WAIT     Advance time (5 ticks)",
        "- WAIT NX  Advance time by N x 5 ticks",
        "- DEPLOY   Leave command via transit",
        "- MOVE     Traverse transit and sectors",
        "- RETURN   Return to command center",
        "- FOCUS    Reallocate attention to a sector",
        "- HARDEN   Reinforce systems against impact",
        "- REPAIR   Begin structure repair",
        "- SCAVENGE Recover materials",
        "- HELP     Show this list",
    ]
