from PIL import Image
from rich.text import Text
from textual.widgets import Static


class PreviewCanvas(Static):
    """Small nearest-neighbor terminal projection; source pixels stay untouched."""
    def show_frame(self, frame: Image.Image, label: str = "") -> None:
        rgba = frame.convert("RGBA")
        target_width = min(48, rgba.width)
        target_height = max(1, round(rgba.height * target_width / rgba.width / 2))
        image = rgba.resize((target_width, target_height * 2), Image.Resampling.NEAREST)
        text = Text(label + "\n", justify="center")
        for y in range(0, image.height, 2):
            for x in range(image.width):
                top, bottom = image.getpixel((x, y)), image.getpixel((x, y + 1))
                if top[3] == 0 and bottom[3] == 0: text.append(" ")
                else: text.append("▀", style=f"rgb({top[0]},{top[1]},{top[2]}) on rgb({bottom[0]},{bottom[1]},{bottom[2]})")
            text.append("\n")
        self.update(text)
