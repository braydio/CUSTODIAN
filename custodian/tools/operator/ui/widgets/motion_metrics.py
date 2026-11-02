from textual.widgets import Static


class MotionMetrics(Static):
    def show(
        self, sample, frames: int, warnings: tuple[str, ...] = (),
        contact_available: bool = False, *, loop: bool = True, loop_cycles: int = 3,
    ) -> None:
        cycle_number = sample.cycle_index + 1 if loop else 1
        cycle_total = max(1, loop_cycles) if loop else 1
        total_position = sample.continuous_position_px if loop else sample.phase_position_px
        per_cycle_target = sample.average_speed * sample.duration_sec
        lines = [
            f"FRAME       {sample.frame_index + 1} / {frames}",
            f"CYCLE       {cycle_number} / {cycle_total}",
            f"TIME        {sample.phase_sec:.3f} / {sample.duration_sec:.3f} s",
            f"PROGRESS    {sample.normalized * 100:.1f}%",
            f"PER CYCLE   {per_cycle_target:.0f} px",
            f"CYCLE POS   {sample.phase_position_px:.0f} px",
            f"TOTAL POS   {total_position:.0f} px",
            f"AVG SPEED   {sample.average_speed:.1f} px/s",
            f"NOW         {sample.current_speed:.1f} px/s",
            "CONTACT DATA: AVAILABLE" if contact_available else "CONTACT DATA: UNAVAILABLE",
        ]
        lines.extend(warnings)
        self.update("\n".join(lines))
