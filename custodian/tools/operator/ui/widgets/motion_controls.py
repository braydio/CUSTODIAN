from textual.widgets import Static


class MotionControls(Static):
    """Current Motion Lab state only — key hints live in ContextKeyBar."""

    def show(self, *, mode: str, ground: str, curve: str, travel_px: float, fps: float) -> None:
        self.update(
            f"MODE      {mode.upper()}\n"
            f"GROUND    {ground.replace('_', ' ').upper()}\n"
            f"CURVE     {curve.replace('_', ' ').upper()}\n"
            f"TRAVEL    {travel_px:.0f} px\n"
            f"FPS       {fps:.1f}"
        )
