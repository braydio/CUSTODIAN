from textual.widgets import DataTable


class TimelineTable(DataTable):
    def on_mount(self) -> None:
        self.add_columns("CLIP", "IDENTITY", "DIR", "LOOPS", "TRIM", "REVIEW FPS")
        self.cursor_type = "row"

    def set_sequence(self, sequence) -> None:
        self.clear()
        for index, clip in enumerate(sequence.clips, 1):
            trim = "all" if clip.start_frame is None else f"{clip.start_frame + 1}–{clip.end_frame + 1}"
            self.add_row(str(index), f"{clip.profile}/{clip.group}/{clip.action}", clip.direction, str(clip.loops), trim, f"{clip.review_fps:.1f}")
