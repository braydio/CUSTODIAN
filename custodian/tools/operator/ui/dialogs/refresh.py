from textual.app import ComposeResult
from textual.containers import Horizontal,Vertical
from textual.screen import ModalScreen
from textual.widgets import Button,Label,Static


class RefreshDialog(ModalScreen[bool | None]):
    def __init__(self,context_mismatch:bool=False)->None:super().__init__();self.context_mismatch=context_mismatch
    def compose(self)->ComposeResult:
        note="Weapon context differs from this workspace. " if self.context_mismatch else ""
        with Vertical(classes="dialog"):
            yield Label("REFRESH WORKBENCH",classes="dialog-title")
            yield Static(note+"--discard-edits will back up and discard workbench edits and any pending migration.",classes="dialog-body")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL",id="cancel");yield Button("BACK UP + DISCARD",id="confirm",variant="warning")
    def on_button_pressed(self,event:Button.Pressed)->None:self.dismiss(None if event.button.id=="cancel" else True)
