from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label, RadioButton, RadioSet, Static


class CanvasResizeDialog(ModalScreen[dict | None]):
    """Choose a target frame canvas and publishing scope."""
    def __init__(self, current: tuple[int, int]) -> None:
        super().__init__()
        self.current = current

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("RESIZE FRAME CANVAS", classes="dialog-title")
            yield Static(f"Current document       {self.current[0]} × {self.current[1]}\nCENTER CANVAS · NO PIXEL SCALING", classes="dialog-body")
            with Horizontal():
                yield Input(str(128 if self.current != (128, 128) else 96), placeholder="Target width", type="integer", id="canvas-width")
                yield Input(str(128 if self.current != (128, 128) else 96), placeholder="Target height", type="integer", id="canvas-height")
            with Horizontal():
                yield Button("96 × 96", id="preset-96")
                yield Button("128 × 128", id="preset-128")
            with RadioSet(id="canvas-scope"):
                yield RadioButton("Animation layers (Operator-authored presentation)", value=True)
                yield RadioButton("Body only")
                yield RadioButton("All editable publishing layers · broader/riskier")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel")
                yield Button("REVIEW MIGRATION", id="confirm", variant="primary")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id in ("preset-96", "preset-128"):
            value = "96" if event.button.id == "preset-96" else "128"
            self.query_one("#canvas-width", Input).value = value
            self.query_one("#canvas-height", Input).value = value
            return
        if event.button.id == "cancel":
            self.dismiss(None)
            return
        try:
            width = int(self.query_one("#canvas-width", Input).value)
            height = int(self.query_one("#canvas-height", Input).value)
        except ValueError:
            self.app.notify("Enter positive integer canvas dimensions.", severity="warning")
            return
        if width <= 0 or height <= 0:
            self.app.notify("Enter positive integer canvas dimensions.", severity="warning")
            return
        scopes = ("animation", "body", "all")
        index = self.query_one("#canvas-scope", RadioSet).pressed_index
        self.dismiss({"width": width, "height": height, "scope": scopes[index if index >= 0 else 0]})
