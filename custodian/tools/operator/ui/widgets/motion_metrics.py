from textual.widgets import Static


class MotionMetrics(Static):
    def show(self, sample, frames: int, warnings: tuple[str, ...] = (), contact_available: bool = False) -> None:
        lines = [
            f"FRAME       {sample.frame_index + 1} / {frames}",
            f"TIME        {sample.elapsed_sec:.3f} / {sample.duration_sec:.3f} s",
            f"PROGRESS    {sample.normalized * 100:.1f}%",
            f"POSITION    {sample.position_px:.0f} px",
            f"TARGET      {sample.average_speed * sample.duration_sec:.0f} px",
            f"AVG SPEED   {sample.average_speed:.1f} px/s",
            f"NOW         {sample.current_speed:.1f} px/s",
            "CONTACT DATA: AVAILABLE" if contact_available else "CONTACT DATA: UNAVAILABLE",
        ]
        lines.extend(warnings)
        self.update("\n".join(lines))
