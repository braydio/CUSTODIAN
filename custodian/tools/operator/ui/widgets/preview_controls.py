from textual.widgets import Static
from textual.message import Message


class PreviewControls(Static):
    class Scrubbed(Message):
        def __init__(self, ratio: float): super().__init__(); self.ratio = ratio

    def show(self, *, frame: int, frames: int, fps: float, playing: bool, loop: bool, source: str) -> None:
        state = "PLAY" if playing else "PAUSE"
        self.update(f"{state}   FRAME {frame + 1} / {frames}   REVIEW FPS {fps:.1f}   LOOP {'✓' if loop else '×'}   SOURCE: {source.upper()}")

    def on_click(self, event) -> None:
        self.post_message(self.Scrubbed(max(0.0, min(1.0, event.x / max(1, self.size.width - 1)))))
