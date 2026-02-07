"""HELP command handler."""


def cmd_help() -> list[str]:
    """Return the locked Phase 1 command list."""

    return [
        "AVAILABLE COMMANDS:",
        "- STATUS   View current situation",
        "- WAIT     Advance time",
        "- WAIT 10X Advance time by ten ticks",
        "- FOCUS    Reallocate attention to a sector",
        "- HELP     Show this list",
    ]
