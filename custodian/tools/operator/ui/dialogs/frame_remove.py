from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Label, Static
from ..state import MigrationView


class FrameRemoveDialog(ModalScreen[dict | None]):
    def __init__(self, preview: MigrationView) -> None: super().__init__(); self.preview = preview
    def compose(self) -> ComposeResult:
        p=self.preview
        with Vertical(classes="dialog"):
            yield Label("REMOVE FRAME", classes="dialog-title")
            yield Input(str(p.position), placeholder="Frame to remove", type="integer", id="frame-position")
            yield Static(f"Contract               {p.old_frames} → {p.new_frames}\nAffected               {', '.join(p.affected)}\nDependency audit       {p.audit}", classes="dialog-body", id="frame-remove-preview")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL", id="cancel"); yield Button("REMOVE FRAME", id="confirm", variant="error", disabled=p.audit != "GREEN")
    def on_button_pressed(self,event:Button.Pressed)->None:
        self.dismiss(None if event.button.id=="cancel" else {"operation":"remove","position":int(self.query_one("#frame-position",Input).value),"fill":"duplicate-prev"})
