"""Compatibility shim for terminal command package imports.

This module remains for backward compatibility with older import paths.
Use `game.simulations.world_state.terminal.commands` package modules directly.
"""

from game.simulations.world_state.terminal.result import CommandResult

__all__ = ["CommandResult"]
