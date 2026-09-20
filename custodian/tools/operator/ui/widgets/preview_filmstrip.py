from __future__ import annotations

from PIL import Image, ImageDraw
from textual.app import ComposeResult
from textual.containers import Container
from textual.message import Message
from textual_image.widget import AutoImage

THUMB_SIZE = (28, 28)
THUMB_SLOT = 32

class PreviewFilmstrip(Container):
    DEFAULT_CSS = "PreviewFilmstrip { height: 7; content-align: center middle; overflow-x: auto; } PreviewFilmstrip .filmstrip-raster { width: auto; height: auto; }"

    class Selected(Message):
        def __init__(self, index: int) -> None:
            super().__init__(); self.index = index

    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs); self._count = 0; self._current = 0; self.contact_sheet = None

    def compose(self) -> ComposeResult:
        yield AutoImage(classes="filmstrip-raster")

    def show_frames(self, frames: tuple[Image.Image, ...], *, current: int, changed: tuple[bool, ...] = ()) -> None:
        self._count = len(frames)
        if not frames:
            self.contact_sheet = None; return
        self._current = max(0, min(current, len(frames) - 1))
        sheet = Image.new("RGBA", (THUMB_SLOT * len(frames), THUMB_SLOT), (0, 0, 0, 0)); draw = ImageDraw.Draw(sheet)
        for index, frame in enumerate(frames):
            thumb = frame.convert("RGBA").copy(); thumb.thumbnail(THUMB_SIZE, Image.Resampling.NEAREST)
            sheet.alpha_composite(thumb, (index * THUMB_SLOT + (THUMB_SLOT - thumb.width) // 2, (THUMB_SLOT - thumb.height) // 2))
            left = index * THUMB_SLOT
            if index < len(changed) and changed[index]: draw.rectangle((left + 1, 1, left + THUMB_SLOT - 2, THUMB_SLOT - 2), outline=(191, 97, 106, 255))
            if index == self._current: draw.rectangle((left, 0, left + THUMB_SLOT - 1, THUMB_SLOT - 1), outline=(129, 161, 193, 255), width=2)
        self.contact_sheet = sheet; self.query_one(".filmstrip-raster", AutoImage).image = sheet

    def on_click(self, event) -> None:
        if self._count < 1: return
        ratio = max(0.0, min(0.999999, event.x / max(1, self.size.width)))
        self.post_message(self.Selected(min(self._count - 1, int(ratio * self._count))))
