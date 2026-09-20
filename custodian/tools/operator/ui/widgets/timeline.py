from textual.widgets import DataTable


class TimelineTable(DataTable):
    def on_mount(self) -> None:
        self.add_columns("CLIP", "IDENTITY", "DIR", "LOOPS", "TRIM", "REVIEW FPS")
        self.cursor_type = "row"

    def set_sequence(self, sequence) -> None:
        self.clear()
        for index, clip in enumerate(sequence.clips, 1):
            start = "1" if clip.start_frame is None else str(clip.start_frame + 1)
            end = "END" if clip.end_frame is None else str(clip.end_frame + 1)
            trim = "all" if clip.start_frame is None and clip.end_frame is None else f"{start}–{end}"
            self.add_row(str(index), f"{clip.profile}/{clip.group}/{clip.action}", clip.direction, str(clip.loops), trim, f"{clip.review_fps:.1f}")

    def selected_clip_index(self) -> int:
        return self.cursor_row

    def select_clip(self, index: int) -> None:
        if self.row_count > 0 and 0 <= index < self.row_count:
            self.move_cursor(row=index)
