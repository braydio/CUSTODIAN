from textual.app import ComposeResult
from textual.containers import Horizontal,Vertical
from textual.screen import ModalScreen
from textual.widgets import Button,Label,RadioButton,RadioSet


class ValidationDialog(ModalScreen[bool | None]):
    def compose(self)->ComposeResult:
        with Vertical(classes="dialog"):
            yield Label("VALIDATION",classes="dialog-title")
            with RadioSet(id="validation-mode"):
                yield RadioButton("Standard validation",value=True);yield RadioButton("Full changed-file validation")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL",id="cancel");yield Button("RUN",id="confirm",variant="primary")
    def on_button_pressed(self,event:Button.Pressed)->None:
        self.dismiss(None if event.button.id=="cancel" else self.query_one("#validation-mode",RadioSet).pressed_index==1)
