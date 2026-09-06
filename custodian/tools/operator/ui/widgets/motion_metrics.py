from textual.widgets import Static


class MotionMetrics(Static):
    def show(self, sample, frames: int, warnings: tuple[str, ...] = (), contact_available: bool = False, mode: str = "treadmill") -> None:
        # TREADMILL reviews cumulative travel across however many cycles have
        # played (it never resets), while WORLD reviews one traversal in
        # isolation and resets to the cycle start each loop.
        position = sample.continuous_position_px if mode == "treadmill" else sample.phase_position_px
        lines = [
            f"FRAME       {sample.frame_index + 1} / {frames}",
            f"CYCLE       {sample.cycle_index + 1}",
            f"TIME        {sample.phase_sec:.3f} / {sample.duration_sec:.3f} s",
            f"PROGRESS    {sample.normalized * 100:.1f}%",
            f"POSITION    {position:.0f} px",
            f"TARGET      {sample.average_speed * sample.duration_sec:.0f} px",
            f"AVG SPEED   {sample.average_speed:.1f} px/s",
            f"NOW         {sample.current_speed:.1f} px/s",
            "CONTACT DATA: AVAILABLE" if contact_available else "CONTACT DATA: UNAVAILABLE",
        ]
        lines.extend(warnings)
        self.update("\n".join(lines))
