from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Checkbox, Label, Static
from ..state import PublishView


class PublishDialog(ModalScreen[bool | None]):
    def __init__(self, preview: PublishView, aseprite_open: bool = False) -> None: super().__init__(); self.preview=preview; self.aseprite_open=aseprite_open
    def compose(self)->ComposeResult:
        p=self.preview; warning="\n[yellow]Aseprite is currently open. Publish uses the last SAVED workbench state.[/yellow]\n" if self.aseprite_open else ""
        retired="\n".join(p.retired_paths) or "none"; new="\n".join(p.new_paths) or "none"
        with Vertical(classes="dialog publish-dialog"):
            yield Label("PUBLISH",classes="dialog-title")
            yield Static(f"{p.selection.identity}\n\nCanonical changes      {p.old_frames}f → {p.new_frames}f\n\nRetired contracts\n{retired}\n\nNew contracts\n{new}\n\nDependency audit       {p.audit}\nCompatibility preflight PASS{warning}",classes="dialog-body",id="publish-preview")
            yield Checkbox("Full changed-file validation",id="full-validation")
            with Horizontal(classes="dialog-buttons"):
                yield Button("CANCEL",id="cancel");yield Button("PUBLISH",id="confirm",variant="success",disabled=p.audit!="GREEN")
    def on_button_pressed(self,event:Button.Pressed)->None:self.dismiss(None if event.button.id=="cancel" else self.query_one("#full-validation",Checkbox).value)
