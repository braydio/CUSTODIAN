"""Phase 1 terminal command handlers."""

from .focus import cmd_focus
from .harden import cmd_harden
from .help import cmd_help
from .deploy import cmd_deploy
from .move import cmd_move
from .repair import cmd_repair
from .return_cmd import cmd_return
from .reset import cmd_reset
from .scavenge import cmd_scavenge
from .status import cmd_status
from .wait import cmd_wait, cmd_wait_ticks

__all__ = [
    "cmd_deploy",
    "cmd_focus",
    "cmd_harden",
    "cmd_help",
    "cmd_move",
    "cmd_repair",
    "cmd_return",
    "cmd_reset",
    "cmd_scavenge",
    "cmd_status",
    "cmd_wait",
    "cmd_wait_ticks",
]
