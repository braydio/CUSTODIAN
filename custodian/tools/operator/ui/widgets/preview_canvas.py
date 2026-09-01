"""Raster-first preview canvas with an explicit degraded terminal fallback."""
from __future__ import annotations

from PIL import Image
from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import Static
from textual_image.widget import AutoImage, get_cell_size
from animation_preview import ZoomMode, scale_preview_frame


class PreviewCanvas(Container):
    """Feed PIL RGBA directly to TGP/Sixel when the terminal supports it."""

    DEFAULT_CSS = """
    PreviewCanvas { align: center middle; }
    PreviewCanvas .preview-label { width: 100%; height: 1; text-align: center; }
    PreviewCanvas .preview-raster { width: auto; height: auto; }
    PreviewCanvas .preview-fallback { width: 100%; height: 1; text-align: center; color: #ebcb8b; }
    """

    def __init__(self, placeholder: str = "", **kwargs) -> None:
        super().__init__(**kwargs)
        self.placeholder = placeholder
        self.source_frame: Image.Image | None = None
        self.rendered_image: Image.Image | None = None
        module = AutoImage._Renderable.__module__
        self.renderer = "TGP" if module.endswith(".tgp") else "SIXEL" if module.endswith(".sixel") else "HALF-CELL" if module.endswith(".halfcell") else "UNICODE"
        self.low_fidelity_fallback = self.renderer in ("HALF-CELL", "UNICODE")

    def compose(self) -> ComposeResult:
        yield Static(self.placeholder, classes="preview-label")
        yield AutoImage(classes="preview-raster")
        yield Static("LOW-FIDELITY FALLBACK · terminal raster protocol unavailable", classes="preview-fallback")

    def on_mount(self) -> None:
        self.query_one(".preview-fallback", Static).display = self.low_fidelity_fallback

    def _best_integer_scale(self, image: Image.Image) -> int:
        cell = get_cell_size()
        pixel_width = self.content_size.width * cell.width
        pixel_height = max(0, self.content_size.height - 2) * cell.height
        return 2 if image.width * 2 <= pixel_width and image.height * 2 <= pixel_height else 1

    def show_frame(self, frame: Image.Image, label: str = "", zoom: ZoomMode = "auto") -> None:
        self.source_frame = frame.convert("RGBA").copy()
        actual_zoom: ZoomMode | int = self._best_integer_scale(self.source_frame) if zoom == "auto" else zoom
        self.rendered_image = scale_preview_frame(self.source_frame, actual_zoom)
        raster = self.query_one(".preview-raster", AutoImage)
        if zoom == "fit":
            raster.styles.width = "100%"; raster.styles.height = "100%"
        else:
            raster.styles.width = "auto"; raster.styles.height = "auto"
        display_image = self.rendered_image
        if self.low_fidelity_fallback:
            background = Image.new("RGBA", display_image.size, (17, 21, 28, 255))
            background.alpha_composite(display_image)
            display_image = background.convert("RGB")
        raster.image = display_image
        zoom_label = "FIT (review representation)" if zoom == "fit" else f"{actual_zoom}× INTEGER"
        self.query_one(".preview-label", Static).update(f"{label} · {zoom_label} · {self.renderer}")
