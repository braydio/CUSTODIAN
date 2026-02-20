"""Phase 1 terminal command handlers."""

from .focus import cmd_focus
from .harden import cmd_harden
from .help import cmd_help
from .deploy import cmd_deploy
from .move import cmd_move
from .config_doctrine import cmd_config_doctrine
from .allocate_defense import cmd_allocate_defense
from .policy import cmd_fortify, cmd_set_fabrication, cmd_set_policy
from .fabrication import cmd_fab_add, cmd_fab_cancel, cmd_fab_priority, cmd_fab_queue
from .assault_ops import (
    cmd_boost_defense,
    cmd_deploy_drone,
    cmd_lockdown,
    cmd_prioritize_repair,
    cmd_reroute_power,
)
from .repair import cmd_repair
from .return_cmd import cmd_return
from .reset import cmd_reset
from .scavenge import cmd_scavenge, cmd_scavenge_runs
from .status import cmd_status
from .wait import cmd_wait, cmd_wait_ticks, cmd_wait_until

__all__ = [
    "cmd_deploy",
    "cmd_fab_add",
    "cmd_fab_cancel",
    "cmd_fab_priority",
    "cmd_fab_queue",
    "cmd_allocate_defense",
    "cmd_config_doctrine",
    "cmd_fortify",
    "cmd_focus",
    "cmd_harden",
    "cmd_help",
    "cmd_move",
    "cmd_repair",
    "cmd_return",
    "cmd_reset",
    "cmd_scavenge",
    "cmd_scavenge_runs",
    "cmd_set_fabrication",
    "cmd_set_policy",
    "cmd_reroute_power",
    "cmd_boost_defense",
    "cmd_deploy_drone",
    "cmd_lockdown",
    "cmd_prioritize_repair",
    "cmd_status",
    "cmd_wait",
    "cmd_wait_ticks",
    "cmd_wait_until",
]
