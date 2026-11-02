from textual.widgets import Static


class MotionControls(Static):
    """Current Motion Lab state only — key hints live in ContextKeyBar."""

    def show(
        self, *, mode: str, heading: str, ground: str, curve: str,
        travel_px: float, fps: float, loop: bool, loop_cycles: int,
    ) -> None:
        loop_text = f"ON · {loop_cycles} CYCLES" if loop else "OFF · ONE PASS"
        self.update(
            f"MODE      {mode.upper()}\n"
            f"HEADING   {heading.upper()}\n"
            f"GROUND    {ground.replace('_', ' ').upper()}\n"
            f"CURVE     {curve.replace('_', ' ').upper()}\n"
            f"TRAVEL    {travel_px:.0f} px / cycle\n"
            f"LOOP      {loop_text}\n"
            f"FPS       {fps:.1f}"
        )
