from textual.app import ComposeResult
from textual.containers import Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Label, Static


class ErrorDialog(ModalScreen[None]):
    def __init__(self, title: str, message: str) -> None:
        super().__init__(); self.error_title = title; self.error_message = message

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog error-dialog"):
            yield Label(self.error_title, classes="dialog-title")
            yield Static(self.error_message, classes="dialog-body")
            yield Button("CLOSE", id="close", variant="error")

    def on_button_pressed(self, _event: Button.Pressed) -> None: self.dismiss(None)
