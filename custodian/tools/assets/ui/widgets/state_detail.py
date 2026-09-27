"""Renders the actual Asset V2 contract for the selected state — never an inference."""
from textual.widgets import Static

from ..state import FamilyProjection, StateProjection


class StateDetail(Static):
    def show(self, projection: FamilyProjection, state: StateProjection | None) -> None:
        if state is None:
            self.update("Select a state to inspect its Asset V2 contract.")
            return
        kind = "animated" if state.animation else "static"
        fps = f"{state.fps:.0f} fps" if state.fps else "—"
        frames = f"{state.expected_frames} frames (declared)" if state.expected_frames else "frame count: unconstrained by contract"
        required_dirs = ", ".join(direction.upper() for direction in state.required_directions) or "none"
        directions = "  ".join(f"{item.direction.upper()}:{item.status[0].upper()}" for item in state.directions) or "—"
        heading = f"{projection.family_id} / {state.state_id}"
        lines = [
            heading,
            "─" * len(heading),
            f"layer / action_group / variant   {state.layer} / {state.action_group} / {state.variant}",
            f"tier                              {state.tier}",
            f"kind                              {kind} · {fps}",
            frames,
            f"canvas                            {projection.canvas[0]}x{projection.canvas[1]}",
            "",
            f"required directions               {required_dirs}",
            f"direction coverage (A=authored, M=mirrored, -=missing)",
            f"  {directions}",
            "",
            f"art present                       {'yes' if state.art_present else 'no'}",
            f"Godot import                      {'yes' if state.imported else 'no'}",
            f"runtime binding                   {'yes' if state.bound else 'no'}",
            f"runtime test verified             {'yes' if state.runtime_verified else 'no'}",
            f"runtime path                      {state.runtime_path or '—'}",
            f"inbox pending for this state       {'yes' if state.source_pending else 'no'}",
        ]
        self.update("\n".join(lines))
