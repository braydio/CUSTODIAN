from textual.widgets import Static
from textual.message import Message


class PreviewControls(Static):
    class Scrubbed(Message):
        def __init__(self, ratio: float): super().__init__(); self.ratio = ratio

    def show(self, *, frame: int, frames: int, fps: float, playing: bool, loop: bool, source: str, zoom: str = "auto", view: str | None = None, compare_source: str | None = None) -> None:
        state = "PLAY" if playing else "PAUSE"
        examiner = ""
        if view and view != "single": examiner = f"   VIEW: {view.upper()}" + (f"   VS: {compare_source.upper()}" if compare_source else "")
        self.update(f"{state}   FRAME {frame + 1} / {frames}   REVIEW FPS {fps:.1f}   LOOP {'✓' if loop else '×'}   SOURCE: {source.upper()}   ZOOM: {zoom.upper()}{examiner}")

    def on_click(self, event) -> None:
        self.post_message(self.Scrubbed(max(0.0, min(1.0, event.x / max(1, self.size.width - 1)))))
