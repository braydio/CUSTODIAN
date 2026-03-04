"""Terminal interface for the world-state simulation."""

from .processor import process_command
from .result import CommandResult

__all__ = ["CommandResult", "process_command"]
