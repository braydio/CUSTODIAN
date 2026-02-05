"""HELP command handler."""


def cmd_help() -> list[str]:
    """Return the locked Phase 1 command list."""

    return [
        "AVAILABLE COMMANDS:",
        "- STATUS   View current situation",
        "- WAIT     Advance time",
        "- HELP     Show this list",
    ]
