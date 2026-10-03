from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Label, Static


class ErrorDialog(ModalScreen[None]):
    BINDINGS = [
        Binding("escape", "close", "Close", priority=True),
        Binding("enter", "close", "Close", priority=True),
    ]

    def __init__(self, title: str, message: str) -> None:
        super().__init__(); self.error_title = title; self.error_message = message

    def compose(self) -> ComposeResult:
        with Vertical(classes="dialog error-dialog"):
            yield Label(self.error_title, classes="dialog-title")
            yield Static(self.error_message, classes="dialog-body", markup=False)
            yield Button("CLOSE", id="close", variant="error")

    def on_mount(self) -> None:
        self.query_one("#close", Button).focus()

    def action_close(self) -> None:
        self.dismiss(None)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        event.stop()
        self.action_close()
